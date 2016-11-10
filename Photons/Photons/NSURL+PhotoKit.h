// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class PHAsset, PHCollection, PHObjectPlaceholder;

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

/// Category for easy analysis and synthesis of URLs related to PhotoKit objects.
///
/// The following URL types are supported:
///   - Album identifier: <photokit scheme>://album/<identifier>
///   - Asset identifier: <photokit scheme>://asset/<identifier>
///   - Album with type and subtype:
///       <photokit scheme>://albumType/?type=<type>&subtype=<subType>
///   - Album of albums with the given type, a possible ordered subtype filter and a title filter:
///       <photokit scheme>://metaAlbum/?type=<type>&subtype=<subType>[&filter&subalbums=<subtype1>
///       &subalbums=<subtype2>...][&title=<title>]
@interface NSURL (PhotoKit)

/// The URL scheme associated with PhotoKit URLs.
+ (NSString *)ptn_photoKitScheme;

/// The unique identifier URL of the given \c objectPlaceholder.
+ (NSURL *)ptn_photoKitAssetURLWithObjectPlaceholder:(PHObjectPlaceholder *)objectPlaceholder;

/// The unique identifier URL of the given \c asset.
+ (NSURL *)ptn_photoKitAssetURLWithAsset:(PHAsset *)asset;

/// The unique identifier URL of the given \c collection.
+ (NSURL *)ptn_photoKitAlbumURLWithCollection:(PHCollection *)collection;

/// Returns a URL for requesting an album which contains the album with the given \c type and
/// \c subtype. The albums associated with this type of URL are expected to contain assets and no
/// subalbums.
///
/// @important serializing this URL does not guarantee consistent results across iOS versions.
+ (NSURL *)ptn_photoKitAlbumWithType:(PHAssetCollectionType)type
                             subtype:(PHAssetCollectionSubtype)subtype;

/// Returns a URL for requesting an album which contains the album with the given \c type and the
/// \c PHAssetCollectionSubtypeAny subtype. If not empty, only \c subalbums subtypes will be fetched
/// and in the given order. The albums associated with this type of URL are expected to contain
/// subalbums and no assets.
///
/// @important serializing this URL does not guarantee consistent results across iOS versions.
+ (NSURL *)ptn_photoKitMetaAlbumWithType:(PHAssetCollectionType)type
                               subalbums:(const std::vector<PHAssetCollectionSubtype> &)subalbums;

/// Returns a URL for requesting an album which contains the album with the given \c type and the
/// \c PHAssetCollectionSubtypeAny subtype. The albums associated with this type of URL are expected
/// to contain subalbums and no assets.
///
/// @important serializing this URL does not guarantee consistent results across iOS versions.
+ (NSURL *)ptn_photoKitMetaAlbumWithType:(PHAssetCollectionType)type;

/// Returns a URL for requesting an album which contains all the albums corresponding to the the
/// \c PHAssetCollectionTypeAlbum and the \c PHAssetCollectionSubtypeAny subtype with a title that
/// matches \c title. The albums associated with this type of URL are expected to contain subalbums
/// and no assets.
///
/// @important serializing this URL does not guarantee consistent results across iOS versions.
+ (NSURL *)ptn_photoKitUserAlbumsWithTitle:(NSString *)title;

/// Returns the camera roll album. This equivalent to calling \c +ptn_photoKitAlbumWithType:subtype:
/// with \c PHAssetCollectionTypeSmartAlbums and \c PHAssetCollectionSubtypeSmartAlbumUserLibrary.
+ (NSURL *)ptn_photoKitCameraRollAlbum;

/// Returns the smart albums album. This is equivalent to calling
/// \c +ptn_photoKitMetaAlbumWithType: with \c PHAssetCollectionTypeSmartAlbums.
+ (NSURL *)ptn_photoKitSmartAlbums;

/// Returns an album with an ordered subset of the smart albums, equivalent to that of the iOS
/// Photos App. This is equivalent to calling \c +ptn_photoKitMetaAlbumWithType:subalbums: with
/// \c PHAssetCollectionTypeSmartAlbums and a subalbums vector containing the
/// \c PHAssetCollectionSubtypes appearing in the iOS Photos app.
+ (NSURL *)ptn_photoKitPhotosAppSmartAlbums;

/// Returns an album containing all of the User Albums. This is equivalent to calling
/// \c +ptn_photoKitMetaAlbumWithType: with \c PHAssetCollectionTypeAlbums.
+ (NSURL *)ptn_photoKitUserAlbums;

/// Type of the URL, or \c nil if the URL is not of PhotoKit type.
@property (readonly, nonatomic, nullable) PTNPhotoKitURLType *ptn_photoKitURLType;

/// Type of the album, or \c nil if the URL is not of PhotoKit type album type or meta album type.
@property (readonly, nonatomic, nullable) NSNumber *ptn_photoKitAlbumType;

/// Subtype of the album, or \c nil if the URL is not of PhotoKit type album type or meta album
/// type.
@property (readonly, nonatomic, nullable) NSNumber *ptn_photoKitAlbumSubtype;

/// Ordered permitted subtypes of the album, or \c nil if the URL is not of PhotoKit type meta album
/// type, or no subalbums filtering was given.
@property (readonly, nonatomic, nullable) NSArray<NSNumber *> *ptn_photoKitAlbumSubalbums;

/// The album identifier or \c nil if the URL is not a valid PhotoKit album URL.
@property (readonly, nonatomic, nullable) NSString *ptn_photoKitAlbumIdentifier;

/// The asset identifier or \c nil if the URL is not a valid PhotoKit asset URL.
@property (readonly, nonatomic, nullable) NSString *ptn_photoKitAssetIdentifier;

/// Fetch options to use when fetching an album with the receiver, or \c nil if the receiver is not
/// a valid album url or does not require any fetch options.
@property (readonly, nonatomic, nullable) PHFetchOptions *ptn_photoKitAlbumFetchOptions;

@end

NS_ASSUME_NONNULL_END
