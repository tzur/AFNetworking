// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+Gateway.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (Gateway)

+ (NSString *)ptn_gatewayScheme {
  return @"com.lightricks.Photons.Gateway";
}

+ (NSURL *)ptn_gatewayAlbumURLWithKey:(NSString *)key {
  NSURLComponents *components = [[NSURLComponents alloc] init];

  components.scheme = [NSURL ptn_gatewayScheme];
  components.queryItems = @[[NSURLQueryItem queryItemWithName:@"key" value:key]];

  return components.URL;
}

@end

NS_ASSUME_NONNULL_END
