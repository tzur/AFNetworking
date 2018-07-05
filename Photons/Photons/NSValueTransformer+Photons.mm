// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "NSValueTransformer+Photons.h"

#import <Mantle/MTLValueTransformer.h>

NS_ASSUME_NONNULL_BEGIN

NSString * const kPTNURLValueTransformer = @"PTNURLValueTransformer";

@interface NSValueTransformer (Photons)
@end

@implementation NSValueTransformer (Photons)

+ (void)load {
  @autoreleasepool {
    [NSValueTransformer setValueTransformer:[self ptn_URLValueTransformer]
                                    forName:kPTNURLValueTransformer];
  }
}

+ (instancetype)ptn_URLValueTransformer {
  return [MTLValueTransformer
          reversibleTransformerWithForwardBlock:^NSURL * _Nullable(NSString * _Nullable URLString) {
    if (!URLString) {
      return nil;
    }
    if (![URLString isKindOfClass:[NSString class]]) {
      LogError(@"Expected NSString, got: %@", NSStringFromClass([URLString class]));
      return nil;
    }
    NSString *escapedUrl = [URLString stringByAddingPercentEncodingWithAllowedCharacters:
                            [NSCharacterSet URLQueryAllowedCharacterSet]];
    return [NSURL URLWithString:escapedUrl];
  } reverseBlock:^NSString * _Nullable(NSURL * _Nullable url) {
    LTParameterAssert(!url || [url isKindOfClass:[NSURL class]], @"Expected NSURL, got: %@",
                      [url class]);
    return url.absoluteString;
  }];
}

@end

NS_ASSUME_NONNULL_END
