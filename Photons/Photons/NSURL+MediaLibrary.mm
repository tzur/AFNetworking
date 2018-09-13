// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSURL+MediaLibrary.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSURL+Query.h>
#import <MediaPlayer/MediaPlayer.h>

#import "PTNMediaQueryProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Fetching option of Media Library entities.
LTEnumImplement(NSUInteger, PTNMediaLibraryFetchType,
  /// fetch entities as list of items.
  PTNMediaLibraryFetchTypeItems,
  /// fetch entities as list of collections.
  PTNMediaLibraryFetchTypeCollections
);

#pragma mark -
#pragma mark NSURL+MediaLibrary
#pragma mark -

@implementation NSURL (MediaLibrary)

- (NSArray<NSString *> *)ptn_valuesForPredicate:(NSString *)predicate {
  auto queryArrayDictionary = [self lt_queryArrayDictionary];
  return queryArrayDictionary[predicate] ?: @[];
}

+ (NSString *)ptn_mediaLibraryScheme {
  return @"com.lightricks.Photons.MediaLibrary";
}

+ (NSURL *)ptn_mediaLibraryAssetWithItem:(MPMediaItem *)item {
  auto predicate = [MPMediaPropertyPredicate predicateWithValue:@(item.persistentID)
                    forProperty:MPMediaItemPropertyPersistentID];
  auto predicates = [[NSURL ptn_unavailableAssetsPredicates] arrayByAddingObject:predicate];

  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAsset
                    predicates:[predicates lt_set]
                     fetchType:$(PTNMediaLibraryFetchTypeItems) groupedBy:nil];
}

// Apple music assets aren't available for downloading, therefore, we filter them in advance.
+ (NSArray<MPMediaPropertyPredicate *> *)ptn_unavailableAssetsPredicates {
  auto cloudPredicate = [MPMediaPropertyPredicate predicateWithValue:@(NO)
                         forProperty:MPMediaItemPropertyIsCloudItem];
  auto protectedAssetPredicate = [MPMediaPropertyPredicate predicateWithValue:@(NO)
                                  forProperty:MPMediaItemPropertyHasProtectedAsset];
  return @[cloudPredicate, protectedAssetPredicate];
}

+ (NSURL *)ptn_mediaLibraryAlbumMusicAlbumSongsWithItem:(MPMediaItem *)item {
  auto predicate = [MPMediaPropertyPredicate predicateWithValue:@(item.albumPersistentID)
                    forProperty:MPMediaItemPropertyAlbumPersistentID];
  auto predicates = [[NSURL ptn_unavailableAssetsPredicates] arrayByAddingObject:predicate];

  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[predicates lt_set]
                     fetchType:$(PTNMediaLibraryFetchTypeItems) groupedBy:nil];
}

+ (NSURL *)ptn_mediaLibraryAlbumArtistMusicAlbumsWithItem:(MPMediaItem *)item {
  auto predicate = [MPMediaPropertyPredicate predicateWithValue:@(item.artistPersistentID)
                    forProperty:MPMediaItemPropertyArtistPersistentID];
  auto predicates = [[NSURL ptn_unavailableAssetsPredicates] arrayByAddingObject:predicate];

  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[predicates lt_set]
                     fetchType:$(PTNMediaLibraryFetchTypeCollections)
                     groupedBy:@(MPMediaGroupingAlbum)];
}

+ (NSURL *)ptn_mediaLibraryAlbumArtistSongsWithItem:(MPMediaItem *)item {
  auto predicate = [MPMediaPropertyPredicate predicateWithValue:@(item.artistPersistentID)
                    forProperty:MPMediaItemPropertyArtistPersistentID];
  auto predicates = [[NSURL ptn_unavailableAssetsPredicates] arrayByAddingObject:predicate];

  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[predicates lt_set]
                     fetchType:$(PTNMediaLibraryFetchTypeItems) groupedBy:nil];
}

