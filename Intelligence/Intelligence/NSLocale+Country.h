// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Category for creating country name strings.
@interface NSLocale (Country)

/// Returns the English name of the receiver's country. If the name is not available for some
/// reason, the country code will be returned, and if the country code is not available, \c nil will
/// be returned.
- (nullable NSString *)int_countryName;

@end

NS_ASSUME_NONNULL_END
