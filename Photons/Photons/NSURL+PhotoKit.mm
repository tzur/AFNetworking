// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+PhotoKit.h"

#import <Photos/Photos.h>

#import "NSURL+Photons.h"

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

/// Possible types of PhotoKit album type.
LTEnumImplement(NSUInteger, PTNPhotoKitAlbumType,
  /// Album type of user's camera roll.
  PTNPhotoKitAlbumTypeCameraRoll
);

/// Possible types of PhotoKit albums of album types.
LTEnumImplement(NSUInteger, PTNPhotoKitMetaAlbumType,
  /// Album of album types included in operating system's albums.
  PTNPhotoKitMetaAlbumTypeSmartAlbums,
  /// Album of album types included in operating system's albums as displayed in the Photos app.
  PTNPhotoKitMetaAlbumTypePhotosAppSmartAlbums,
  /// Album of user's albums.
  PTNPhotoKitMetaAlbumTypeUserAlbums
);

@implementation NSURL (PhotoKit)

static NSString * const kAssetKey = @"asset";
static NSString * const kAlbumKey = @"album";
static NSString * const kTypeKey = @"type";
static NSString * const kSubtypeKey = @"subtype";

+ (NSString *)ptn_photoKitScheme {
  return @"com.lightricks.Photons.PhotoKit";
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

+ (NSURL * __nonnull)ptn_photoKitAlbumWithType:(PTNPhotoKitAlbumType *)type {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  PTNPhotoKitURLType *urlType = $(PTNPhotoKitURLTypeAlbumType);

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = kAlbumKey;
  components.queryItems = @[[NSURLQueryItem queryItemWithName:kTypeKey value:urlType.name],
                            [NSURLQueryItem queryItemWithName:kSubtypeKey value:type.name]];

  return components.URL;
}

+ (NSURL * __nonnull)ptn_photoKitMetaAlbumWithType:(PTNPhotoKitMetaAlbumType *)type {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  PTNPhotoKitURLType *urlType = $(PTNPhotoKitURLTypeMetaAlbumType);

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = kAlbumKey;
  components.queryItems = @[[NSURLQueryItem queryItemWithName:kTypeKey value:urlType.name],
                            [NSURLQueryItem queryItemWithName:kSubtypeKey value:type.name]];

  return components.URL;
}

- (nullable PTNPhotoKitURLType *)ptn_photoKitURLType {
  if (![self.scheme isEqual:[NSURL ptn_photoKitScheme]]) {
    return nil;
  }

  if ([self.host isEqual:kAlbumKey]) {
    if (self.query) {
      NSDictionary<NSString *, NSString *> *query = self.ptn_queryDictionary;
      if (query[kTypeKey] && query[kSubtypeKey]) {
        PTNPhotoKitURLType *type = [PTNPhotoKitURLType enumWithName:query[kTypeKey]];
        if (type.value == PTNPhotoKitURLTypeAlbumType) {
          return $(PTNPhotoKitURLTypeAlbumType);
        }
        if (type.value == PTNPhotoKitURLTypeMetaAlbumType) {
          return $(PTNPhotoKitURLTypeMetaAlbumType);
        }
      }
    } else if (self.path.length > 0) {
      return $(PTNPhotoKitURLTypeAlbum);
    }
  } else if ([self.host isEqual:kAssetKey] && !self.query && self.path.length > 0) {
    return $(PTNPhotoKitURLTypeAsset);
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

- (nullable PTNPhotoKitAlbumType *)ptn_photoKitAlbumType {
  if (![self.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeAlbumType)]) {
    return nil;
  }

  NSDictionary<NSString *, NSString *> *query = self.ptn_queryDictionary;
  if (!query[kSubtypeKey]) {
    return nil;
  }

  return [PTNPhotoKitAlbumType enumWithName:query[kSubtypeKey]];
}

- (nullable PTNPhotoKitMetaAlbumType *)ptn_photoKitMetaAlbumType {
  if (![self.ptn_photoKitURLType isEqual:$(PTNPhotoKitURLTypeMetaAlbumType)]) {
    return nil;
  }

  NSDictionary<NSString *, NSString *> *query = self.ptn_queryDictionary;
  if (!query[kSubtypeKey]) {
    return nil;
  }

  return [PTNPhotoKitMetaAlbumType enumWithName:query[kSubtypeKey]];
}

@end

NS_ASSUME_NONNULL_END
