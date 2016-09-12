// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class PHAsset, PHCollection;

/// Possible types of PhotoKit URL.
LTEnumDeclare(NSUInteger, PTNPhotoKitURLType,
  /// URL of a specific asset.
  PTNPhotoKitURLTypeAsset,
  /// URL of an album by identifier.
  PTNPhotoKitURLTypeAlbum,
  /// URL of an album by type.
  PTNPhotoKitURLTypeAlbumType,
  /// URL of album of albums by type.
  PTNPhotoKitURLTypeMetaAlbumType
);

/// Possible types of PhotoKit album type.
LTEnumDeclare(NSUInteger, PTNPhotoKitAlbumType,
  /// Album type of user's camera roll.
  PTNPhotoKitAlbumTypeCameraRoll
);

/// Possible types of PhotoKit albums of album types.
LTEnumDeclare(NSUInteger, PTNPhotoKitMetaAlbumType,
  /// Album of album types included in operating system's albums.
  PTNPhotoKitMetaAlbumTypeSmartAlbums,
  /// Album of album types included in operating system's albums as displayed in the Photos app.
  /// This includes hiding empty albums.
  PTNPhotoKitMetaAlbumTypePhotosAppSmartAlbums,
  /// Album of user's albums.
  PTNPhotoKitMetaAlbumTypeUserAlbums
);

/// Category for easy analysis and synthesis of URLs related to PhotoKit objects.
///
/// The following URL types are supported:
///   - Album identifier: <photokit scheme>://album/<identifier>
///   - Asset identifier: <photokit scheme>://asset/<identifier>
///   - Album of albums with the given type and subtype:
///       <photokit scheme>://album/?type=<type>&subtype=<subtype>
@interface NSURL (PhotoKit)

/// The URL scheme associated with PhotoKit URLs.
+ (NSString *)ptn_photoKitScheme;

/// The unique identifier URL of the given \c asset.
+ (NSURL *)ptn_photoKitAssetURLWithAsset:(PHAsset *)asset;

/// The unique identifier URL of the given \c collection.
+ (NSURL *)ptn_photoKitAlbumURLWithCollection:(PHCollection *)collection;

/// Returns a URL for requesting an album which contains the album with the given \c type. The
/// albums associated with this type of URL are expected to contain assets and no subalbums.
+ (NSURL *)ptn_photoKitAlbumWithType:(PTNPhotoKitAlbumType *)type;

/// Returns a URL for requesting an album which contains the albums included in the given \c type.
/// The albums associated with this type of URL are expected to contain subalbums and no assets.
+ (NSURL *)ptn_photoKitMetaAlbumWithType:(PTNPhotoKitMetaAlbumType *)type;

/// Type of the URL, or \c nil if the URL is not of PhotoKit type.
@property (readonly, nonatomic, nullable) PTNPhotoKitURLType *ptn_photoKitURLType;

/// The album identifier or \c nil if the URL is not a valid PhotoKit album URL.
@property (readonly, nonatomic, nullable) NSString *ptn_photoKitAlbumIdentifier;

/// The asset identifier or \c nil if the URL is not a valid PhotoKit album URL.
@property (readonly, nonatomic, nullable) NSString *ptn_photoKitAssetIdentifier;

/// Type of the album to fetch or \c nil if the URL doesn't specify such type.
@property (readonly, nonatomic, nullable) PTNPhotoKitAlbumType *ptn_photoKitAlbumType;

/// Type of the album of albums to fetch or \c nil if the URL doesn't specify such type.
@property (readonly, nonatomic, nullable) PTNPhotoKitMetaAlbumType *ptn_photoKitMetaAlbumType;

@end

NS_ASSUME_NONNULL_END