+ (NSURL *)ptn_mediaLibraryAlbumSongsByMusicAlbum {
  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[self ptn_mediaTypeMusicPredicates]
                     fetchType:$(PTNMediaLibraryFetchTypeCollections)
                     groupedBy:@(MPMediaGroupingAlbum)];
}

+ (NSURL *)ptn_mediaLibraryAlbumSongsByAritst {
  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[self ptn_mediaTypeMusicPredicates]
                     fetchType:$(PTNMediaLibraryFetchTypeCollections)
                     groupedBy:@(MPMediaGroupingArtist)];
}

+ (NSURL *)ptn_mediaLibraryAlbumSongs {
  return [self ptn_urlWithType:PTNMediaLibraryURLTypeAlbum
                    predicates:[self ptn_mediaTypeMusicPredicates]
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

+ (NSSet<MPMediaPropertyPredicate *> *)ptn_mediaTypeMusicPredicates {
  auto predicate =  [MPMediaPropertyPredicate predicateWithValue:@(MPMediaTypeMusic)
                                                     forProperty:MPMediaItemPropertyMediaType];
  auto predicates = [[NSURL ptn_unavailableAssetsPredicates] arrayByAddingObject:predicate];
  return [predicates lt_set];
}

+ (LTBidirectionalMap<NSNumber *, NSString *> *)ptn_groupingValueToNSStringMap {
  static LTBidirectionalMap<NSNumber *, NSString *> *groupingValueToNSStringMap;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    groupingValueToNSStringMap = [LTBidirectionalMap mapWithDictionary:@{
      @(MPMediaGroupingAlbum): @"MPMediaGroupingAlbum",
      @(MPMediaGroupingAlbumArtist): @"MPMediaGroupingAlbumArtist",
      @(MPMediaGroupingArtist): @"MPMediaGroupingArtist",
      @(MPMediaGroupingComposer): @"MPMediaGroupingComposer",
      @(MPMediaGroupingGenre): @"MPMediaGroupingGenre",
      @(MPMediaGroupingPlaylist): @"MPMediaGroupingPlaylist",
      @(MPMediaGroupingPodcastTitle): @"MPMediaGroupingPodcastTitle",
      @(MPMediaGroupingTitle): @"MPMediaGroupingTitle"
    }];
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

  return [[[self class] ptn_groupingValueToNSStringMap] keyForObject:grouping];
}

@end

#pragma mark -
#pragma mark NSURL+PTNMediaQuery
#pragma mark -

@implementation NSURL (PTNMediaQuery)

- (nullable id<PTNMediaQuery>)ptn_mediaLibraryQueryWithProvider:
      (id<PTNMediaQueryProvider>)provider {
  if (![self.scheme isEqualToString:[NSURL ptn_mediaLibraryScheme]] ||
      (![self.host isEqualToString:@"asset"] && ![self.host isEqualToString:@"album"]) ||
      ![self ptn_hasValidQueryItems]) {
    return nil;
  }

  auto _Nullable predicateQueryItems = [self ptn_predicateQueryItems];
  LTAssert(predicateQueryItems, "predicate query items should not be nil at this stage");

  auto predicates = [NSMutableSet<MPMediaPropertyPredicate *> set];
  for (NSURLQueryItem *queryItem in predicateQueryItems) {
    auto _Nullable predicate = [[self class] ptn_predicateWithProperty:queryItem.name
                                                                 value:queryItem.value];
    if (!predicate) {
      return nil;
    }
    [predicates addObject:predicate];
  }

  auto query = [provider queryWithFilterPredicates:predicates];

  if (self.ptn_mediaLibraryGrouping) {
    query.groupingType = (MPMediaGrouping)self.ptn_mediaLibraryGrouping.integerValue;
  }

  return query;
}

- (BOOL)ptn_hasValidQueryItems {
  NSDictionary<NSString *, NSArray<NSString *> *> *itemsDictionary = [self lt_queryArrayDictionary];
  auto _Nullable predicateQueryItems = [self ptn_predicateQueryItems];
  auto _Nullable fetches = itemsDictionary[@"fetch"];
  auto _Nullable groupings = itemsDictionary[@"grouping"];

  if (!predicateQueryItems || predicateQueryItems.count == 0 || !fetches || fetches.count != 1 ||
      ![PTNMediaLibraryFetchType fieldNamesToValues][fetches.firstObject]) {
    return NO;
  }

  if (groupings) {
    if (groupings.count != 1) {
      return NO;
    }
    if(![[[self class] ptn_groupingValueToNSStringMap] keyForObject:groupings.firstObject]) {
      return NO;
    }
  }

  if ([self.host isEqualToString:@"asset"]) {
    if (groupings || ![fetches.firstObject isEqualToString:$(PTNMediaLibraryFetchTypeItems).name]) {
      return NO;
    }
  }

  for (NSURLQueryItem *queryItem in predicateQueryItems) {
    if(![[[self class] ptn_supportedProperties] containsObject:queryItem.name]) {
      return NO;
    }
  }
  return YES;
}

- (nullable NSArray<NSURLQueryItem *> *)ptn_predicateQueryItems {
  auto _Nullable allQueryItems = [self lt_queryItems];
  if (!allQueryItems) {
    return nil;
  }

  auto propertyPredicateQueryItems = [NSMutableArray<NSURLQueryItem *> array];
  for (NSURLQueryItem *item in allQueryItems) {
    if ([item.name isEqualToString:@"fetch"] || [item.name isEqualToString:@"grouping"]) {
      continue;
    }
    [propertyPredicateQueryItems addObject:item];
  }

  return propertyPredicateQueryItems;
}

+ (nullable MPMediaPropertyPredicate *)ptn_predicateWithProperty:(NSString *)property
                                                           value:(NSString *)value {
  errno = 0;
  if ([self ptn_isUnsignedLongLongProperty:property]) {
    auto number = [NSNumber numberWithUnsignedLongLong:strtoull([value UTF8String], NULL, 0)];
    if (errno) {
      return nil;
    }
    return [MPMediaPropertyPredicate predicateWithValue:number forProperty:property];
  }
  if ([self ptn_isUnsignedLongProperty:property]) {
    auto number = [NSNumber numberWithUnsignedLong:strtoul([value UTF8String], NULL, 0)];
    if (errno) {
      return nil;
    }
    return [MPMediaPropertyPredicate predicateWithValue:number forProperty:property];
  }

  if ([self ptn_isBooleanProperty:property]) {
    return [MPMediaPropertyPredicate predicateWithValue:@([value boolValue]) forProperty:property];
  }

  return [MPMediaPropertyPredicate predicateWithValue:value forProperty:property];
}

+ (BOOL)ptn_isUnsignedLongLongProperty:(NSString *)property {
  return ([property isEqualToString:MPMediaItemPropertyAlbumPersistentID] ||
          [property isEqualToString:MPMediaItemPropertyArtistPersistentID] ||
          [property isEqualToString:MPMediaItemPropertyPersistentID]);
}

+ (BOOL)ptn_isUnsignedLongProperty:(NSString *)property {
  return [property isEqualToString:MPMediaItemPropertyMediaType];
}

+ (BOOL)ptn_isBooleanProperty:(NSString *)property {
  return [property isEqualToString:MPMediaItemPropertyHasProtectedAsset] ||
      [property isEqualToString:MPMediaItemPropertyIsCloudItem];
}

+ (NSSet<NSString *> *)ptn_supportedProperties {
  static NSSet<NSString *> *values;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    values = [NSSet setWithArray:@[
      MPMediaItemPropertyAlbumPersistentID,
      MPMediaItemPropertyAlbumTitle,
      MPMediaItemPropertyArtist,
      MPMediaItemPropertyArtistPersistentID,
      MPMediaItemPropertyMediaType,
      MPMediaItemPropertyPersistentID,
      MPMediaItemPropertyTitle,
      MPMediaItemPropertyIsCloudItem,
      MPMediaItemPropertyHasProtectedAsset
    ]];
  });

  return values;
}

@end

NS_ASSUME_NONNULL_END
