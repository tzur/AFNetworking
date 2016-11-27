// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationParametersProvider.h"

#import "BZRReceiptValidationParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptValidationParametersProvider

@synthesize appStoreLocale = _appStoreLocale;

- (nullable BZRReceiptValidationParameters *)receiptValidationParameters {
  return [BZRReceiptValidationParameters defaultParametersWithLocale:self.appStoreLocale];
}

@end

NS_ASSUME_NONNULL_END
