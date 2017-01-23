// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRFakeCachedReceiptValidationStatusProvider.h"

#import "BZRKeychainStorage.h"
#import "BZRTimeProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRFakeCachedReceiptValidationStatusProvider ()

/// \c YES if \c fetchReceiptValidationStatus was called, \c NO otherwise.
@property (readwrite, nonatomic) BOOL wasFetchReceiptValidationStatusCalled;

/// \c YES if \c expireSubscription was called, \c NO otherwise.
@property (readwrite, nonatomic) BOOL wasExpireSubscriptionCalled;

@end

@implementation BZRFakeCachedReceiptValidationStatusProvider

@synthesize receiptValidationStatus = _receiptValidationStatus;
@synthesize lastReceiptValidationDate = _lastReceiptValidationDate;

- (instancetype)init {
  BZRKeychainStorage *keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  id<BZRTimeProvider> timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
  OCMStub([timeProvider currentTime]).andReturn([RACSignal return:[NSDate date]]);

  id<BZRReceiptValidationStatusProvider> underlyingProvider =
      OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
  OCMStub([underlyingProvider eventsSignal]).andReturn([RACSignal empty]);

  return [super initWithKeychainStorage:keychainStorage timeProvider:timeProvider
                     underlyingProvider:underlyingProvider];
}

- (RACSignal *)fetchReceiptValidationStatus {
  self.wasFetchReceiptValidationStatusCalled = YES;
  return self.signalToReturnFromFetchReceiptValidationStatus ?: [RACSignal empty];
}

- (void)expireSubscription {
  self.wasExpireSubscriptionCalled = YES;
}

@end

NS_ASSUME_NONNULL_END
