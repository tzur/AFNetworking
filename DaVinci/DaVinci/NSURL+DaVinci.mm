// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "NSURL+DaVinci.h"

#import <LTKit/NSURL+Query.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (DaVinci)

+ (NSString *)dvn_scheme {
  return @"com.lightricks.DaVinci";
}

+ (NSURL *)dvn_urlOfSourceTexture {
  static NSURL *url;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    url = [[self dvn_textureURL] lt_URLByAppendingQueryItems:@[
        [NSURLQueryItem queryItemWithName:@"id" value:@"source"]
    ]];
  });
  return url;
}

+ (NSURL *)dvn_urlOfEdgeAvoidanceTexture {
  static NSURL *url;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    url = [[self dvn_textureURL] lt_URLByAppendingQueryItems:@[
      [NSURLQueryItem queryItemWithName:@"id" value:@"edgeAvoidance"]
    ]];
  });
  return url;
}

+ (NSURL *)dvn_urlOfOneByOneWhiteSingleChannelByteTexture {
  static NSURL *url;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    url = [[self dvn_textureURL] lt_URLByAppendingQueryItems:@[
        [NSURLQueryItem queryItemWithName:@"id" value:@"1_x_1_white_single_channel_byte_texture"],
    ]];
  });
  return url;
}

+ (NSURL *)dvn_urlOfOneByOneWhiteNonPremultipliedRGBAByteTexture {
  static NSURL *url;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    url = [[self dvn_textureURL] lt_URLByAppendingQueryItems:@[
      [NSURLQueryItem queryItemWithName:@"id" value:@"1_x_1_white_non_premultiplied_rgba_texture"],
    ]];
  });
  return url;
}

+ (NSURL *)dvn_textureURL {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = [self dvn_scheme];
  components.host = @"texture";
  return components.URL;
}

@end

NS_ASSUME_NONNULL_END
