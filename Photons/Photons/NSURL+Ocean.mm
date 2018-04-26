// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "NSURL+Ocean.h"

#import <LTKit/NSURL+Query.h>

#import "PTNOceanEnums.h"

NS_ASSUME_NONNULL_BEGIN

/// Possible types of Ocean URLs.
LTEnumImplement(NSUInteger, PTNOceanURLType,
  /// Album URL type.
  PTNOceanURLTypeAlbum,
  /// Asset URL type.
  PTNOceanURLTypeAsset
);

@implementation NSURL (Ocean)

+ (NSString *)ptn_oceanScheme {
  return @"com.lightricks.Photons.Ocean";
}

+ (NSURL *)ptn_oceanAlbumURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType
                                phrase:(nullable NSString *)phrase {
  return [NSURL ptn_oceanAlbumURLWithSource:source assetType:assetType phrase:phrase page:1];
}

+ (NSURL *)ptn_oceanAlbumURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType
                                phrase:(nullable NSString *)phrase page:(NSUInteger)page {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = [self ptn_oceanScheme];
  components.host = @"album";

  NSMutableArray *queryItems =
      [@[[NSURLQueryItem queryItemWithName:@"source" value:source.identifier],
         [NSURLQueryItem queryItemWithName:@"type" value:assetType.name]] mutableCopy];

  if (phrase) {
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"phrase" value:phrase]];
  }
  [queryItems addObject:[NSURLQueryItem queryItemWithName:@"page"
                         value:[NSString stringWithFormat:@"%lu", (unsigned long)page]]];
  components.queryItems = queryItems;
  return components.URL;
}

+ (NSURL *)ptn_oceanAssetURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType
                            identifier:(NSString *)identifier {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = [self ptn_oceanScheme];
  components.host = @"asset";
  components.queryItems = @[
    [NSURLQueryItem queryItemWithName:@"id" value:identifier],
    [NSURLQueryItem queryItemWithName:@"source" value:source.identifier],
    [NSURLQueryItem queryItemWithName:@"type" value:assetType.name]
  ];
  return components.URL;
}

- (nullable PTNOceanURLType *)ptn_oceanURLType {
  if (![self.scheme isEqualToString:[NSURL ptn_oceanScheme]]) {
    return nil;
  }
  if ([self.host isEqualToString:@"album"]) {
    return $(PTNOceanURLTypeAlbum);
  }
  if ([self.host isEqualToString:@"asset"]) {
    return $(PTNOceanURLTypeAsset);
  }
  return nil;
}

- (nullable PTNOceanAssetType *)ptn_oceanAssetType {
  if (![self.scheme isEqualToString:[NSURL ptn_oceanScheme]]) {
    return nil;
  }
  NSString * _Nullable type = [self lt_queryDictionary][@"type"];
  if (!type) {
    return nil;
  }
  return [PTNOceanAssetType enumWithName:type];
}

@end

NS_ASSUME_NONNULL_END
