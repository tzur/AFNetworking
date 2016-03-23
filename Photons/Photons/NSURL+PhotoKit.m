// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+PhotoKit.h"

#import <Photos/Photos.h>

#import "NSURL+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (PhotoKit)

+ (NSString *)ptn_photoKitScheme {
  return @"com.lightricks.Photons.PhotoKit";
}

+ (NSURL *)ptn_photoKitAssetURLWithAsset:(PHAsset *)asset {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = @"asset";
  components.path = [@"/" stringByAppendingString:asset.localIdentifier];

  return components.URL;
}

+ (NSURL *)ptn_photoKitAlbumURLWithCollection:(PHCollection *)collection {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = @"album";
  components.path = [@"/" stringByAppendingString:collection.localIdentifier];

  return components.URL;
}

+ (NSURL * __nonnull)ptn_photoKitAlbumWithType:(PTNPhotoKitAlbumType)type {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  NSString *typeString =
      [NSString stringWithFormat:@"%lu", (unsigned long)PTNPhotoKitURLTypeAlbumType];
  NSString *subtypeString = [NSString stringWithFormat:@"%lu", (unsigned long)type];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = @"album";
  components.queryItems = @[[NSURLQueryItem queryItemWithName:@"type" value:typeString],
                            [NSURLQueryItem queryItemWithName:@"subtype" value:subtypeString]];

  return components.URL;
}

+ (NSURL * __nonnull)ptn_photoKitAlbumOfAlbumsWithType:(PTNPhotoKitAlbumOfAlbumsType)type {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  NSString *typeString = [NSString stringWithFormat:@"%lu",
      (unsigned long)PTNPhotoKitURLTypeAlbumOfAlbumsType];
  NSString *subtypeString = [NSString stringWithFormat:@"%lu", (unsigned long)type];

  components.scheme = [NSURL ptn_photoKitScheme];
  components.host = @"album";
  components.queryItems = @[[NSURLQueryItem queryItemWithName:@"type" value:typeString],
                            [NSURLQueryItem queryItemWithName:@"subtype" value:subtypeString]];

  return components.URL;
}

- (PTNPhotoKitURLType)ptn_photoKitURLType {
  if (![self.scheme isEqual:[NSURL ptn_photoKitScheme]]) {
    return PTNPhotoKitURLTypeInvalid;
  }

  if ([self.host isEqual:@"album"]) {
    if (self.query) {
      NSDictionary<NSString *, NSString *> *query = self.ptn_queryDictionary;
      if (query[@"type"] && query[@"subtype"]) {
        if (query[@"type"].integerValue == PTNPhotoKitURLTypeAlbumType) {
          return PTNPhotoKitURLTypeAlbumType;
        }
        if (query[@"type"].integerValue == PTNPhotoKitURLTypeAlbumOfAlbumsType) {
          return PTNPhotoKitURLTypeAlbumOfAlbumsType;
        }
      }
    } else if (self.path.length > 0) {
      return PTNPhotoKitURLTypeAlbum;
    }
  } else if ([self.host isEqual:@"asset"] && !self.query && self.path.length > 0) {
    return PTNPhotoKitURLTypeAsset;
  }

  return PTNPhotoKitURLTypeInvalid;
}

- (nullable NSString *)ptn_photoKitAlbumIdentifier {
  if (self.ptn_photoKitURLType != PTNPhotoKitURLTypeAlbum) {
    return nil;
  }

  return [self.path substringFromIndex:1];
}

- (nullable NSString *)ptn_photoKitAssetIdentifier {
  if (self.ptn_photoKitURLType != PTNPhotoKitURLTypeAsset) {
    return nil;
  }

  return [self.path substringFromIndex:1];
}

- (PTNPhotoKitAlbumType)ptn_photoKitAlbumType {
  if (self.ptn_photoKitURLType != PTNPhotoKitURLTypeAlbumType) {
    return PTNPhotoKitAlbumTypeInvalid;
  }

  NSDictionary<NSString *, NSString *> *query = self.ptn_queryDictionary;
  if (!query[@"subtype"]) {
    return PTNPhotoKitAlbumTypeInvalid;
  }

  return query[@"subtype"].integerValue;
}

- (PTNPhotoKitAlbumOfAlbumsType)ptn_photoKitAlbumOfAlbumsType {
  if (self.ptn_photoKitURLType != PTNPhotoKitURLTypeAlbumOfAlbumsType) {
    return PTNPhotoKitAlbumOfAlbumsTypeInvalid;
  }

  NSDictionary<NSString *, NSString *> *query = self.ptn_queryDictionary;
  if (!query[@"subtype"]) {
    return PTNPhotoKitAlbumOfAlbumsTypeInvalid;
  }

  return query[@"subtype"].integerValue;
}

@end

NS_ASSUME_NONNULL_END
