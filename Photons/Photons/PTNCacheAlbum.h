// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAlbum.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNCacheInfo;

/// Protocol extending \c PTNAlbum by providing cache information that is not included in the
/// original protocol. This allows entities that are not aware of the caching system use this album
/// in a regular fashion, while enabling entities that need the caching information access it for
/// their purposes.
@protocol PTNCacheAlbum <PTNAlbum>

/// Underlying \c PTNAlbum wrapped by the receiver.
@property (readonly, nonatomic) id<PTNAlbum> underlyingAlbum;

/// Cache information associated with the receiver's \c underlyingAlbum.
@property (readonly, nonatomic) PTNCacheInfo *cacheInfo;

@end

/// Implementation of \c PTNCacheAlbum acting as a wrapper to an album with associated cache
/// information.
@interface PTNCacheAlbum : NSObject <PTNCacheAlbum>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes and returns a \c PTNCacheAlbum wrapping \c underlyingAlbum and \c cacheInfo. All
/// methods from the \c PTNCacheAlbum protocol in the returned album will be proxied to
/// \c underlyingAlbum.
+ (instancetype)cacheAlbumWithUnderlyingAlbum:(id<PTNAlbum>)underlyingAlbum
                                    cacheInfo:(PTNCacheInfo *)cacheInfo;

@end

NS_ASSUME_NONNULL_END
