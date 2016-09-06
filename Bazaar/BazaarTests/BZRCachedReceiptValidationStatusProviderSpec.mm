// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptValidationStatus.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRCachedReceiptValidationStatusProvider)

__block BZRKeychainStorage *keychainStorage;
__block BZRReceiptValidationStatus *receiptValidationStatus;
__block id<BZRReceiptValidationStatusProvider> underlyingProvider;
__block RACSubject *underlyingNonCriticalErrorsSubject;
__block BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

beforeEach(^{
  keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
  underlyingProvider = OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
  underlyingNonCriticalErrorsSubject = [RACSubject subject];
  OCMStub([underlyingProvider nonCriticalErrorsSignal])
      .andReturn(underlyingNonCriticalErrorsSubject);
  validationStatusProvider =
      [[BZRCachedReceiptValidationStatusProvider alloc] initWithKeychainStorage:keychainStorage
                                                             underlyingProvider:underlyingProvider];
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRCachedReceiptValidationStatusProvider __weak *weakValidationStatusProvider;
    RACSignal *fetchSignal;
    RACSignal *errorsSignal;
    OCMStub([underlyingProvider nonCriticalErrorsSignal])
        .andReturn([RACSignal empty]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    @autoreleasepool {
      BZRCachedReceiptValidationStatusProvider *validationStatusProvider =
          [[BZRCachedReceiptValidationStatusProvider alloc] initWithKeychainStorage:keychainStorage
           underlyingProvider:underlyingProvider];
      weakValidationStatusProvider = validationStatusProvider;
      fetchSignal = [validationStatusProvider fetchReceiptValidationStatus];
      errorsSignal = [validationStatusProvider nonCriticalErrorsSignal];
    }

    expect(errorsSignal).will.complete();
    expect(fetchSignal).will.complete();
    expect(weakValidationStatusProvider).to.beNil();
  });
});

context(@"handling errors", ^{
  it(@"should send non critical error sent by the underlying provider", ^{
    LLSignalTestRecorder *recorder =
        [validationStatusProvider.nonCriticalErrorsSignal testRecorder];
    NSError *error = OCMClassMock([NSError class]);
    [underlyingNonCriticalErrorsSubject sendNext:error];
    expect(recorder).will.sendValues(@[error]);
  });

  it(@"should send non critical error when failed to save receipt validation status to storage", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    OCMStub([keychainStorage setValue:OCMOCK_ANY forKey:OCMOCK_ANY
                                error:[OCMArg setTo:underlyingError]]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    LLSignalTestRecorder *recorder =
        [validationStatusProvider.nonCriticalErrorsSignal testRecorder];
    expect([validationStatusProvider fetchReceiptValidationStatus]).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeStoringDataToStorageFailed &&
          error.lt_underlyingError == underlyingError;
    });
  });

  it(@"should err when underlying receipt validitation status provider errs", ^{
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal error:error]);

    LLSignalTestRecorder *recorder =
        [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];

    expect(recorder).will.sendError(error);
  });
});

context(@"fetching receipt validation status", ^{
  it(@"should send receipt validation status sent by the underlying provider", ^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    RACSignal *validateSignal =
        [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];

    expect(validateSignal).will.complete();
    expect(validateSignal).will.sendValues(@[receiptValidationStatus]);
  });
});

context(@"caching receipt validation status", ^{
  it(@"should return nil if no validation completed and failed to read from storage", ^{
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
                                    error:[OCMArg setTo:error]]);

    LLSignalTestRecorder *recorder =
        [validationStatusProvider.nonCriticalErrorsSignal testRecorder];

    expect(validationStatusProvider.receiptValidationStatus).to.beNil();
    expect(recorder).will.sendValues(@[error]);
  });

  it(@"should not read from storage if validation status is not nil", ^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus];

    expect(validateSignal).will.complete();
    OCMReject([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
                                      error:[OCMArg anyObjectRef]]);
    expect(validationStatusProvider.receiptValidationStatus).notTo.beNil();
  });

  it(@"should read validation status from storage when receipt validation fails", ^{
    OCMExpect([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn(receiptValidationStatus);
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal error:error]);

    RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus];

    expect(validateSignal).will.sendError(error);
    expect(validationStatusProvider.receiptValidationStatus).to.equal(receiptValidationStatus);
    OCMVerifyAll((id)keychainStorage);
  });
});

SpecEnd
