// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSBundle+LTEngineBundle.h"

/// Used to allow NSBundle to locate the bundle that contains LTEngine.
@interface LTEngineBundleLocator : NSObject
@end

@implementation LTEngineBundleLocator
@end

@implementation NSBundle (LTEngineBundle)

+ (NSBundle *)lt_engineBundle {
  auto _Nullable executableBundle = [NSBundle bundleForClass:LTEngineBundleLocator.class];
  auto _Nullable bundlePath = [executableBundle pathForResource:@"LTEngine" ofType:@"bundle"];
  LTAssert(bundlePath, @"Cannot find LTEngine.bundle in LTEngine's executable directory");
  return [NSBundle bundleWithPath:bundlePath];
}

@end
