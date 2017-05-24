// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSLocale+Country.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSLocale (Country)

- (nullable NSString *)int_countryName {
  NSString * _Nullable countryCode = self.countryCode;

  auto englishLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
  auto _Nullable countryName =
      [englishLocale displayNameForKey:NSLocaleCountryCode value:countryCode];

  return countryName ?: countryCode;
}

@end

NS_ASSUME_NONNULL_END
