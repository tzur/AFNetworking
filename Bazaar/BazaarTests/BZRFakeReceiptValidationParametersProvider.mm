// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRFakeReceiptValidationParametersProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakeReceiptValidationParametersProvider

@synthesize appStoreLocale = _appStoreLocale;

- (instancetype)init {
  if (self = [super init]) {
    _eventsSubject = [RACSubject subject];
  }
  return self;
}

- (nullable BZRReceiptValidationParameters *)receiptValidationParameters {
  return nil;
}

- (RACSignal *)eventsSignal {
  return self.eventsSubject;
}

@end

NS_ASSUME_NONNULL_END
