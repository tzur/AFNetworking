// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSLocale+Language.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSLocale (Language)

- (NSString *)lt_preferredLanguage {
  // There must always be at least one language configured, which is the primary language of the
  // device.
  return nn([NSLocale preferredLanguages].firstObject);
}

- (NSString *)lt_currentAppLanguage {
  // There must be at least one localization for the main bundle.
  return nn([[NSBundle mainBundle] preferredLocalizations].firstObject);
}

@end

NS_ASSUME_NONNULL_END
