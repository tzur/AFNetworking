// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSURL+MediaLibrary.h"

#import <LTKit/NSURL+Query.h>
#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

/// Fetching option of Media Library entities.
LTEnumImplement(NSUInteger, PTNMediaLibraryFetchType,
  /// fetch entities as list of items.
  PTNMediaLibraryFetchTypeItems,
  /// fetch entities as list of collections.
  PTNMediaLibraryFetchTypeCollections
);

@implementation NSURL (MediaLibrary)

+ (NSString *)ptn_mediaLibraryScheme {
  return @"com.lightricks.Photons.MediaLibrary";
}

+ (NSURL *)ptn_mediaLibraryAssetWithItem:(MPMediaItem *)item {
  auto predicate = [MPMediaPropertyPredicate predicateWithValue:@(item.persistentID)
                    forProperty:MPMediaItemPropertyPersistentID];
  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAsset
                    predicates:[NSSet setWithObject:predicate]
                     fetchType:$(PTNMediaLibraryFetchTypeItems) groupedBy:nil];
}

+ (NSURL *)ptn_mediaLibraryAlbumMusicAlbumSongsWithItem:(MPMediaItem *)item {
  auto predicate = [MPMediaPropertyPredicate predicateWithValue:@(item.albumPersistentID)
                    forProperty:MPMediaItemPropertyAlbumPersistentID];
  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[NSSet setWithObject:predicate]
                     fetchType:$(PTNMediaLibraryFetchTypeItems) groupedBy:nil];
}

+ (NSURL *)ptn_mediaLibraryAlbumArtistMusicAlbumsWithItem:(MPMediaItem *)item {
  auto predicate = [MPMediaPropertyPredicate predicateWithValue:@(item.albumPersistentID)
                    forProperty:MPMediaItemPropertyAlbumPersistentID];
  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[NSSet setWithObject:predicate]
                     fetchType:$(PTNMediaLibraryFetchTypeCollections)
                     groupedBy:@(MPMediaGroupingAlbum)];
}

+ (NSURL *)ptn_mediaLibraryAlbumArtistSongsWithItem:(MPMediaItem *)item {
  auto predicate = [MPMediaPropertyPredicate predicateWithValue:@(item.albumPersistentID)
                    forProperty:MPMediaItemPropertyAlbumPersistentID];
  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[NSSet setWithObject:predicate]
                     fetchType:$(PTNMediaLibraryFetchTypeItems) groupedBy:nil];
}

+ (NSURL *)ptn_mediaLibraryAlbumSongsByMusicAlbum {
  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[NSSet setWithObject:[self mediaTypeMusicPredicate]]
                     fetchType:$(PTNMediaLibraryFetchTypeCollections)
                     groupedBy:@(MPMediaGroupingAlbum)];
}

+ (NSURL *)ptn_mediaLibraryAlbumSongsByAritst {
  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[NSSet setWithObject:[self mediaTypeMusicPredicate]]
                     fetchType:$(PTNMediaLibraryFetchTypeCollections)
                     groupedBy:@(MPMediaGroupingArtist)];
}

+ (NSURL *)ptn_mediaLibraryAlbumSongs {
  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[NSSet setWithObject:[self mediaTypeMusicPredicate]]
                     fetchType:$(PTNMediaLibraryFetchTypeCollections)
                     groupedBy:@(MPMediaGroupingTitle)];
}

+ (NSURL *)ptn_urlWithType:(PTNMediaLibraryURLType)type
                predicates:(NSSet<MPMediaPropertyPredicate *> *)predicates
                 fetchType:(PTNMediaLibraryFetchType *)fetchType
                 groupedBy:(nullable NSNumber *)grouping {
  LTParameterAssert(type == PTNMediaLibraryURLTypeAlbum || type == PTNMediaLibraryURLTypeAsset,
                    @"url type (%lu) is not upported", (unsigned long)type);

  auto queryItems = [NSMutableArray arrayWithArray:[self ptn_queryItemsFromPredicates:predicates]];
  [queryItems addObject:[NSURLQueryItem queryItemWithName:@"fetch" value:fetchType.name]];

  if (grouping) {
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"grouping"
                           value:[self ptn_groupingToString:grouping]]];
  }

  auto components = [[NSURLComponents alloc] init];
  components.scheme = [NSURL ptn_mediaLibraryScheme];
  components.host = (type == PTNMediaLibraryURLTypeAlbum) ? @"album" : @"asset";
  components.queryItems = [queryItems copy];

  return components.URL;
}

+ (NSArray<NSURLQueryItem *> *)ptn_queryItemsFromPredicates:
    (NSSet<MPMediaPropertyPredicate *> *)predicates {
  auto items = [NSMutableArray<NSURLQueryItem *> array];
  for (MPMediaPropertyPredicate *predicate in predicates) {
    [items addObject:[NSURLQueryItem queryItemWithName:predicate.property
                      value:[NSString stringWithFormat:@"%@", predicate.value]]];
  }
  return [items copy];
}

+ (NSString *)ptn_groupingToString:(NSNumber *)groupingType {
  return [self ptn_groupingValueToNSStringMap][groupingType];
}

+ (MPMediaPropertyPredicate *)mediaTypeMusicPredicate {
    return [MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeMusic)
                                            forProperty:MPMediaItemPropertyMediaType];
}

+ (NSDictionary<NSNumber *, NSString *> *)ptn_groupingValueToNSStringMap {
  static NSDictionary<NSNumber *, NSString *> *groupingValueToNSStringMap;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    groupingValueToNSStringMap = @{
      @(MPMediaGroupingAlbum): @"MPMediaGroupingAlbum",
      @(MPMediaGroupingAlbumArtist): @"MPMediaGroupingAlbumArtist",
      @(MPMediaGroupingArtist): @"MPMediaGroupingArtist",
      @(MPMediaGroupingComposer): @"MPMediaGroupingComposer",
      @(MPMediaGroupingGenre): @"MPMediaGroupingGenre",
      @(MPMediaGroupingPlaylist): @"MPMediaGroupingPlaylist",
      @(MPMediaGroupingPodcastTitle): @"MPMediaGroupingPodcastTitle",
      @(MPMediaGroupingTitle): @"MPMediaGroupingTitle"
    };
  });

  return groupingValueToNSStringMap;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (PTNMediaLibraryURLType)ptn_mediaLibraryURLType {
  if (![self.scheme isEqual:[NSURL ptn_mediaLibraryScheme]]) {
    return PTNMediaLibraryURLTypeInvalid;
  }

  if ([self.host isEqual:@"asset"]) {
    return PTNMediaLibraryURLTypeAsset;
  } else if ([self.host isEqual:@"album"]) {
    return PTNMediaLibraryURLTypeAlbum;
  }

  return PTNMediaLibraryURLTypeInvalid;
}

- (PTNMediaLibraryFetchType *)ptn_mediaLibraryFetch {
  auto _Nullable fetch = self.lt_queryDictionary[@"fetch"];
  LTParameterAssert(fetch, @"%@ does not have a 'fetch' query item", self);
  return [PTNMediaLibraryFetchType enumWithName:fetch];
}

- (nullable NSNumber *)ptn_mediaLibraryGrouping {
  auto _Nullable grouping = self.lt_queryDictionary[@"grouping"];
  if (!grouping) {
    return nil;
  }

  auto keys = [[[self class] ptn_groupingValueToNSStringMap] allKeysForObject:grouping];
  LTAssert(keys.count == 1, "Expected to have 1 key for %@, got %lu", grouping,
           (unsigned long)keys.count);
  return keys.firstObject;
}

@end

NS_ASSUME_NONNULL_END
