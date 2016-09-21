// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+Gateway.h"

#import <LTKit/NSURL+Query.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (Gateway)

static NSString * const kGatewayKeyKey = @"key";
static NSString * const kGatewayAlbumHost = @"album";
static NSString * const kGatewayFlattenedAlbumHost = @"flattenedAlbum";

+ (NSString *)ptn_gatewayScheme {
  return @"com.lightricks.Photons.Gateway";
}

+ (NSURL *)ptn_gatewayAlbumURLWithKey:(NSString *)key {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_gatewayScheme];
  components.host = kGatewayAlbumHost;
  components.queryItems = @[[NSURLQueryItem queryItemWithName:kGatewayKeyKey value:key]];

  return components.URL;
}

+ (NSURL *)ptn_flattenedGatewayAlbumURLWithKey:(NSString *)key {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_gatewayScheme];
  components.host = kGatewayFlattenedAlbumHost;
  components.queryItems = @[[NSURLQueryItem queryItemWithName:kGatewayKeyKey value:key]];

  return components.URL;
}

- (nullable NSString *)ptn_gatewayKey {
  return self.lt_queryDictionary[kGatewayKeyKey];
}

- (BOOL)ptn_isFlattened {
  return [self.host isEqualToString:kGatewayFlattenedAlbumHost];
}

@end

NS_ASSUME_NONNULL_END
