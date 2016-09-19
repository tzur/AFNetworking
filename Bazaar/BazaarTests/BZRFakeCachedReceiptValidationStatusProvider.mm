// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRFakeCachedReceiptValidationStatusProvider.h"

#import "BZRKeychainStorage.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakeCachedReceiptValidationStatusProvider

@synthesize receiptValidationStatus = _receiptValidationStatus;

- (instancetype)init {
  BZRKeychainStorage *keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  id<BZRReceiptValidationStatusProvider> underlyingProvider =
      OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
  OCMStub([underlyingProvider nonCriticalErrorsSignal]).andReturn([RACSignal empty]);
  return [super initWithKeychainStorage:keychainStorage underlyingProvider:underlyingProvider];
}

@end

NS_ASSUME_NONNULL_END
