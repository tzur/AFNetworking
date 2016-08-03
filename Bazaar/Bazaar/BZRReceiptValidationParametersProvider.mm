// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationParametersProvider.h"

#import "BZRReceiptValidationParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptValidationParametersProvider

- (nullable BZRReceiptValidationParameters *)receiptValidationParameters {
  return [BZRReceiptValidationParameters defaultParameters];
}

@end

NS_ASSUME_NONNULL_END
