// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "NSBundle+PinkyBundle.h"

NS_ASSUME_NONNULL_BEGIN

/// Used to allow NSBundle to locate the bundle that contains Pinky.
@interface PNKBundleLocator : NSObject
@end

@implementation PNKBundleLocator
@end

@implementation NSBundle (PinkyBundle)

+ (nullable NSBundle *)pnk_bundle {
  auto _Nullable executableBundle = [NSBundle bundleForClass:PNKBundleLocator.class];
  auto _Nullable bundlePath = [executableBundle pathForResource:@"Pinky" ofType:@"bundle"];
  return [NSBundle bundleWithPath:bundlePath];
}

@end

NS_ASSUME_NONNULL_END
