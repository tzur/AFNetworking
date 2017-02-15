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

static NSString * const kValidationStatusKey = @"validationStatus";
static NSString * const kValidationDateKey = @"validationDate";

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

context(@"initialization", ^{
  it(@"should load receipt validation status from cache on initialization", ^{
    BZRReceiptValidationStatus *validationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    NSDictionary *receiptDictionary = @{
      kValidationStatusKey: validationStatus,
      kValidationDateKey: [NSDate date]
    };

    OCMExpect([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                      error:[OCMArg anyObjectRef]]).andReturn(receiptDictionary);
    validationStatusProvider = [[BZRCachedReceiptValidationStatusProvider alloc]
                                initWithKeychainStorage:keychainStorage
                                timeProvider:timeProvider
                                underlyingProvider:underlyingProvider];

    expect(validationStatusProvider.receiptValidationStatus).to.equal(validationStatus);
    OCMVerifyAll((id)keychainStorage);
  });
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRCachedReceiptValidationStatusProvider __weak *weakValidationStatusProvider;
    RACSignal *fetchSignal;
    RACSignal *eventsSignal;
    OCMStub([underlyingProvider eventsSignal]).andReturn([RACSignal empty]);
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
    LLSignalTestRecorder *recorder = [[validationStatusProvider eventsSignal] testRecorder];
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal error:error]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

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

  it(@"should send error event when failed to read from storage", ^{
    LLSignalTestRecorder *recorder = [validationStatusProvider.eventsSignal testRecorder];
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                    error:[OCMArg setTo:error]]);

    NSError *returnedError;
    [validationStatusProvider refreshReceiptValidationStatus:&returnedError];

    expect(returnedError).to.equal(error);
    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] && event.eventError == error;
    });
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

context(@"loading receipt validation status from cache", ^{
  it(@"should return nil if no validation completed and failed to read from storage", ^{
    OCMStub([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                    error:[OCMArg setTo:[NSError lt_errorWithCode:1337]]]);

    BZRReceiptValidationStatus *returnedValidationStatus =
        [validationStatusProvider refreshReceiptValidationStatus:nil];

    expect(validationStatusProvider.receiptValidationStatus).to.beNil();
    expect(validationStatusProvider.lastReceiptValidationDate).to.beNil();
    expect(validationStatusProvider.receiptValidationStatus).to.equal(returnedValidationStatus);
  });

  it(@"should load validation status from storage and date in new format", ^{
    BZRReceiptValidationStatus *validationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    NSDate *validationDate = [NSDate date];
    NSDictionary *receiptDictionary = @{
      kValidationStatusKey: validationStatus,
      kValidationDateKey: validationDate
    };

    OCMStub([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]).andReturn(receiptDictionary);

    BZRReceiptValidationStatus *returnedValidationStatus =
        [validationStatusProvider refreshReceiptValidationStatus:nil];

    expect(validationStatusProvider.receiptValidationStatus).to.equal(validationStatus);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(validationDate);
    expect(validationStatusProvider.receiptValidationStatus).to.equal(returnedValidationStatus);
  });

  it(@"should load old format cached values if new format values are not available", ^{
    BZRReceiptValidationStatus *validationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    NSDate *validationDate = [NSDate date];
    OCMStub([keychainStorage valueOfClass:[BZRReceiptValidationStatus class] forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]).andReturn(validationStatus);
    OCMStub([keychainStorage valueOfClass:[NSDate class] forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]).andReturn(validationDate);

    BZRReceiptValidationStatus *returnedValidationStatus =
        [validationStatusProvider refreshReceiptValidationStatus:nil];

    expect(validationStatusProvider.receiptValidationStatus).to.equal(validationStatus);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(validationDate);
    expect(validationStatusProvider.receiptValidationStatus).to.equal(returnedValidationStatus);
  });

  it(@"should not modify receipt validation status if failed to read from storage", ^{
    BZRReceiptValidationStatus *validationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    NSDate *validationDate = [NSDate date];
    NSDictionary *receiptDictionary = @{
      kValidationStatusKey: validationStatus,
      kValidationDateKey: validationDate
    };

    OCMExpect([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                      error:[OCMArg anyObjectRef]]).andReturn(receiptDictionary);
    [validationStatusProvider refreshReceiptValidationStatus:nil];

    OCMStub([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                    error:[OCMArg setTo:[NSError lt_errorWithCode:1337]]]);
    
    [validationStatusProvider refreshReceiptValidationStatus:nil];

    expect(validationStatusProvider.receiptValidationStatus).to.equal(validationStatus);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(validationDate);
  });

  it(@"should return nil when receipt validation status was cleared", ^{
    NSDictionary *receiptDictionary = @{
      kValidationStatusKey: OCMClassMock([BZRReceiptValidationStatus class]),
      kValidationDateKey: [NSDate date]
    };

    OCMExpect([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                      error:[OCMArg anyObjectRef]]).andReturn(receiptDictionary);
    [validationStatusProvider refreshReceiptValidationStatus:nil];

    OCMStub([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]);

    [validationStatusProvider refreshReceiptValidationStatus:nil];

    expect(validationStatusProvider.receiptValidationStatus).to.beNil();
    expect(validationStatusProvider.lastReceiptValidationDate).to.beNil();
  });
});

context(@"KVO compliance", ^{
  it(@"should notify the observer when receipt validation status changes", ^{
    LLSignalTestRecorder *recorder =
        [RACObserve(validationStatusProvider, receiptValidationStatus) testRecorder];

    BZRReceiptValidationStatus *validationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    NSDictionary *receiptDictionary = @{
      kValidationStatusKey: validationStatus,
      kValidationDateKey: [NSDate date]
    };
    
    OCMStub([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]).andReturn(receiptDictionary);

    [validationStatusProvider refreshReceiptValidationStatus:nil];

    expect(recorder).to.sendValues(@[[NSNull null], validationStatus]);
  });

  it(@"should notify the observer when last receipt validation date changes", ^{
    LLSignalTestRecorder *recorder =
        [RACObserve(validationStatusProvider, lastReceiptValidationDate) testRecorder];

    NSDate *validationDate = [NSDate date];
    NSDictionary *receiptDictionary = @{
      kValidationStatusKey: OCMClassMock([BZRReceiptValidationStatus class]),
      kValidationDateKey: validationDate
    };

    OCMStub([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]).andReturn(receiptDictionary);

    [validationStatusProvider refreshReceiptValidationStatus:nil];
    
    expect(recorder).to.sendValues(@[[NSNull null], validationDate]);
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
