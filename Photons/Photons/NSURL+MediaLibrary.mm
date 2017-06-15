// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSURL+MediaLibrary.h"

#import <LTKit/NSURL+Query.h>
#import <MediaPlayer/MediaPlayer.h>
#import <errno.h>

NS_ASSUME_NONNULL_BEGIN

/// Supported types of media library queries.
LTEnumImplement(NSUInteger, PTNMediaLibraryQueryType,
  /// Returns all the music artists in the library sorted by artist name.
  PTNMediaLibraryQueryTypeArtists,
  /// Returns all the music albums in the library sorted by album name.
  PTNMediaLibraryQueryTypeAlbums,
  /// Returns all the songs in the library sorted by song name.
  PTNMediaLibraryQueryTypeSongs
);

@implementation NSURL (MediaLibrary)

+ (NSString *)ptn_mediaLibraryScheme {
  return @"com.lightricks.Photons.MediaLibrary";
}

+ (NSURL *)ptn_mediaLibraryAssetURLWithItem:(MPMediaItem *)item {
  return [self ptn_mediaLibraryURLForType:PTNMediaLibraryURLTypeAsset entity:item];
}

+ (NSURL *)ptn_mediaLibraryAlbumURLWithCollection:(MPMediaItemCollection *)collection {
  return [self ptn_mediaLibraryURLForType:PTNMediaLibraryURLTypeAlbum entity:collection];
}

+ (NSURL *)ptn_mediaLibraryURLForType:(PTNMediaLibraryURLType)type entity:(MPMediaEntity *)entity {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_mediaLibraryScheme];
  components.host = (type == PTNMediaLibraryURLTypeAlbum) ? @"album" : @"asset";
  components.path = [NSString stringWithFormat:@"/%llu", entity.persistentID];

  return components.URL;
}

+ (NSURL *)ptn_mediaLibraryQueryURLWithType:(PTNMediaLibraryQueryType *)type {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_mediaLibraryScheme];
  components.host = @"query";
  components.queryItems = @[[NSURLQueryItem queryItemWithName:@"type" value:type.name]];

  return components.URL;
}

+ (NSURL *)ptn_mediaLibraryAlbumsQueryURL {
  return [NSURL ptn_mediaLibraryQueryURLWithType:$(PTNMediaLibraryQueryTypeAlbums)];
}

+ (NSURL *)ptn_mediaLibraryArtistsQueryURL {
  return [NSURL ptn_mediaLibraryQueryURLWithType:$(PTNMediaLibraryQueryTypeArtists)];
}

+ (NSURL *)ptn_mediaLibrarySongsQueryURL {
  return [NSURL ptn_mediaLibraryQueryURLWithType:$(PTNMediaLibraryQueryTypeSongs)];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (PTNMediaLibraryURLType)ptn_mediaLibraryURLType {
  if (![self.scheme isEqual:[NSURL ptn_mediaLibraryScheme]]) {
    return PTNMediaLibraryURLTypeInvalid;
  }

  if ([self.host isEqual:@"asset"] && [self persistentID]) {
    return PTNMediaLibraryURLTypeAsset;
  } else if ([self.host isEqual:@"album"] && [self persistentID]) {
    return PTNMediaLibraryURLTypeAlbum;
  } else if ([self.host isEqual:@"query"] && self.lt_queryDictionary[@"type"]) {
    return PTNMediaLibraryURLTypeQuery;
  }

  return PTNMediaLibraryURLTypeInvalid;
}

- (nullable NSNumber *)persistentID {
  if (![self.path hasPrefix:@"/"]) {
    return nil;
  }
  errno = 0;
  auto number = strtoull([[self.path substringFromIndex:1] UTF8String], NULL, 10);
  if (errno == ERANGE) {
    return nil;
  }
  return @(number);
}

- (nullable PTNMediaLibraryQueryType *)ptn_mediaLibraryQueryType {
  if (![self.scheme isEqual:[NSURL ptn_mediaLibraryScheme]]) {
    return nil;
  }

  if (![self.host isEqual:@"query"]) {
    return nil;
  }

  auto _Nullable typeName = self.lt_queryDictionary[@"type"];
  if (!typeName) {
    return nil;
  }
  auto _Nullable type = [PTNMediaLibraryQueryType enumWithName:typeName];
  if (!type) {
    return nil;
  }

  return type;
}

- (nullable NSNumber *)ptn_mediaLibraryPersistentID {
  if (self.ptn_mediaLibraryURLType != PTNMediaLibraryURLTypeAsset &&
      self.ptn_mediaLibraryURLType != PTNMediaLibraryURLTypeAlbum) {
    return nil;
  }

  return [self persistentID];
}

@end

NS_ASSUME_NONNULL_END
