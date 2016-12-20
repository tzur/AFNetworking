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
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal return:receiptValidationStatus]);

    RACSignal *receiptSignal = [validator validateReceiptWithParameters:
                                OCMClassMock([BZRReceiptValidationParameters class])];

    __block BZRReceiptValidationStatus *sentReceipt;
    [receiptSignal subscribeNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
      sentReceipt = receiptValidationStatus;
    }];

    expect(sentReceipt).will.equal(receiptValidationStatus);
    OCMVerifyAll((id)underlyingValidator);
  });

  it(@"should return value returned the third time after exponential backoff delay", ^{
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
    OCMExpect([underlyingValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal return:receiptValidationStatus]);

    RACSignal *receiptSignal = [validator validateReceiptWithParameters:
                                OCMClassMock([BZRReceiptValidationParameters class])];

    __block BZRReceiptValidationStatus *sentReceipt;
    [receiptSignal subscribeNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
      sentReceipt = receiptValidationStatus;
    }];

    expect(sentReceipt).will.equal(receiptValidationStatus);
    OCMVerifyAll((id)underlyingValidator);
  });
});

SpecEnd
