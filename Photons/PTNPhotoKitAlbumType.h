// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

/// Groups type and subtype of PhotoKit asset collection.
@interface PTNPhotoKitAlbumType : NSObject <NSCopying>

/// Initiailizes new album type with PhotoKit \c type and \c subtype.
+ (instancetype)albumTypeWithType:(PHAssetCollectionType)type
                          subtype:(PHAssetCollectionSubtype)subtype;

/// Type of the album.
@property (readonly, nonatomic) PHAssetCollectionType type;

/// Subtype of the album.
@property (readonly, nonatomic) PHAssetCollectionSubtype subtype;

@end

NS_ASSUME_NONNULL_END
