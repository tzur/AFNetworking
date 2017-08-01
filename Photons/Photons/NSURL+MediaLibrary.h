// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

@class MPMediaItem, PTNMediaQuery;

@protocol PTNMediaQuery, PTNMediaQueryProvider;

/// Supported types of Media Library URL.
typedef NS_ENUM(NSUInteger, PTNMediaLibraryURLType) {
  /// URL of a specific asset.
  PTNMediaLibraryURLTypeAsset,
  /// URL of a specific album.
  PTNMediaLibraryURLTypeAlbum,
  /// Invalid URL type.
  PTNMediaLibraryURLTypeInvalid
};

/// Fetching option of Media Library entities.
LTEnumDeclare(NSUInteger, PTNMediaLibraryFetchType,
  /// fetch entities as list of items.
  PTNMediaLibraryFetchTypeItems,
  /// fetch entities as list of collections.
  PTNMediaLibraryFetchTypeCollections
);

/// Category for easy analysis and synthesis of URLs related to Media Library objects.
///
/// The following URL types are supported:
///   - Asset path: <medialibrary scheme>://asset?<predicate>=<value>[...]&
///                 fetch=PTNMediaLibraryFetchTypeItems
///   - Album path: <medialibrary scheme>://album?<predicate>=<value>[...]&
///                 fetch=[PTNMediaLibraryFetchTypeItems|PTNMediaLibraryFetchTypeCollections]&
///                 [grouping=<MPMediaGrouping>]
///
/// \c predicate is \s NSString which may have any of \c MPMediaItemProperty* values. \c value is
/// the string representation of the corresponding predicate value of \c id type. \c predicate and
/// \c value can repeat any number of times. \c fetch defines how the entity is being fetched i.e.
/// as list of items (assets) or as list of collections (albums). \c grouping may apply only when
/// \c fetch=PTNMediaLibraryFetchTypeCollections and defines how the collections are constructed
/// from the URL.
@interface NSURL (MediaLibrary)

/// Returns \c NSArray of all values, in order of appearance, for the given \c predicate.
- (NSArray<NSString *> *)ptn_valuesForPredicate:(NSString *)predicate;

/// URL Scheme associated with Media Library URLs.
+ (NSString *)ptn_mediaLibraryScheme;

/// Unique identifier URL of a song asset, pointed by the given \c item. The song is fetch as an
/// item.
+ (NSURL *)ptn_mediaLibraryAssetWithItem:(MPMediaItem *)item;

/// Unique identifier URL of album holding a list of songs. Each song belongs to the same music
/// album, pointed by the given \c item. The album is fetched as a list of items. Albums are sorted
/// by music album alphabetically.
+ (NSURL *)ptn_mediaLibraryAlbumMusicAlbumSongsWithItem:(MPMediaItem *)item;

/// Unique identifier URL of an album, which holds all music albums of an artist, pointed by the
/// given \c item. Music albums are fetched as list of collections, when each is holding songs.
/// Albums sorted by music album title alphabetically.
+ (NSURL *)ptn_mediaLibraryAlbumArtistMusicAlbumsWithItem:(MPMediaItem *)item;

/// Unique identifier URL of an album, which holds all songs of an artist, pointed by the given
/// \c item. Songs are fetched as a list of items, sorted by title alphabetically.
+ (NSURL *)ptn_mediaLibraryAlbumArtistSongsWithItem:(MPMediaItem *)item;

/// Unique identifier URL of album, which holds all music albums available in Media Library.
/// music albums are fetched as list of collections, when each is holding songs. Albums sorted by
/// music albums alphabetically.
+ (NSURL *)ptn_mediaLibraryAlbumSongsByMusicAlbum;

/// Unique identifier URL of album, which holds all artists available in Media Library. Artist
/// are fetched as collections, when each is holding songs. Albums sorted by artists alphabetically.
+ (NSURL *)ptn_mediaLibraryAlbumSongsByAritst;

/// Unique identifier URL of album, which holds all songs available in Media Library. Songs are
/// fetched as items. Songs are ordered alphabetically by title.
+ (NSURL *)ptn_mediaLibraryAlbumSongs;

/// Type of the URL, or \c PTNMediaLibraryURLTypeInvalid if the URL is not of Media Library type.
@property (readonly, nonatomic) PTNMediaLibraryURLType ptn_mediaLibraryURLType;

/// Media Library entity fetching option.
@property (readonly, nonatomic) PTNMediaLibraryFetchType *ptn_mediaLibraryFetch;

/// \c MPMediaGrouping or \c nil if the URL is invalid or does not represent a URL with a specific
/// media grouping.
@property (readonly, nonatomic, nullable) NSNumber *ptn_mediaLibraryGrouping;

@end

/// Category augmenting \c NSURL with functionality which enables to obtain \c PTNMediaQuery from
/// \c NSURL.
@interface NSURL (PTNMediaQuery)

/// Returns \c PTNMediaQuery which is represented by this instance, or \c nil if this instance does
/// not represent a valid \c PTNMediaQuery. Uses the given \c provider when createing
/// \c PTNMediaQuery.
- (nullable id<PTNMediaQuery>)ptn_mediaLibraryQueryWithProvider:(id<PTNMediaQueryProvider>)provider;

@end

NS_ASSUME_NONNULL_END
