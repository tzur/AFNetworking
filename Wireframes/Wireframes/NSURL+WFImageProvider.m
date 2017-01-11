// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "NSURL+WFImageProvider.h"

#import <LTKit/NSURL+Query.h>
#import <LTKit/UIColor+Utilities.h>

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
    @"color": [color lt_hexString]
  }];
}

- (NSURL *)wf_URLWithImageLineWidth:(CGFloat)lineWidth {
  return [self lt_URLByAppendingQueryDictionary:@{
    @"lineWidth": [@(lineWidth) stringValue]
  }];
}

@end

NS_ASSUME_NONNULL_END
