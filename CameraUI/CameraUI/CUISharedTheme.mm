// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUISharedTheme.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUISharedTheme

+ (id<CUITheme>)sharedTheme {
  id<CUITheme> sharedTheme = [JSObjection defaultInjector][@protocol(CUITheme)];
  LTAssert(sharedTheme, @"CUISharedTheme was not set using JSObjection for protocol CUITheme.");
  return sharedTheme;
}

@end

NS_ASSUME_NONNULL_END
