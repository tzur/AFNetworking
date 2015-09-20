// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSBundle+LTEngineBundle.h"

@implementation NSBundle (LTKitBundle)

+ (NSBundle *)LTEngineBundle {
  return [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"LTEngine"
                                                                  ofType:@"bundle"]];
}

@end
