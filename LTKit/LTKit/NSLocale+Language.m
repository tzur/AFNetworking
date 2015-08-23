// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSLocale+Language.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSLocale (Language)

- (NSString *)lt_preferredLanguage {
  return [NSLocale preferredLanguages].firstObject;
}

- (NSString *)lt_currentAppLanguage {
  return [[NSBundle mainBundle] preferredLocalizations].firstObject;
}

@end

NS_ASSUME_NONNULL_END
