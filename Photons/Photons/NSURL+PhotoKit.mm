// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+PhotoKit.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSURL+Query.h>

NS_ASSUME_NONNULL_BEGIN

/// Possible types of PhotoKit URL.
LTEnumImplement(NSUInteger, PTNPhotoKitURLType,
  /// URL of a specific asset.
  PTNPhotoKitURLTypeAsset,
  /// URL of an album by identifier.
  PTNPhotoKitURLTypeAlbum,
  /// URL of an album by type.
  PTNPhotoKitURLTypeAlbumType,
  /// URL of album of albums by type.
  PTNPhotoKitURLTypeMetaAlbumType
);

@implementation NSURL (PhotoKit)

static NSString * const kAssetKey = @"asset";
static NSString * const kAlbumKey = @"album";
static NSString * const kAlbumTypeKey = @"albumType";
static NSString * const kMetaAlbumTypeKey = @"metaAlbumType";
static NSString * const kSubalbumsKey = @"subalbums";
static NSString * const kTypeKey = @"type";
static NSString * const kSubtypeKey = @"subtype";
static NSString * const kFilterSubalbumsKey = @"filterSubalbums";
static NSString * const kTitlePredicateKey = @"title";

+ (NSString *)ptn_photoKitScheme {
  return @"com.lightricks.Photons.PhotoKit";
}

+ (NSURL *)ptn_photoKitAssetURLWithObjectPlaceholder:(PHObjectPlaceholder *)objectPlaceholder {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = kAssetKey;
  components.path = [@"/" stringByAppendingString:objectPlaceholder.localIdentifier];

  return components.URL;
}

+ (NSURL *)ptn_photoKitAssetURLWithAsset:(PHAsset *)asset {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = kAssetKey;
  components.path = [@"/" stringByAppendingString:asset.localIdentifier];

  return components.URL;
}

+ (NSURL *)ptn_photoKitAlbumURLWithCollection:(PHCollection *)collection {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = kAlbumKey;
  components.path = [@"/" stringByAppendingString:collection.localIdentifier];

  return components.URL;
}

#pragma mark -
#pragma mark Types
#pragma mark -

+ (NSURL *)ptn_photoKitAlbumWithType:(PHAssetCollectionType)type
                             subtype:(PHAssetCollectionSubtype)subtype {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = kAlbumTypeKey;
  components.queryItems = @[
    [NSURLQueryItem queryItemWithName:kTypeKey value:[NSString stringWithFormat:@"%lu",
                                                      (unsigned long)type]],
    [NSURLQueryItem queryItemWithName:kSubtypeKey value:[NSString stringWithFormat:@"%lu",
                                                         (unsigned long)subtype]]
  ];

  return components.URL;
}

+ (NSURL *)ptn_photoKitMetaAlbumWithType:(PHAssetCollectionType)type
    subalbums:(const std::vector<PHAssetCollectionSubtype> &)subalbums {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = kMetaAlbumTypeKey;

  NSMutableArray<NSURLQueryItem *> *subalbumsQuery =
      [NSMutableArray arrayWithCapacity:subalbums.size()];
  for (PHAssetCollectionSubtype subalbumType : subalbums) {
    NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:kSubalbumsKey
        value:[NSString stringWithFormat:@"%lu", (unsigned long)subalbumType]];
    [subalbumsQuery addObject:queryItem];
  }

  components.queryItems = [@[
    [NSURLQueryItem queryItemWithName:kTypeKey value:[NSString stringWithFormat:@"%lu",
                                                      (unsigned long)type]],
    [NSURLQueryItem queryItemWithName:kSubtypeKey
        value:[NSString stringWithFormat:@"%lu", (unsigned long)PHAssetCollectionSubtypeAny]],
    [NSURLQueryItem queryItemWithName:kFilterSubalbumsKey value:nil]
  ] arrayByAddingObjectsFromArray:subalbumsQuery];

  return components.URL;
}

+ (NSURL *)ptn_photoKitMetaAlbumWithType:(PHAssetCollectionType)type {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = kMetaAlbumTypeKey;

  components.queryItems = @[
    [NSURLQueryItem queryItemWithName:kTypeKey value:[NSString stringWithFormat:@"%lu",
                                                      (unsigned long)type]],
    [NSURLQueryItem queryItemWithName:kSubtypeKey
        value:[NSString stringWithFormat:@"%lu", (unsigned long)PHAssetCollectionSubtypeAny]]
  ];

  return components.URL;
}

+ (NSURL *)ptn_photoKitUserAlbumsWithTitle:(NSString *)title {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = kMetaAlbumTypeKey;

  NSString *escapedTitle = [title stringByAddingPercentEncodingWithAllowedCharacters:
                            [NSCharacterSet URLQueryAllowedCharacterSet]];
  components.queryItems = @[
    [NSURLQueryItem queryItemWithName:kTypeKey
        value:[NSString stringWithFormat:@"%lu", (unsigned long)PHAssetCollectionTypeAlbum]],
    [NSURLQueryItem queryItemWithName:kSubtypeKey
        value:[NSString stringWithFormat:@"%lu", (unsigned long)PHAssetCollectionSubtypeAny]],
    [NSURLQueryItem queryItemWithName:kTitlePredicateKey value:escapedTitle]
  ];

  return components.URL;
}

