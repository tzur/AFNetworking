// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSBundle+LTKitBundle.h"

@implementation NSBundle (LTKitBundle)

+ (NSBundle *)LTKitBundle {
  return [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"LTKit"
                                                                  ofType:@"bundle"]];
}

@end
