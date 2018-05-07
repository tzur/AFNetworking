// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAssetManager.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "NSError+Photons.h"
#import "NSURL+Gateway.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNGatewayAlbumDescriptor.h"
#import "PTNIncrementalChanges.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNGatewayAssetManager ()

/// Mapping of \c PTNGatewayAlbumDescriptor objects' \c ptn_identifier's Gateway key and their
/// corresponding descriptor.
@property (readonly, nonatomic) NSDictionary<NSString *, PTNGatewayAlbumDescriptor *> *assetMap;

@end

@implementation PTNGatewayAssetManager

- (instancetype)initWithDescriptors:(NSSet<PTNGatewayAlbumDescriptor *> *)descriptors {
  if (self = [super init]) {
    _assetMap = [self keyToAssetMapping:descriptors];
  }
  return self;
}

- (NSDictionary *)keyToAssetMapping:(NSSet<PTNGatewayAlbumDescriptor *> *)descriptors {
  NSMutableDictionary *map = [NSMutableDictionary dictionary];
  for (PTNGatewayAlbumDescriptor *descriptor in descriptors) {
    NSString * _Nullable key = [descriptor.ptn_identifier ptn_gatewayKey];
    LTParameterAssert(key, @"Given descriptor %@ doesn't have a Gateway key", descriptor);
    map[key] = descriptor;
  }
  return [map copy];
}

#pragma mark -
#pragma mark PTNAssetManager
#pragma mark -

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  PTNGatewayAlbumDescriptor * _Nullable descriptor = [self descriptorForURL:url];
  if (!descriptor) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  if (url.ptn_isFlattened) {
    return descriptor.albumSignal;
  }

  PTNGatewayAlbumDescriptor *flattenedDescriptor = [[PTNGatewayAlbumDescriptor alloc]
      initWithIdentifier:[NSURL ptn_flattenedGatewayAlbumURLWithKey:url.ptn_gatewayKey]
      localizedTitle:descriptor.localizedTitle imageSignalBlock:descriptor.imageSignalBlock
      albumSignal:descriptor.albumSignal];

  id<PTNAlbum> album = [[PTNAlbum alloc] initWithURL:descriptor.ptn_identifier
                                           subalbums:@[flattenedDescriptor] assets:@[]];
  PTNAlbumChangeset *initialChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
  PTNIncrementalChanges *incrementalChanges =
      [PTNIncrementalChanges changesWithRemovedIndexes:nil insertedIndexes:nil
                                        updatedIndexes:[NSIndexSet indexSetWithIndex:0] moves:nil];
  PTNAlbumChangeset *updates = [PTNAlbumChangeset changesetWithBeforeAlbum:album afterAlbum:album
                                                           subalbumChanges:incrementalChanges
                                                              assetChanges:nil];

  return [[RACSignal
      return:initialChangeset]
      concat:[descriptor.albumSignal mapReplace:updates]];
}

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  PTNGatewayAlbumDescriptor * _Nullable descriptor = [self descriptorForURL:url];
  if (!descriptor) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [RACSignal return:descriptor];
}

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(PTNImageFetchOptions *)options {
  // Although unregistered \c PTNGatewayAlbumDescriptors can technically be served, they will only
  // work for fetching images, resulting in confusing behavior and are therefore rejected.
  PTNGatewayAlbumDescriptor * _Nullable gatewayDescriptor =
      [self descriptorForURL:descriptor.ptn_identifier];
  if (!gatewayDescriptor) {
    NSError *error = [NSError ptn_errorWithCode:PTNErrorCodeInvalidURL
                           associatedDescriptor:descriptor];
    return [RACSignal error:error];
  }

  return gatewayDescriptor.imageSignalBlock(resizingStrategy, options);
}

- (RACSignal *)fetchAVAssetWithDescriptor:(id<PTNDescriptor>)descriptor
                                  options:(PTNAVAssetFetchOptions __unused *)options {
  return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnsupportedOperation
                                associatedDescriptor:descriptor]];
}

- (RACSignal *)fetchImageDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnsupportedOperation
                                associatedDescriptor:descriptor]];
}

- (RACSignal *)fetchAVPreviewWithDescriptor:(id<PTNDescriptor>)descriptor
                                    options:(PTNAVAssetFetchOptions __unused *)options {
  return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnsupportedOperation
                                associatedDescriptor:descriptor]];
}

- (RACSignal<PTNProgress<id<PTNAVDataAsset>> *>*)
    fetchAVDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnsupportedOperation
                                associatedDescriptor:descriptor]];
}

#pragma mark -
#pragma mark Descriptor mapping
#pragma mark -

- (nullable PTNGatewayAlbumDescriptor *)descriptorForURL:(NSURL *)url {
  if (![url.scheme isEqualToString:[NSURL ptn_gatewayScheme]]) {
    return nil;
  }

  NSString * _Nullable key = [url ptn_gatewayKey];
  if (!key) {
    return nil;
  }

  return self.assetMap[key];
}

@end

NS_ASSUME_NONNULL_END
