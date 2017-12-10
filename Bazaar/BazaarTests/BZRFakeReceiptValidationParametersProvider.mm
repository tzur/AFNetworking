// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRFakeReceiptValidationParametersProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakeReceiptValidationParametersProvider

@synthesize appStoreLocale = _appStoreLocale;

- (nullable BZRReceiptValidationParameters *)receiptValidationParametersForApplication:
    (NSString __unused *)applicationBundleID {
  return nil;
}

@end

NS_ASSUME_NONNULL_END
