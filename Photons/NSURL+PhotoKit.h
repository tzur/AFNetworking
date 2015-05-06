// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

@import Photos;

@class PTNPhotoKitAlbumType;

NS_ASSUME_NONNULL_BEGIN

/// Possible types of PhotoKit URL.
typedef NS_ENUM(NSUInteger, PTNPhotoKitURLType) {
  /// URL of a specific asset.
  PTNPhotoKitURLTypeAsset,
  /// URL of a specific album.
  PTNPhotoKitURLTypeAlbum,
  /// URL of an album type.
  PTNPhotoKitURLTypeAlbumType,
  /// Invalid URL type.
  PTNPhotoKitURLTypeInvalid,
};

/// Category for easy analysis and synthesis of URLs related to PhotoKit objects.
///
/// The following URL types are supported:
///   - Album identifier: <photokit scheme>://album/<identifier>
///   - Asset identifier: <photokit scheme>://asset/<identifier>
///   - Album of albums with the given type and subtype:
///       <photokit scheme>://album/?type=<type>&subtype=<subtype>
@interface NSURL (PhotoKit)

/// The unique identifier URL of the given \c asset.
+ (NSURL *)ptn_photoKitAssetURLWithAsset:(PHAsset *)asset;

/// The unique identifier URL of the given \c collection.
+ (NSURL *)ptn_photoKitAlbumURLWithCollection:(PHCollection *)collection;

/// Returns a URL for requesting an album which contains the albums with the given \c type.
+ (NSURL *)ptn_photoKitAlbumsWithType:(PTNPhotoKitAlbumType *)type;

/// Type of the URL, or \c PTNPhotoKitURLTypeInvalid if the URL is not of PhotoKit type.
@property (readonly, nonatomic) PTNPhotoKitURLType ptn_photoKitURLType;

/// The album identifier or \c nil if the URL is not a valid PhotoKit album URL.
@property (readonly, nonatomic, nullable) NSString *ptn_photoKitAlbumIdentifier;

/// The asset identifier or \c nil if the URL is not a valid PhotoKit album URL.
@property (readonly, nonatomic, nullable) NSString *ptn_photoKitAssetIdentifier;

/// Type of the album to fetch or \c nil if the URL doesn't specify such type.
@property (readonly, nonatomic, nullable) PTNPhotoKitAlbumType *ptn_photoKitAlbumType;

@end

NS_ASSUME_NONNULL_END
