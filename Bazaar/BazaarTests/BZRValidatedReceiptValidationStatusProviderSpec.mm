// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRValidatedReceiptValidationStatusProvider.h"

#import "BZREvent.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationError.h"
#import "BZRReceiptValidationParameters.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidator.h"
#import "NSErrorCodes+Bazaar.h"

BZRReceiptValidationStatus *BZRReceiptValidationStatusWithValidity(BOOL isValid) {
  NSDictionary *dictionaryValue = @{
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @(isValid),
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
    @instanceKeypath(BZRReceiptValidationStatus, receipt): OCMClassMock([BZRReceiptInfo class])
  };
  BZRReceiptValidationStatus *receiptValidationStatus =
      [BZRReceiptValidationStatus modelWithDictionary:dictionaryValue error:nil];
  return receiptValidationStatus;
}

SpecBegin(BZRValidatedReceiptValidationStatusProvider)

__block id<BZRReceiptValidator> receiptValidator;
__block BZRReceiptValidationParameters *receiptValidationParameters;
__block id<BZRReceiptValidationParametersProvider> receiptValidationParametersProvider;
__block BZRValidatedReceiptValidationStatusProvider *validationStatusProvider;

beforeEach(^{
  receiptValidator = OCMProtocolMock(@protocol(BZRReceiptValidator));
  receiptValidationParameters = OCMClassMock([BZRReceiptValidationParameters class]);
  receiptValidationParametersProvider =
      OCMProtocolMock(@protocol(BZRReceiptValidationParametersProvider));
  validationStatusProvider =
      [[BZRValidatedReceiptValidationStatusProvider alloc]
       initWithReceiptValidator:receiptValidator
       validationParametersProvider:receiptValidationParametersProvider];
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRValidatedReceiptValidationStatusProvider __weak *weakValidationStatusProvider;
    RACSignal *eventsSignal;
    RACSignal *fetchSignal;

    OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal return:BZRReceiptValidationStatusWithValidity(YES)]);
    OCMStub([receiptValidationParametersProvider receiptValidationParameters])
        .andReturn(receiptValidationParameters);

    @autoreleasepool {
      BZRValidatedReceiptValidationStatusProvider *validationStatusProvider =
          [[BZRValidatedReceiptValidationStatusProvider alloc]
           initWithReceiptValidator:receiptValidator
           validationParametersProvider:receiptValidationParametersProvider];
      weakValidationStatusProvider = validationStatusProvider;
      eventsSignal = validationStatusProvider.eventsSignal;
      fetchSignal = [validationStatusProvider fetchReceiptValidationStatus];
    }

    expect(fetchSignal).will.finish();
    expect(weakValidationStatusProvider).to.beNil();
  });
});

context(@"fetching receipt validation status", ^{
  it(@"should send error when receipt validation parameters are nil", ^{
    RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus];

    expect(validateSignal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeReceiptValidationFailed;
    });
  });

  context(@"receipt validation parameters are valid", ^{
    beforeEach(^{
      OCMStub([receiptValidationParametersProvider receiptValidationParameters])
          .andReturn(receiptValidationParameters);
    });

    it(@"should send error when receipt validator errs", ^{
      NSError *error = OCMClassMock([NSError class]);
      OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
          .andReturn([RACSignal error:error]);

      expect([validationStatusProvider fetchReceiptValidationStatus]).will.sendError(error);
    });

    it(@"should send error when validation has failed", ^{
      OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
          .andReturn([RACSignal return:BZRReceiptValidationStatusWithValidity(NO)]);

      RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus];

      expect(validateSignal).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeReceiptValidationFailed;
      });
    });

    it(@"should return receipt validation status upon successful validation", ^{
      BZRReceiptValidationStatus *receiptValidationStatus =
          BZRReceiptValidationStatusWithValidity(YES);
      OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      LLSignalTestRecorder *recorder =
          [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[receiptValidationStatus]);
    });
  });
});

context(@"events signal", ^{
  it(@"should send event sent by receipt validator", ^{
    RACSubject *receiptValidatorEventsSubject = [RACSubject subject];
    OCMStub([receiptValidator eventsSignal]).andReturn(receiptValidatorEventsSubject);

    LLSignalTestRecorder *recorder = [validationStatusProvider.eventsSignal testRecorder];

    BZREvent *event = [[BZREvent alloc] initWithType:$(BZREventTypeReceiptValidationStatusReceived)
                                           eventInfo:@{}];
    [receiptValidatorEventsSubject sendNext:event];

    expect(recorder).will.sendValues(@[event]);
  });
});

SpecEnd
