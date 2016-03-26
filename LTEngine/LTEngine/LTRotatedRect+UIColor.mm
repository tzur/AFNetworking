// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRotatedRect+UIColor.h"

@implementation LTRotatedRect (UIColor)

- (UIColor *)color {
  return objc_getAssociatedObject(self, @selector(color));
}

- (void)setColor:(UIColor *)color {
  objc_setAssociatedObject(self, @selector(color), color, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
