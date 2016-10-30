// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRRetryReceiptValidator.h"

#import "BZRReceiptValidationParameters.h"
#import "BZRReceiptValidationStatus.h"

SpecBegin(BZRRetryReceiptValidator)

__block id<BZRReceiptValidator> underlyingValidator;
__block NSTimeInterval initialRetryDelay;
__block BZRRetryReceiptValidator *validator;
__block BZRReceiptValidationStatus *receiptValidationStatus;

beforeEach(^{
  underlyingValidator = OCMProtocolMock(@protocol(BZRReceiptValidator));
  initialRetryDelay = 0.005;
  validator =
      [[BZRRetryReceiptValidator alloc] initWithUnderlyingValidator:underlyingValidator
                                                  initialRetryDelay:initialRetryDelay
                                                    numberOfRetries:3];
  receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
});

context(@"undelying validator succeeded", ^{
  it(@"should return value returned by validator immediately", ^{
    OCMStub([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal return:receiptValidationStatus]);

    RACSignal *receiptSignal = [validator validateReceiptWithParameters:
                                OCMClassMock([BZRReceiptValidationParameters class])];

    expect(receiptSignal).to.sendValues(@[receiptValidationStatus]);
  });
});

context(@"underlying validator failed", ^{
  it(@"should return the value returned the second time after delay", ^{
    __block NSUInteger timesCalled = 0;
    RACSignal *varyingSignal = [RACSignal defer:^RACSignal *{
      NSArray *signals = @[[RACSignal error:[NSError lt_errorWithCode:1337]],
                           [RACSignal return:receiptValidationStatus]];
      return signals[timesCalled++];
    }];
    OCMStub([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn(varyingSignal);

    RACSignal *receiptSignal = [validator validateReceiptWithParameters:
                                OCMClassMock([BZRReceiptValidationParameters class])];

    __block BZRReceiptValidationStatus *sentReceipt;
    [receiptSignal subscribeNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
      sentReceipt = receiptValidationStatus;
    }];
    expect(timesCalled).will.equal(2);
    expect(sentReceipt).to.equal(receiptValidationStatus);
  });

  it(@"should return value returned the third time after exponential backoff delay", ^{
    __block NSUInteger timesCalled = 0;
    RACSignal *varyingSignal = [RACSignal defer:^RACSignal *{
      NSArray *signals = @[[RACSignal error:OCMClassMock([NSError class])],
                           [RACSignal error:OCMClassMock([NSError class])],
                           [RACSignal return:receiptValidationStatus]];
      return signals[timesCalled++];
    }];
    OCMStub([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn(varyingSignal);

    RACSignal *receiptSignal = [validator validateReceiptWithParameters:
                                OCMClassMock([BZRReceiptValidationParameters class])];

    __block BZRReceiptValidationStatus *sentReceipt;
    [receiptSignal subscribeNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
      sentReceipt = receiptValidationStatus;
    }];
    expect(timesCalled).will.equal(3);
    expect(sentReceipt).to.equal(receiptValidationStatus);
  });
});

SpecEnd
