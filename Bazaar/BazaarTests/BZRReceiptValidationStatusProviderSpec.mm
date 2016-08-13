// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationError.h"
#import "BZRReceiptValidationParameters.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidator.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRReceiptValidationStatusProvider)

__block BZRKeychainStorage *keychainStorage;
__block id<BZRReceiptValidator> receiptValidator;
__block BZRReceiptValidationParameters *receiptValidationParameters;
__block id<BZRReceiptValidationParametersProvider> receiptValidationParametersProvider;
__block BZRReceiptValidationStatus *receiptValidationStatus;
__block BZRReceiptValidationStatusProvider *validationStatusProvider;

beforeEach(^{
  keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  receiptValidator = OCMProtocolMock(@protocol(BZRReceiptValidator));
  receiptValidationParameters = OCMClassMock([BZRReceiptValidationParameters class]);
  receiptValidationParametersProvider =
      OCMProtocolMock(@protocol(BZRReceiptValidationParametersProvider));
  NSDictionary *dictionaryValue = @{
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
    @instanceKeypath(BZRReceiptValidationStatus, receipt): OCMClassMock([BZRReceiptInfo class])
  };
  receiptValidationStatus = [[BZRReceiptValidationStatus alloc] initWithDictionary:dictionaryValue
                                                                             error:nil];

  validationStatusProvider = [[BZRReceiptValidationStatusProvider alloc]
                              initWithKeychainStorage:keychainStorage
                              receiptValidator:receiptValidator
                              validationParametersProvider:receiptValidationParametersProvider];
});

context(@"loading validation status from storage", ^{
  it(@"should return nil validation status if no validation completed and failed to read from "
     "storage", ^{
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg setTo:error]]);

    LLSignalTestRecorder *recorder = [validationStatusProvider.storageErrorsSignal testRecorder];

    expect(validationStatusProvider.receiptValidationStatus).to.beNil();
    expect(recorder).will.sendValue(1, error);
  });

  it(@"should not read from storage if validation status is not nil", ^{
    RACSignal *signal = [RACSignal return:receiptValidationStatus];
    OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY]).andReturn(signal);
    OCMStub([receiptValidationParametersProvider receiptValidationParameters])
        .andReturn(receiptValidationParameters);

    RACSignal *validateSignal = [validationStatusProvider validateReceipt];

    expect(validateSignal).will.complete();
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]);
    expect(validationStatusProvider.receiptValidationStatus).notTo.beNil();
  });

  it(@"should read validation status from storage when receipt validation fails", ^{
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn(receiptValidationStatus);
    NSError *error = OCMClassMock([NSError class]);
    RACSignal *errorSignal = [RACSignal error:error];
    OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY]).andReturn(errorSignal);
    OCMStub([receiptValidationParametersProvider receiptValidationParameters])
        .andReturn(receiptValidationParameters);

    RACSignal *signal = [validationStatusProvider validateReceipt];

    expect(signal).will.sendError(error);
    expect(validationStatusProvider.receiptValidationStatus).to.equal(receiptValidationStatus);
  });
});

context(@"validating receipt", ^{
  it(@"should send error when receipt validation parameters are nil", ^{
    RACSignal *validateSignal = [validationStatusProvider validateReceipt];

    expect(validateSignal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeReceiptValidationFailed;
    });
  });

  it(@"should not update validation status if validation has failed", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRReceiptValidationStatus, isValid): @NO,
      @instanceKeypath(BZRReceiptValidationStatus, error):
          $(BZRReceiptValidationErrorServerIsNotAvailable),
      @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date]
    };
    BZRReceiptValidationStatus *invalidReceiptValidation =
        [[BZRReceiptValidationStatus alloc] initWithDictionary:dictionaryValue error:nil];
    RACSignal *signal = [RACSignal return:invalidReceiptValidation];
    OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY]).andReturn(signal);
    OCMStub([receiptValidationParametersProvider receiptValidationParameters])
        .andReturn(receiptValidationParameters);
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn(receiptValidationStatus);

    RACSignal *validateSignal = [validationStatusProvider validateReceipt];

    expect(validateSignal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeReceiptValidationFailed;
    });
    expect(validationStatusProvider.receiptValidationStatus).to.equal(receiptValidationStatus);
  });

  it(@"should store validation status upon successful validation", ^{
    RACSignal *signal = [RACSignal return:receiptValidationStatus];
    OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY]).andReturn(signal);
    OCMStub([receiptValidationParametersProvider receiptValidationParameters])
        .andReturn(receiptValidationParameters);

    LLSignalTestRecorder *recorder =
        [[validationStatusProvider validateReceipt] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[receiptValidationStatus]);
    expect(validationStatusProvider.receiptValidationStatus).to.equal(receiptValidationStatus);
    OCMVerify([keychainStorage setValue:receiptValidationStatus forKey:OCMOCK_ANY
                                  error:[OCMArg anyObjectRef]]);
  });
});

context(@"error saving to storage", ^{
  it(@"should send storage error when save receipt validation status to storage has failed", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    OCMStub([keychainStorage setValue:OCMOCK_ANY forKey:OCMOCK_ANY
                                error:[OCMArg setTo:underlyingError]]);
    RACSignal *signal = [RACSignal return:receiptValidationStatus];
    OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY]).andReturn(signal);
    OCMStub([receiptValidationParametersProvider receiptValidationParameters])
        .andReturn(receiptValidationParameters);

    LLSignalTestRecorder *recorder = [validationStatusProvider.storageErrorsSignal testRecorder];
    
    expect([validationStatusProvider validateReceipt]).will.complete();
    expect(recorder).will.matchValue(1, ^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeStoringDataToStorageFailed &&
          error.lt_underlyingError == underlyingError;
    });
  });
});

SpecEnd
