// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNImageAsset.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNDataAsset;

@class PTNCacheInfo;

/// Protocol extending \c PTNImageAsset by providing cache information that is not included in the
/// original protocol. This allows entities that are not aware of the caching system use this album
/// in a regular fashion, while enabling entities that need the caching information access it for
/// their purposes.
///
/// @note The wrapped asset must confrom to both the \c PTNImageAsset and \c PTNDataAsset.
/// This is because the receiver conforms to \c PTNImageAsset itself by forwarding method calls to
/// the underlying asset, and since the \c underlyingAsset property is intended to be used by the
/// caching system that only support \c PTNDataAsset conforming objects.
@protocol PTNCacheImageAsset <PTNImageAsset>

/// Underlying image asset wrapped by the receiver.
@property (readonly, nonatomic) id<PTNImageAsset, PTNDataAsset> underlyingAsset;

/// Cache information associated with the receiver's \c underlyingAsset.
@property (readonly, nonatomic) PTNCacheInfo *cacheInfo;

@end

/// Implementation of \c PTNCacheImageAsset wrapping a \c PTNImageAsset and \c PTNDataAsset
/// conforming object and a \c PTNCacheInfo.
@interface PTNCacheImageAsset : NSObject <PTNCacheImageAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Creates and returns a \c PTNCacheImageAsset with \c underlyingAsset and \c cacheInfo.
+ (instancetype)imageAssetWithUnderlyingAsset:(id<PTNImageAsset, PTNDataAsset>)underlyingAsset
                                    cacheInfo:(PTNCacheInfo *)cacheInfo;

@end

NS_ASSUME_NONNULL_END
