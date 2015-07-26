// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+PhotoKit.h"

#import <Photos/Photos.h>

#import "PTNPhotoKitAlbumType.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kPhotoKitScheme = @"com.lightricks.Photons.PhotoKit";

@implementation NSURL (PhotoKit)

+ (NSURL *)ptn_photoKitAssetURLWithAsset:(PHAsset *)asset {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = kPhotoKitScheme;
  components.host = @"asset";
  components.path = [@"/" stringByAppendingString:asset.localIdentifier];

  return components.URL;
}

+ (NSURL *)ptn_photoKitAlbumURLWithCollection:(PHCollection *)collection {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = kPhotoKitScheme;
  components.host = @"album";
  components.path = [@"/" stringByAppendingString:collection.localIdentifier];

  return components.URL;
}

+ (NSURL * __nonnull)ptn_photoKitAlbumsWithType:(PTNPhotoKitAlbumType *)type {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  NSString *typeString = [NSString stringWithFormat:@"%ld", (long)type.type];
  NSString *subtypeString = [NSString stringWithFormat:@"%ld", (long)type.subtype];

  components.scheme = kPhotoKitScheme;
  components.host = @"album";
  components.queryItems = @[[NSURLQueryItem queryItemWithName:@"type" value:typeString],
                            [NSURLQueryItem queryItemWithName:@"subtype" value:subtypeString]];

  return components.URL;
}

- (PTNPhotoKitURLType)ptn_photoKitURLType {
  if (![self.scheme isEqual:kPhotoKitScheme]) {
    return PTNPhotoKitURLTypeInvalid;
  }

  if ([self.host isEqual:@"album"]) {
    if (self.query) {
      NSDictionary *query = self.ptn_queryDictionary;
      if (query[@"type"] && query[@"subtype"]) {
        return PTNPhotoKitURLTypeAlbumType;
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

- (nullable PTNPhotoKitAlbumType *)ptn_photoKitAlbumType {
  if (self.ptn_photoKitURLType != PTNPhotoKitURLTypeAlbumType) {
    return nil;
  }

  NSDictionary *query = self.ptn_queryDictionary;
  if (!query[@"type"] || !query[@"subtype"]) {
    return nil;
  }

  PHAssetCollectionType type = [query[@"type"] integerValue];
  PHAssetCollectionSubtype subtype = [query[@"subtype"] integerValue];

  return [PTNPhotoKitAlbumType albumTypeWithType:type subtype:subtype];
}

- (NSDictionary *)ptn_queryDictionary {
  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];

  // Last query item name overrides previous ones, if exist.
  NSMutableDictionary *items = [NSMutableDictionary dictionary];
  for (NSURLQueryItem *item in components.queryItems) {
    items[item.name] = item.value;
  }

  return [items copy];
}

@end

NS_ASSUME_NONNULL_END
