// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbum.h"

NS_ASSUME_NONNULL_BEGIN

@class PHFetchResult;

@interface PTNPhotoKitAlbum : NSObject <PTNAlbum>

/// Initializes a PhotoKit album with a fetch result that contains \c PHAsset objects. The newly
/// created album will contain assets only, and an empty \c subalbums collection.
- (instancetype)initWithAssets:(PHFetchResult *)assets NS_DESIGNATED_INITIALIZER;

/// Initializes a PhotoKit album with a fetch result that contains \c PHCollection objects. The
/// newly created album will contain subalbums only, and an empty \c asset collection.
- (instancetype)initWithAlbums:(PHFetchResult *)albums NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
