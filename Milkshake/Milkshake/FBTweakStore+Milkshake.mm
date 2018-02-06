// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "FBTweakStore+Milkshake.h"

#import "SHKTweakCategory.h"
#import "SHKTweakCategoryAdapter.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBTweakStore (Milkshake)

- (void)shk_addTweakCategory:(id<SHKTweakCategory>)category {
  auto nativeCategory = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:category];
  [self addTweakCategory:nativeCategory];
}

@end

NS_ASSUME_NONNULL_END
