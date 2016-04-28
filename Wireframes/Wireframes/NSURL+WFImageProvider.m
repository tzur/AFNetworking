// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "NSURL+WFImageProvider.h"

#import <LTKit/NSURL+Query.h>

#import "UIColor+Utilities.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (WFImageProvider)

- (NSURL *)wf_URLWithImageSize:(CGSize)size {
  return [self lt_URLByAppendingQueryDictionary:@{
    @"width": [@(size.width) stringValue],
    @"height": [@(size.height) stringValue]
  }];
}

- (NSURL *)wf_URLWithImageColor:(UIColor *)color {
  return [self lt_URLByAppendingQueryDictionary:@{
    @"color": [color wf_hexString]
  }];
}

@end

NS_ASSUME_NONNULL_END
