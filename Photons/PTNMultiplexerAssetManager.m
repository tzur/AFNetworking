// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMultiplexerAssetManager.h"

#import "NSError+Photons.h"
#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNMultiplexerAssetManager

- (instancetype)initWithSources:(PTNSchemeToManagerMap *)mapping {
  if (self = [super init]) {
    _mapping = mapping;
  }
  return self;
}

#pragma mark -
#pragma mark Album fetching
#pragma mark -

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  id<PTNAssetManager> assetManager = self.mapping[url.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnrecognizedURLScheme url:url]];
  }
  return [assetManager fetchAlbumWithURL:url];
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchAssetWithURL:(NSURL *)url {
  id<PTNAssetManager> assetManager = self.mapping[url.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnrecognizedURLScheme url:url]];
  }
  return [assetManager fetchAssetWithURL:url];
}

#pragma mark -
#pragma mark Image fetching
#pragma mark -

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(PTNImageFetchOptions *)options {
  id<PTNAssetManager> assetManager = self.mapping[descriptor.ptn_identifier.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                  associatedDescriptor:descriptor]];
  }
  return [assetManager fetchImageWithDescriptor:descriptor resizingStrategy:resizingStrategy
                                        options:options];
}

@end

NS_ASSUME_NONNULL_END
