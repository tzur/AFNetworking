// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRRetryReceiptValidator.h"

#import "BZREvent.h"
#import "BZRReceiptValidationParameters.h"
#import "BZRReceiptValidationStatus.h"

SpecBegin(BZRRetryReceiptValidator)

static const NSTimeInterval kInitialRetryDelay = 0.005;
static const NSUInteger kNumberOfRetries = 2;

__block id<BZRReceiptValidator> underlyingValidator;
__block RACSubject *underlyingValidatorEventsSubject;
__block BZRRetryReceiptValidator *validator;
__block BZRReceiptValidationStatus *receiptValidationStatus;
__block BZRReceiptValidationParameters *validationParameters;

beforeEach(^{
  underlyingValidator = OCMProtocolMock(@protocol(BZRReceiptValidator));
  underlyingValidatorEventsSubject = [RACSubject subject];
  OCMStub([underlyingValidator eventsSignal]).andReturn(underlyingValidatorEventsSubject);

  validator =
      [[BZRRetryReceiptValidator alloc] initWithUnderlyingValidator:underlyingValidator
                                                  initialRetryDelay:kInitialRetryDelay
                                                    numberOfRetries:kNumberOfRetries];

  receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
  validationParameters = OCMClassMock([BZRReceiptValidationParameters class]);
});

context(@"underlying validator succeeded", ^{
  it(@"should return value returned by validator immediately", ^{
    OCMStub([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal return:receiptValidationStatus]);

    RACSignal *receiptSignal = [validator validateReceiptWithParameters:validationParameters];

    expect(receiptSignal).to.sendValues(@[receiptValidationStatus]);
  });
});

context(@"underlying validator failed", ^{
  it(@"should retry once and deliver the value delivered on the second validation", ^{
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal return:receiptValidationStatus]);

    RACSignal *validationSignal = [validator validateReceiptWithParameters:validationParameters];

    expect(validationSignal).will.sendValues(@[receiptValidationStatus]);
    OCMVerifyAll((id)underlyingValidator);
  });

  it(@"should retry twice and deliver the value delivered on the third validation", ^{
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1]]);
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:2]]);
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal return:receiptValidationStatus]);

    RACSignal *validationSignal = [validator validateReceiptWithParameters:validationParameters];

    expect(validationSignal).will.sendValues(@[receiptValidationStatus]);
    OCMVerifyAll((id)underlyingValidator);
  });

  it(@"should not retry more than twice and err if the third validation failed", ^{
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1]]);
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:2]]);
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:3]]);
    OCMReject([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY]);

    RACSignal *validationSignal = [validator validateReceiptWithParameters:validationParameters];

    expect(validationSignal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == 3;
    });
    OCMVerifyAll((id)underlyingValidator);
  });
});

context(@"events signal", ^{
  it(@"should propagate non-critical validation error events", ^{
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1]]);
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:2]]);
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal return:receiptValidationStatus]);

    LLSignalTestRecorder *eventsRecoder = [validator.eventsSignal testRecorder];
    RACSignal *validationSignal = [validator validateReceiptWithParameters:validationParameters];

    expect(validationSignal).will.complete();
    expect(eventsRecoder).to.sendValuesWithCount(2);
    expect(eventsRecoder).to.matchValue(0, ^BOOL(BZREvent *event) {
      return event.eventType.value == BZREventTypeNonCriticalError && event.eventError.code == 1;
    });
    expect(eventsRecoder).to.matchValue(1, ^BOOL(BZREvent *event) {
      return event.eventType.value == BZREventTypeNonCriticalError && event.eventError.code == 2;
    });
  });

  it(@"should propagate underlying validator events", ^{
    LLSignalTestRecorder *eventsRecoder = [validator.eventsSignal testRecorder];

    BZREvent *event = OCMClassMock([BZREvent class]);
    [underlyingValidatorEventsSubject sendNext:event];
    [underlyingValidatorEventsSubject sendNext:event];

    expect(eventsRecoder).to.sendValues(@[event, event]);
  });
});

SpecEnd