#pragma mark -
#pragma mark Convenience types
#pragma mark -

+ (NSURL *)ptn_photoKitCameraRollAlbum {
  return [self ptn_photoKitAlbumWithType:PHAssetCollectionTypeSmartAlbum
                                 subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary];
}

+ (NSURL *)ptn_photoKitSmartAlbums {
  return [self ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeSmartAlbum];
}

+ (NSURL *)ptn_photoKitPhotosAppSmartAlbums {
  std::vector<PHAssetCollectionSubtype> subalbums = {
    PHAssetCollectionSubtypeSmartAlbumUserLibrary,
    PHAssetCollectionSubtypeSmartAlbumFavorites,
    PHAssetCollectionSubtypeSmartAlbumVideos,
    PHAssetCollectionSubtypeSmartAlbumSelfPortraits,
    PHAssetCollectionSubtypeSmartAlbumPanoramas,
    PHAssetCollectionSubtypeSmartAlbumTimelapses,
    PHAssetCollectionSubtypeSmartAlbumSlomoVideos,
    PHAssetCollectionSubtypeSmartAlbumBursts,
    PHAssetCollectionSubtypeSmartAlbumScreenshots,
    PHAssetCollectionSubtypeSmartAlbumGeneric
  };

  return [self ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeSmartAlbum
                                   subalbums:subalbums];
}

+ (NSURL *)ptn_photoKitUserAlbums {
  return [self ptn_photoKitMetaAlbumWithType:PHAssetCollectionTypeAlbum];
}

#pragma mark -
#pragma mark Getters
#pragma mark -

- (nullable PTNPhotoKitURLType *)ptn_photoKitURLType {
  if (![self.scheme isEqual:[NSURL ptn_photoKitScheme]]) {
    return nil;
  }

  if ([self.host isEqual:kAssetKey] && !self.query && self.path.length > 0) {
    return $(PTNPhotoKitURLTypeAsset);
  } else if ([self.host isEqual:kAlbumKey] && !self.query && self.path.length > 0) {
    return $(PTNPhotoKitURLTypeAlbum);
  } else if ([self.host isEqual:kAlbumTypeKey]) {
    NSDictionary<NSString *, NSString *> *query = self.lt_queryDictionary;
    if (query[kTypeKey] && query[kSubtypeKey]) {
      return $(PTNPhotoKitURLTypeAlbumType);
    }

    return nil;
  } else if ([self.host isEqual:kMetaAlbumTypeKey]) {
    NSDictionary<NSString *, NSString *> *query = self.lt_queryDictionary;
    if (query[kTypeKey] && query[kSubtypeKey]) {
      return $(PTNPhotoKitURLTypeMetaAlbumType);
    }

    return nil;
  }

  return nil;
}

- (nullable NSString *)ptn_photoKitAlbumIdentifier {
  if (![self.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbum)]) {
    return nil;
  }

  return [self.path substringFromIndex:1];
}

- (nullable NSString *)ptn_photoKitAssetIdentifier {
  if (![self.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAsset)]) {
    return nil;
  }

  return [self.path substringFromIndex:1];
}

- (nullable NSNumber *)ptn_photoKitAlbumType {
  if (![self.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbumType)] &&
      ![self.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)]) {
    return nil;
  }

  return @(self.lt_queryDictionary[kTypeKey].integerValue);
}

- (nullable NSNumber *)ptn_photoKitAlbumSubtype {
  if (![self.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbumType)] &&
      ![self.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)]) {
    return nil;
  }

  return @(self.lt_queryDictionary[kSubtypeKey].integerValue);
}

- (nullable NSArray<NSNumber *> *)ptn_photoKitAlbumSubalbums {
  if (![self.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)]) {
    return nil;
  }

  if (!self.lt_queryDictionary[kFilterSubalbumsKey]) {
    return nil;
  }

  return [self.lt_queryArrayDictionary[kSubalbumsKey] lt_map:^NSNumber *(NSString *string) {
    return @(string.integerValue);
  }] ?: @[];
}

- (nullable PHFetchOptions *)ptn_photoKitAlbumFetchOptions {
  if (![self.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)]) {
    return nil;
  }

  NSString * _Nullable escapedTitlePredicate = self.lt_queryDictionary[kTitlePredicateKey];
  if (!escapedTitlePredicate) {
    return nil;
  }

  NSString *titlePredicate = [escapedTitlePredicate stringByRemovingPercentEncoding];
  PHFetchOptions *options = [[PHFetchOptions alloc] init];
  options.predicate = [NSPredicate predicateWithFormat:@"title=%@", titlePredicate];
  return options;
}

@end

NS_ASSUME_NONNULL_END
