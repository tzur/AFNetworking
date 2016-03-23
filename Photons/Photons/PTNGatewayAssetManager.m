// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAssetManager.h"

#import "NSError+Photons.h"
#import "NSURL+Gateway.h"
#import "PTNGatewayAlbumDescriptor.h"

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

  return descriptor.albumSignal;
}

- (RACSignal *)fetchAssetWithURL:(NSURL *)url {
  PTNGatewayAlbumDescriptor * _Nullable descriptor = [self descriptorForURL:url];
  if (!descriptor) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeInvalidURL url:url]];
  }

  return [RACSignal return:descriptor];
}

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy> __unused)resizingStrategy
                                options:(PTNImageFetchOptions __unused *)options {
  // Although unregistered \c PTNGatewayAlbumDescriptors can technically be served, they will only
  // work for fetching images, resulting in confusing behavior and are therefore rejected.
  PTNGatewayAlbumDescriptor * _Nullable gatewayDescriptor =
      [self descriptorForURL:descriptor.ptn_identifier];
  if (!gatewayDescriptor) {
    NSError *error = [NSError ptn_errorWithCode:PTNErrorCodeInvalidURL
                           associatedDescriptor:descriptor];
    return [RACSignal error:error];
  }

  return gatewayDescriptor.imageSignal;
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
