// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

@class MPMediaItem, MPMediaItemCollection;

/// Supported types of Media Library URL.
typedef NS_ENUM(NSUInteger, PTNMediaLibraryURLType) {
  /// URL of a specific asset.
  PTNMediaLibraryURLTypeAsset,
  /// URL of a specific album.
  PTNMediaLibraryURLTypeAlbum,
  /// URL of a media library query.
  PTNMediaLibraryURLTypeQuery,
  /// Invalid URL type.
  PTNMediaLibraryURLTypeInvalid
};

/// Supported types of media library queries.
LTEnumDeclare(NSUInteger, PTNMediaLibraryQueryType,
  /// Returns all the music artists in the library sorted by artist name.
  PTNMediaLibraryQueryTypeArtists,
  /// Returns all the music albums in the library sorted by album name.
  PTNMediaLibraryQueryTypeAlbums,
  /// Returns all the songs in the library sorted by song name.
  PTNMediaLibraryQueryTypeSongs
);

/// Category for easy analysis and synthesis of URLs related to Media Library objects.
///
/// The following URL types are supported:
///   - Album path: <medialibrary scheme>://album/<identifier>
///   - Asset path: <medialibrary scheme>://asset/<identifier>
///   - Query path: <medialibrary scheme>://query?type=<PTNMediaLibraryQueryType>
@interface NSURL (MediaLibrary)

/// URL Scheme associated with Media Library URLs.
+ (NSString *)ptn_mediaLibraryScheme;

/// Unique identifier URL of the given \c item.
+ (NSURL *)ptn_mediaLibraryAssetURLWithItem:(MPMediaItem *)item;

/// Unique identifier URL of the given \c collection.
+ (NSURL *)ptn_mediaLibraryAlbumURLWithCollection:(MPMediaItemCollection *)collection;

/// Unique identifier URL of a query with the given \c type.
+ (NSURL *)ptn_mediaLibraryQueryURLWithType:(PTNMediaLibraryQueryType *)type;

/// Query URL of album type, equivalent to calling
/// \c ptn_mediaLibraryQueryURLWithType:$(PTNMediaLibraryQueryTypeAlbums).
+ (NSURL *)ptn_mediaLibraryAlbumsQueryURL;

/// Query URL of artists type, equivalent to calling
/// \c ptn_mediaLibraryQueryURLWithType:$(PTNMediaLibraryQueryTypeArtists).
+ (NSURL *)ptn_mediaLibraryArtistsQueryURL;

/// Query URL of songs type, equivalent to calling
/// \c ptn_mediaLibraryQueryURLWithType:$(PTNMediaLibraryQueryTypeSongs).
+ (NSURL *)ptn_mediaLibrarySongsQueryURL;

/// Type of the URL, or \c PTNMediaLibraryURLTypeInvalid if the URL is not of Media Library type.
@property (readonly, nonatomic) PTNMediaLibraryURLType ptn_mediaLibraryURLType;

/// Query type of the URL, or \c nil if the URL contains no query.
@property (readonly, nonatomic, nullable) PTNMediaLibraryQueryType *ptn_mediaLibraryQueryType;

/// Persistent ID of the album or asset, or \c nil if the URL is invalid or does not represent
/// an asset or album. Persistent ID's value is of \c MPMediaEntityPersistentID type.
@property (readonly, nonatomic, nullable) NSNumber *ptn_mediaLibraryPersistentID;

@end

NS_ASSUME_NONNULL_END
