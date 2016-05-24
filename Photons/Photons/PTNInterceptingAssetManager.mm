// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNInterceptingAssetManager.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTMappingRandomAccessCollection.h>

#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNAlbumInterceptionController.h"
#import "PTNDescriptor.h"
#import "PTNIncrementalChanges.h"
#import "PTNMulticastingSignalCache.h"
#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNInterceptingAssetManager ()

/// Signal carrying \c PTNDescriptorBidirectionalMap objects that represent the latest mapping
/// between \c NSURL identifiers to intercept and the \c PTNDescriptor objects to inject in their
/// place.
@property (readonly, nonatomic) RACSignal *interceptedDescriptors;

/// Underlying asset manager used to relay all asset requests.
@property (readonly, nonatomic) id<PTNAssetManager> assetManager;

/// Signal cache used to store original descriptors of intercepted identifiers in order to avoid
/// fetching them multiple times.
@property (readonly, nonatomic) id<PTNSignalCache> originalSignalCache;

@end

@implementation PTNInterceptingAssetManager

- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager
              interceptedDescriptors:(RACSignal *)interceptedDescriptors {
  if (self = [super init]) {
    _assetManager = assetManager;
    _interceptedDescriptors = [[[[[[interceptedDescriptors
        takeUntil:self.rac_willDeallocSignal]
        startWith:@{}]
        map:^LTBidirectionalMap *(NSDictionary *dictionary) {
          return [[LTBidirectionalMap alloc] initWithDictionary:dictionary];
        }]
        distinctUntilChanged]
        catchTo:[RACSignal empty]]
        replayLast];
    _originalSignalCache = [[PTNMulticastingSignalCache alloc] initWithReplayCapacity:1];

    [self autoClearSignalCache];
  }
  return self;
}

- (void)autoClearSignalCache {
  @weakify(self)
  [[[self.interceptedDescriptors
      map:^NSArray<NSURL *> *(PTNDescriptorBidirectionalMap *interceptionMap) {
        return interceptionMap.allKeys;
      }]
      combinePreviousWithStart:@[] reduce:^id<NSFastEnumeration>(NSArray<NSURL *> *previous,
                                                                 NSArray<NSURL *> *current) {
        return [previous.rac_sequence filter:^BOOL(NSURL *identifier) {
          return ![current containsObject:identifier];
        }];
      }]
      subscribeNext:^(NSArray<NSURL *> *untrackedIdentifiers) {
        @strongify(self)
        for (NSURL *identifier in untrackedIdentifiers) {
          [self.originalSignalCache removeSignalForURL:identifier];
        }
      }];
}

#pragma mark -
#pragma mark Album fetching
#pragma mark -

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  return [[[RACSignal
      ptn_combineLatestWithIndex:@[
        [self.assetManager fetchAlbumWithURL:url],
        [self previousAndCurrentMaps]
      ]]
      reduceEach:(id)^PTNAlbumChangeset *(RACTuple *combinedData, NSNumber *changedIndex) {
        RACTupleUnpack(PTNAlbumChangeset *changeset, RACTuple *mapsWithPrevious) = combinedData;
        RACTupleUnpack(RACTuple *previousMaps, RACTuple *maps) = mapsWithPrevious;

        PTNAlbumInterceptionChangeInvoker changeInvoker;
        if (!changedIndex) {
          changeInvoker = PTNAlbumInterceptionChangeInvokerNone;
        } else {
          changeInvoker = changedIndex.unsignedIntegerValue == 0 ?
              PTNAlbumInterceptionChangeInvokerUnderlyingAlbum :
              PTNAlbumInterceptionChangeInvokerMapping;
        }

        PTNAlbumInterceptionChangeParameters parameters = {
          .interceptionMap = maps.first,
          .originalMap = maps.second,
          .previousInterceptionMap = previousMaps.first,
          .previousOriginalMap = previousMaps.second,
          .changeset = changeset,
          .changeInvoker = changeInvoker
        };

        return [PTNAlbumInterceptionController changesetWithParameters:parameters];
      }]
      ignore:nil];
}

- (RACSignal *)previousAndCurrentMaps {
  LTBidirectionalMap *emptyMap = [[LTBidirectionalMap alloc] initWithDictionary:@{}];
  RACTuple *emptyMaps = RACTuplePack(emptyMap, emptyMap);
  @weakify(self)
  return [[[self.interceptedDescriptors
      map:^RACStream *(PTNDescriptorBidirectionalMap *interceptionMap) {
        @strongify(self)
        return [RACSignal combineLatest:@[
          [RACSignal return:interceptionMap],
          [self originalDescriptorsFromInterceptionMap:interceptionMap]
        ]];
      }]
      switchToLatest]
      combinePreviousWithStart:emptyMaps
      reduce:^RACTuple *(PTNDescriptorBidirectionalMap *previous,
                         PTNDescriptorBidirectionalMap *current) {
        return RACTuplePack(previous, current);
      }];
}

- (RACSignal *)originalDescriptorsFromInterceptionMap:
    (PTNDescriptorBidirectionalMap *)interceptionMap {
  // Returns the descriptors that are originally associated with the URL keys of \c interceptionMap.
  if (!interceptionMap.allKeys.count) {
    return [RACSignal return:[[LTBidirectionalMap alloc] init]];
  }

  NSArray *signals = [interceptionMap.allKeys.rac_sequence map:^RACSignal *(NSURL *url) {
    return [self fetchCachedDescriptorWithURL:url];
  }].array;

  return [[[RACSignal combineLatest:signals]
      map:^id(RACTuple *descriptors) {
        NSDictionary *dictionary = [[NSDictionary alloc] initWithObjects:descriptors.allObjects
                                                                 forKeys:interceptionMap.allKeys];
        return [[LTBidirectionalMap alloc] initWithDictionary:dictionary];
      }]
      takeUntil:self.rac_willDeallocSignal];
}

- (RACSignal *)fetchCachedDescriptorWithURL:(NSURL *)url {
  RACSignal *existingSignal = self.originalSignalCache[url];
  if (existingSignal) {
    return existingSignal;
  }

  RACSignal *signal = [self.assetManager fetchDescriptorWithURL:url];
  self.originalSignalCache[url] = signal;

  return signal;
}

#pragma mark -
#pragma mark Descriptor fetching
#pragma mark -

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  @weakify(self)
  return [[[[self.interceptedDescriptors
      map:^id<PTNDescriptor>(PTNDescriptorMap *map) {
        return map[url];
      }]
      distinctUntilChanged]
      map:^RACStream *(id<PTNDescriptor> _Nullable interceptingDescriptor) {
        @strongify(self)
        if (interceptingDescriptor) {
          return [RACSignal return:interceptingDescriptor];
        }

        return [self.assetManager fetchDescriptorWithURL:url];
      }]
      switchToLatest];
}

#pragma mark -
#pragma mark Image fetching
#pragma mark -

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(PTNImageFetchOptions *)options {
  return [self.assetManager fetchImageWithDescriptor:descriptor resizingStrategy:resizingStrategy
                                             options:options];
}

#pragma mark -
#pragma mark Proxying optional methods
#pragma mark -

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
  return [super conformsToProtocol:aProtocol] ||
      [self.assetManager conformsToProtocol:aProtocol];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
  return [super respondsToSelector:aSelector] ||
      [self.assetManager respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
  return [self.assetManager respondsToSelector:selector] ?
      self.assetManager : [super forwardingTargetForSelector:selector];
}

@end

NS_ASSUME_NONNULL_END
