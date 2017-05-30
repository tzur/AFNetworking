// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "NSBundle+PinkyBundle.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSBundle (PinkyBundle)

+ (nullable NSBundle *)pnk_bundle {
  return [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"Pinky"
                                                                  ofType:@"bundle"]];
}

@end

NS_ASSUME_NONNULL_END
