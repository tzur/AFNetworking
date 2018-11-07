// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNInterceptingAssetManager.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTMappingRandomAccessCollection.h>

#import "NSErrorCodes+Photons.h"
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

/// \c RACTuple of \c RACTuples representing
/// @code
/// ((<previousInterceptionMap>, <previousOriginalMap>), (<interceptionMap>, <originalMap>))
/// @endcode
/// Where the first tuple contains the previous versions of the interception map and its
/// corresponding original map and the second their current versions. Each map is a
/// \c PTNDescriptorBidirectionalMap, the interception mapping maps \c NSURL identifiers to the
/// \c PTNDescriptor objects to inject in their place and the original mapping maps \c NSURL
/// identifiers to the \c PTNDescriptor they represent normally prior to the interception.
@property (readonly, nonatomic) RACTuple *previousAndCurrentMaps;

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
    _interceptedDescriptors = [[[[[[[interceptedDescriptors
        takeUntil:self.rac_willDeallocSignal]
        startWith:@{}]
        map:^LTBidirectionalMap *(NSDictionary *dictionary) {
          return [[LTBidirectionalMap alloc] initWithDictionary:dictionary];
        }]
        distinctUntilChanged]
        catchTo:[RACSignal empty]]
        replayLast]
        deliverOnMainThread];
    RAC(self, previousAndCurrentMaps) = [self fetchPreviousAndCurrentMaps];
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
  // The order in which \c self.previousAndCurrentMaps comes before the album fetch is crucial to
  // ensure no values of the album fetch are missed (even on cold signals sending mutliple values
  // on subscription).
  return [[[RACSignal
      ptn_combineLatestWithIndex:@[
        RACObserve(self, previousAndCurrentMaps),
        [[self.assetManager fetchAlbumWithURL:url] deliverOnMainThread]
      ]]
      reduceEach:(id)^PTNAlbumChangeset *(RACTuple *combinedData, NSNumber *changedIndex) {
        RACTupleUnpack(RACTuple *mapsWithPrevious, PTNAlbumChangeset *changeset) = combinedData;
        RACTupleUnpack(RACTuple *previousMaps, RACTuple *maps) = mapsWithPrevious;

        PTNAlbumInterceptionChangeInvoker changeInvoker;
        if (!changedIndex) {
          changeInvoker = PTNAlbumInterceptionChangeInvokerNone;
        } else {
          changeInvoker = changedIndex.unsignedIntegerValue == 1 ?
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

- (RACSignal *)fetchPreviousAndCurrentMaps {
  LTBidirectionalMap *emptyMap = [[LTBidirectionalMap alloc] initWithDictionary:@{}];
  RACTuple *emptyMaps = RACTuplePack(emptyMap, emptyMap);
  @weakify(self)
  return [[[[self.interceptedDescriptors
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
      }]
      startWith:RACTuplePack(emptyMaps, emptyMaps)];
}

- (RACSignal *)originalDescriptorsFromInterceptionMap:
    (PTNDescriptorBidirectionalMap *)interceptionMap {
  // Returns the descriptors that are originally associated with the URL keys of \c interceptionMap.
  // Descriptors that can't be found are assumed to be removed and ignored.
  if (!interceptionMap.allKeys.count) {
    return [RACSignal return:[[LTBidirectionalMap alloc] init]];
  }

  RACSequence *signals = [interceptionMap.allKeys.rac_sequence map:^RACSignal *(NSURL *url) {
    return [[self fetchCachedDescriptorWithURL:url] catchTo:[RACSignal return:nil]];
  }];

  return [[[[RACSignal combineLatest:signals]
      map:^id(RACTuple *descriptors) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        for (NSUInteger i = 0; i < descriptors.count; ++i) {
          id<PTNDescriptor> _Nullable descriptor = descriptors[i];
          if (descriptor) {
            dictionary[interceptionMap.allKeys[i]] = descriptor;
          }
        }

        return [[LTBidirectionalMap alloc] initWithDictionary:dictionary];
      }]
      takeUntil:self.rac_willDeallocSignal]
      deliverOnMainThread];
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

        return [[self.assetManager fetchDescriptorWithURL:url] deliverOnMainThread];
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
#pragma mark AVAsset fetching
#pragma mark -

- (RACSignal *)fetchAVAssetWithDescriptor:(id<PTNDescriptor>)descriptor
                                  options:(PTNAVAssetFetchOptions *)options {
  return [self.assetManager fetchAVAssetWithDescriptor:descriptor options:options];
}

#pragma mark -
#pragma mark Image data fetching
#pragma mark -

- (RACSignal *)fetchImageDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  return [self.assetManager fetchImageDataWithDescriptor:descriptor];
}

#pragma mark -
#pragma mark AV preview fetching
#pragma mark -

- (RACSignal *)fetchAVPreviewWithDescriptor:(id<PTNDescriptor>)descriptor
                                    options:(PTNAVAssetFetchOptions __unused *)options {
  return [self.assetManager fetchAVPreviewWithDescriptor:descriptor options:options];
}

#pragma mark -
#pragma mark AV data fetching
#pragma mark -

- (RACSignal<LTProgress<id<PTNAVDataAsset>> *>*)
    fetchAVDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  return [self.assetManager fetchAVDataWithDescriptor:descriptor];
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
