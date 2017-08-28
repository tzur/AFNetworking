// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "NSURL+Ocean.h"

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
                                phrase:(nullable NSString *)phrase {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = [self ptn_oceanScheme];
  components.host = @"album";

  NSMutableArray *queryItems =
      [@[[NSURLQueryItem queryItemWithName:@"source" value:source.identifier]] mutableCopy];

  if (phrase) {
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"phrase" value:phrase]];
  }
  components.queryItems = queryItems;
  return components.URL;
}

+ (NSURL *)ptn_oceanAssetURLWithSource:(PTNOceanAssetSource *)source
                            identifier:(NSString *)identifier {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = [self ptn_oceanScheme];
  components.host = @"asset";
  components.queryItems = @[
    [NSURLQueryItem queryItemWithName:@"id" value:identifier],
    [NSURLQueryItem queryItemWithName:@"source" value:source.identifier]
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

@end

NS_ASSUME_NONNULL_END
