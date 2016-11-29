// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRCachedReceiptValidationStatusProvider)

__block BZRKeychainStorage *keychainStorage;
__block id<BZRTimeProvider> timeProvider;
__block BZRReceiptValidationStatus *receiptValidationStatus;
__block id<BZRReceiptValidationStatusProvider> underlyingProvider;
__block RACSubject *underlyingEventsSubject;
__block BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

beforeEach(^{
  keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
  receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
  underlyingProvider = OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
  underlyingEventsSubject = [RACSubject subject];
  OCMStub([underlyingProvider eventsSignal]).andReturn(underlyingEventsSubject);
  validationStatusProvider =
      [[BZRCachedReceiptValidationStatusProvider alloc] initWithKeychainStorage:keychainStorage
                                                                   timeProvider:timeProvider
                                                             underlyingProvider:underlyingProvider];
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRCachedReceiptValidationStatusProvider __weak *weakValidationStatusProvider;
    RACSignal *fetchSignal;
    RACSignal *eventsSignal;
    OCMStub([underlyingProvider eventsSignal])
        .andReturn([RACSignal empty]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    @autoreleasepool {
      BZRCachedReceiptValidationStatusProvider *validationStatusProvider =
          [[BZRCachedReceiptValidationStatusProvider alloc] initWithKeychainStorage:keychainStorage
           timeProvider:timeProvider underlyingProvider:underlyingProvider];
      weakValidationStatusProvider = validationStatusProvider;
      fetchSignal = [validationStatusProvider fetchReceiptValidationStatus];
      eventsSignal = [validationStatusProvider eventsSignal];
    }

    expect(eventsSignal).will.complete();
    expect(fetchSignal).will.complete();
    expect(weakValidationStatusProvider).to.beNil();
  });
});

context(@"handling errors", ^{
  it(@"should send event sent by the underlying provider", ^{
    LLSignalTestRecorder *recorder = [validationStatusProvider.eventsSignal testRecorder];
    BZREvent *event = OCMClassMock([BZREvent class]);
    [underlyingEventsSubject sendNext:event];
    expect(recorder).will.sendValues(@[event]);
  });

  it(@"should send error event when failed to store receipt validation status", ^{
    OCMStub([timeProvider currentTime]).andReturn([RACSignal return:[NSDate date]]);
    NSError *underlyingError = OCMClassMock([NSError class]);
    OCMStub([keychainStorage setValue:OCMOCK_ANY forKey:OCMOCK_ANY
                                error:[OCMArg setTo:underlyingError]]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    LLSignalTestRecorder *recorder =
        [validationStatusProvider.eventsSignal testRecorder];
    expect([validationStatusProvider fetchReceiptValidationStatus]).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      NSError *error = event.eventError;
      return error.lt_isLTDomain && error.code == BZRErrorCodeStoringDataToStorageFailed &&
          error.lt_underlyingError == underlyingError &&
          [event.eventType isEqual:$(BZREventTypeNonCriticalError)];
    });
  });

  it(@"should err when underlying receipt validitation status provider errs", ^{
    OCMStub([timeProvider currentTime]).andReturn([RACSignal return:[NSDate date]]);
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus]).andReturn([RACSignal error:error]);

    LLSignalTestRecorder *recorder =
        [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];

    expect(recorder).will.sendError(error);
  });

  it(@"should send error event when time provider errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal error:error]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);
    
    LLSignalTestRecorder *recorder =
        [[validationStatusProvider eventsSignal] testRecorder];

    expect([validationStatusProvider fetchReceiptValidationStatus]).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] &&
          [event.eventError isEqual:error];
    });
  });

  it(@"should not cache the receipt if time provider failed", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal error:error]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);
    OCMReject([keychainStorage setValue:OCMOCK_ANY forKey:OCMOCK_ANY]);

    expect([validationStatusProvider fetchReceiptValidationStatus]).will.complete();
  });
});

