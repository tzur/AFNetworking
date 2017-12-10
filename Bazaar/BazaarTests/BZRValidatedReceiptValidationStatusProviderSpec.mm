// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRValidatedReceiptValidationStatusProvider.h"

#import "BZREvent.h"
#import "BZRReceiptDataCache.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationError.h"
#import "BZRReceiptValidationParameters.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidator.h"
#import "NSErrorCodes+Bazaar.h"

BZRReceiptValidationStatus *BZRInvalidReceiptValidationStatusWithError(
    BZRReceiptValidationError *error) {
  NSDictionary *dictionaryValue = @{
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @NO,
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
    @instanceKeypath(BZRReceiptValidationStatus, error): error
  };
  BZRReceiptValidationStatus *receiptValidationStatus =
      [BZRReceiptValidationStatus modelWithDictionary:dictionaryValue error:nil];
  return receiptValidationStatus;
}

BZRReceiptValidationStatus *BZRValidReceiptValidationStatus() {
  NSDictionary *dictionaryValue = @{
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
    @instanceKeypath(BZRReceiptValidationStatus, receipt): OCMClassMock([BZRReceiptInfo class]),
  };
  BZRReceiptValidationStatus *receiptValidationStatus =
      [BZRReceiptValidationStatus modelWithDictionary:dictionaryValue error:nil];
  return receiptValidationStatus;
}

SpecBegin(BZRValidatedReceiptValidationStatusProvider)

__block id<BZRReceiptValidator> receiptValidator;
__block BZRReceiptValidationParameters *receiptValidationParameters;
__block id<BZRReceiptValidationParametersProvider> receiptValidationParametersProvider;
__block BZRReceiptDataCache *receiptDataCache;
__block NSString *currentApplicationBundleID;
__block BZRValidatedReceiptValidationStatusProvider *validationStatusProvider;

beforeEach(^{
  receiptValidator = OCMProtocolMock(@protocol(BZRReceiptValidator));
  receiptValidationParameters = OCMClassMock([BZRReceiptValidationParameters class]);
  receiptValidationParametersProvider =
      OCMProtocolMock(@protocol(BZRReceiptValidationParametersProvider));
  receiptDataCache = OCMClassMock([BZRReceiptDataCache class]);
  currentApplicationBundleID = @"foo";
  validationStatusProvider =
      [[BZRValidatedReceiptValidationStatusProvider alloc]
       initWithReceiptValidator:receiptValidator
       validationParametersProvider:receiptValidationParametersProvider
       receiptDataCache:receiptDataCache currentApplicationBundleID:currentApplicationBundleID];
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRValidatedReceiptValidationStatusProvider __weak *weakValidationStatusProvider;
    RACSignal *eventsSignal;
    RACSignal *fetchSignal;

    OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
        .andReturn([RACSignal return:BZRValidReceiptValidationStatus()]);
    OCMStub([receiptValidationParametersProvider receiptValidationParameters])
        .andReturn(receiptValidationParameters);

    @autoreleasepool {
      BZRValidatedReceiptValidationStatusProvider *validationStatusProvider =
          [[BZRValidatedReceiptValidationStatusProvider alloc]
           initWithReceiptValidator:receiptValidator
           validationParametersProvider:receiptValidationParametersProvider
           receiptDataCache:receiptDataCache currentApplicationBundleID:currentApplicationBundleID];
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
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
          .andReturn([RACSignal error:error]);

      NSError *receiptValidationError =
          [NSError lt_errorWithCode:BZRErrorCodeReceiptValidationFailed underlyingError:error];

      expect([validationStatusProvider fetchReceiptValidationStatus]).will
          .sendError(receiptValidationError);
    });

    it(@"should send error when validation has failed", ^{
      auto receiptValidationStatus = BZRInvalidReceiptValidationStatusWithError(
          $(BZRReceiptValidationErrorMalformedReceiptData));
      OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus];

      expect(validateSignal).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeReceiptValidationFailed;
      });
    });

    it(@"should store receipt data when validation was successful", ^{
      auto receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
      OCMStub([receiptValidationParameters receiptData]).andReturn(receiptData);
      auto receiptValidationStatus = BZRValidReceiptValidationStatus();
      OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      expect([validationStatusProvider fetchReceiptValidationStatus]).will.finish();

      OCMVerify([receiptDataCache storeReceiptData:receiptData
                               applicationBundleID:currentApplicationBundleID
                                             error:[OCMArg anyObjectRef]]);
    });

    it(@"should store receipt data when validation failed and the error is unrelated to the "
       "receipt", ^{
      auto receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
      OCMStub([receiptValidationParameters receiptData]).andReturn(receiptData);
      auto receiptValidationStatus = BZRInvalidReceiptValidationStatusWithError(
          $(BZRReceiptValidationErrorUnknown));
      OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      expect([validationStatusProvider fetchReceiptValidationStatus]).will.finish();

      OCMVerify([receiptDataCache storeReceiptData:receiptData
                               applicationBundleID:currentApplicationBundleID
                                             error:[OCMArg anyObjectRef]]);
    });

    it(@"should not store receipt data when validation failed and the error is related to the "
       "receipt", ^{
      auto receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
      OCMStub([receiptValidationParameters receiptData]).andReturn(receiptData);
      auto receiptValidationStatus = BZRInvalidReceiptValidationStatusWithError(
          $(BZRReceiptValidationErrorMalformedReceiptData));
      OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      OCMReject([receiptDataCache storeReceiptData:OCMOCK_ANY applicationBundleID:OCMOCK_ANY
                                             error:[OCMArg anyObjectRef]]);

      expect([validationStatusProvider fetchReceiptValidationStatus]).will.finish();
    });

    it(@"should not store receipt data when receipt data is nil", ^{
      auto receiptValidationStatus = BZRValidReceiptValidationStatus();
      OCMStub([receiptValidator validateReceiptWithParameters:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      OCMReject([receiptDataCache storeReceiptData:OCMOCK_ANY applicationBundleID:OCMOCK_ANY
                                             error:[OCMArg anyObjectRef]]);

      expect([validationStatusProvider fetchReceiptValidationStatus]).will.finish();
    });

    it(@"should return receipt validation status upon successful validation", ^{
      BZRReceiptValidationStatus *receiptValidationStatus =
          BZRValidReceiptValidationStatus();
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
  it(@"should send events sent by the underlying receipt validator", ^{
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
