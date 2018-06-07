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
        [NSURLQueryItem queryItemWithName:@"width" value:@"1"],
        [NSURLQueryItem queryItemWithName:@"height" value:@"1"],
        [NSURLQueryItem queryItemWithName:@"pixel_components" value:@"R"],
        [NSURLQueryItem queryItemWithName:@"pixel_data_type" value:@"8Unorm"],
        [NSURLQueryItem queryItemWithName:@"color" value:@"#FF"],
        [NSURLQueryItem queryItemWithName:@"premultiplied" value:@"1"]
    ]];
  });
  return url;
}

+ (NSURL *)dvn_urlOfOneByOneWhiteNonPremultipliedRGBAByteTexture {
  static NSURL *url;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    url = [[self dvn_textureURL] lt_URLByAppendingQueryItems:@[
        [NSURLQueryItem queryItemWithName:@"width" value:@"1"],
        [NSURLQueryItem queryItemWithName:@"height" value:@"1"],
        [NSURLQueryItem queryItemWithName:@"pixel_components" value:@"RGBA"],
        [NSURLQueryItem queryItemWithName:@"pixel_data_type" value:@"8Unorm"],
        [NSURLQueryItem queryItemWithName:@"color" value:@"#FF"],
        [NSURLQueryItem queryItemWithName:@"premultiplied" value:@"0"]
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