context(@"fetching receipt validation status", ^{
  beforeEach(^{
    RACSignal *receiptValidationSignal = [RACSignal defer:^RACSignal *{
      return [RACSignal return:receiptValidationStatus];
    }];
    OCMStub([underlyingProvider fetchReceiptValidationStatus]).andReturn(receiptValidationSignal);
  });

  it(@"should send receipt validation status sent by the underlying provider", ^{
    RACSignal *validateSignal =
        [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];

    expect(validateSignal).will.complete();
    expect(validateSignal).will.sendValues(@[receiptValidationStatus]);
  });

  it(@"should save receipt validation status to storage", ^{
    NSDate *currentTime = [NSDate date];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal return:currentTime]);
    OCMExpect([keychainStorage setValue:OCMOCK_ANY forKey:OCMOCK_ANY
                                  error:[OCMArg anyObjectRef]]).andReturn(YES);

    RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus];

    expect(validateSignal).will.complete();
    OCMVerifyAll((id)keychainStorage);
  });

  it(@"should update last validation date after fetching receipt validation status", ^{
    OCMStub([keychainStorage setValue:receiptValidationStatus forKey:OCMOCK_ANY
                                error:[OCMArg anyObjectRef]]).andReturn(YES);
    NSDate *currentTime = [NSDate date];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal return:currentTime]);
    LLSignalTestRecorder *validateSignal =
        [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];

    expect(validateSignal).will.complete();
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(currentTime);
  });
});

context(@"getting cached receipt validation status", ^{
  it(@"should return nil if no validation completed and failed to read from storage", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                    error:[OCMArg setTo:error]]);

    LLSignalTestRecorder *recorder =
        [validationStatusProvider.eventsSignal testRecorder];

    expect(validationStatusProvider.receiptValidationStatus).to.beNil();
    expect(validationStatusProvider.lastReceiptValidationDate).to.beNil();

    BZREvent *event =
        [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error];
    expect(recorder).will.sendValues(@[event, event]);
  });

  it(@"should not read from storage if validation status is not nil", ^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);
    OCMStub([timeProvider currentTime]).andReturn([RACSignal return:[NSDate date]]);

    RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus];

    expect(validateSignal).will.complete();
    OCMReject([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
                                      error:[OCMArg anyObjectRef]]);
    expect(validationStatusProvider.receiptValidationStatus).notTo.beNil();
    expect(validationStatusProvider.lastReceiptValidationDate).notTo.beNil();
  });

  it(@"should load validation status from storage if receipt validation status is nil", ^{
    OCMExpect([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                      error:[OCMArg anyObjectRef]]).andReturn(@{});
    OCMReject([keychainStorage valueOfClass:[BZRReceiptValidationStatus class] forKey:OCMOCK_ANY
                                      error:[OCMArg anyObjectRef]]);

    BZRReceiptValidationStatus __unused *validationStatus =
        validationStatusProvider.receiptValidationStatus;
    OCMVerifyAll((id)keychainStorage);
  });

  it(@"should load old format cached values if new format values are not available", ^{
    BZRReceiptValidationStatus *validationStatus =
        OCMClassMock([BZRReceiptValidationStatus class]);
    NSDate *validationDate = [NSDate date];
    OCMStub([keychainStorage valueOfClass:[BZRReceiptValidationStatus class] forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]).andReturn(validationStatus);
    OCMStub([keychainStorage valueOfClass:[NSDate class] forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]).andReturn(validationDate);

    expect(validationStatusProvider.receiptValidationStatus).to.equal(validationStatus);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(validationDate);
  });
});

context(@"expiring subscription", ^{
  it(@"should change subscription to expired", ^{
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);
    LLSignalTestRecorder *validationSignal =
        [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];

    expect(validationSignal).will.complete();
    expect(validationStatusProvider.receiptValidationStatus).to.equal(receiptValidationStatus);

    [validationStatusProvider expireSubscription];
    expect(validationStatusProvider.receiptValidationStatus.receipt.subscription.isExpired)
        .to.equal(YES);
  });
});

SpecEnd
