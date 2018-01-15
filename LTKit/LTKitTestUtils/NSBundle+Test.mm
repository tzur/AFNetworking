// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "NSBundle+Test.h"

NS_ASSUME_NONNULL_BEGIN

// Because this file is a part of a static library, this class is a part of the bundle that is
// linking with this library, which is the bundle of the currently running test target.
@interface LTClassOfCurrentlyRunningTestBundle : NSObject
@end

@implementation LTClassOfCurrentlyRunningTestBundle
@end

@implementation NSBundle (Test)

+ (NSBundle *)lt_testBundle {
  return [NSBundle bundleForClass:[LTClassOfCurrentlyRunningTestBundle class]];
}

@end

NS_ASSUME_NONNULL_END
