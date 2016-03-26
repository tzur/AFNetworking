// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNGatewayAlbumDescriptor;

/// Asset manager backed by a static list of \c PTNGatewayAlbumDescriptor objects. Each descriptor's
/// Gateway key is stored and any successive fetching of assets, albums and images with a Gateway
/// URL of the same key will return the corresponding descriptor or the signals defined by it.
@interface PTNGatewayAssetManager : NSObject <PTNAssetManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c descriptors as the albums provided by this asset manager. A mapping of each
/// descriptor's Gateway key to itself is stored and used when fetching the asset by URL. Fetching
/// albums and images will return the \c RACSignal stored in the corresponding descriptor.
- (instancetype)initWithDescriptors:(NSSet<PTNGatewayAlbumDescriptor *> *)descriptors;

@end

NS_ASSUME_NONNULL_END
