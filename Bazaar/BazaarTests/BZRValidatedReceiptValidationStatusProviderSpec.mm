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
#import "BZRUserIDProvider.h"
#import "BZRValidatricksClient.h"
#import "NSError+Bazaar.h"
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

__block id<BZRValidatricksClient> validatricksClient;
__block BZRReceiptValidationParameters *receiptValidationParameters;
__block id<BZRReceiptValidationParametersProvider> receiptValidationParametersProvider;
__block BZRReceiptDataCache *receiptDataCache;
__block NSString *currentApplicationBundleID;
__block id<BZRUserIDProvider> userIDProvider;
__block BZRValidatedReceiptValidationStatusProvider *validationStatusProvider;

beforeEach(^{
  validatricksClient = OCMProtocolMock(@protocol(BZRValidatricksClient));
  receiptValidationParameters = OCMClassMock([BZRReceiptValidationParameters class]);
  receiptValidationParametersProvider =
      OCMProtocolMock(@protocol(BZRReceiptValidationParametersProvider));
  receiptDataCache = OCMClassMock([BZRReceiptDataCache class]);
  currentApplicationBundleID = @"foo";
  userIDProvider = OCMProtocolMock(@protocol(BZRUserIDProvider));
  validationStatusProvider =
      [[BZRValidatedReceiptValidationStatusProvider alloc]
       initWithValidatricksClient:validatricksClient
       validationParametersProvider:receiptValidationParametersProvider
       receiptDataCache:receiptDataCache userIDProvider:userIDProvider];
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRValidatedReceiptValidationStatusProvider __weak *weakValidationStatusProvider;
    RACSignal *eventsSignal;
    RACSignal *fetchSignal;

    OCMStub([validatricksClient validateReceipt:OCMOCK_ANY])
        .andReturn([RACSignal return:BZRValidReceiptValidationStatus()]);
    OCMStub([validatricksClient eventsSignal]).andReturn([RACSignal empty]);
    OCMStub([receiptValidationParametersProvider
        receiptValidationParametersForApplication:OCMOCK_ANY userID:OCMOCK_ANY])
        .andReturn(receiptValidationParameters);

    @autoreleasepool {
      BZRValidatedReceiptValidationStatusProvider *validationStatusProvider =
          [[BZRValidatedReceiptValidationStatusProvider alloc]
           initWithValidatricksClient:validatricksClient
           validationParametersProvider:receiptValidationParametersProvider
           receiptDataCache:receiptDataCache userIDProvider:userIDProvider];
      weakValidationStatusProvider = validationStatusProvider;
      eventsSignal = validationStatusProvider.eventsSignal;
      fetchSignal = [validationStatusProvider fetchReceiptValidationStatus:@"foo"];
    }

    expect(fetchSignal).will.finish();
    expect(weakValidationStatusProvider).to.beNil();
  });
});

context(@"fetching receipt validation status", ^{
  it(@"should send error when receipt validation parameters are nil", ^{
    RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus:@"foo"];

    expect(validateSignal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeReceiptValidationFailed &&
          [error.userInfo[kBZRApplicationBundleIDKey] isEqualToString:@"foo"];
    });
  });

  it(@"should pass application bundle ID and user ID to parameters provider", ^{
    OCMStub([userIDProvider userID]).andReturn(@"bar");

    expect([validationStatusProvider fetchReceiptValidationStatus:@"foo"]).will.finish();

    OCMVerify([receiptValidationParametersProvider
               receiptValidationParametersForApplication:@"foo" userID:@"bar"]);
  });

  context(@"receipt validation parameters are valid", ^{
    beforeEach(^{
      OCMStub([receiptValidationParametersProvider
          receiptValidationParametersForApplication:OCMOCK_ANY userID:OCMOCK_ANY])
          .andReturn(receiptValidationParameters);
    });

    it(@"should send error when receipt validator errs", ^{
      NSError *underlyingError = [NSError lt_errorWithCode:1337];
      OCMStub([validatricksClient validateReceipt:OCMOCK_ANY])
          .andReturn([RACSignal error:underlyingError]);

      RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus:@"foo"];

      expect(validateSignal).will.matchError(^BOOL(NSError *error) {
        return error.code == BZRErrorCodeReceiptValidationFailed &&
            error.lt_underlyingError == underlyingError &&
            [error.userInfo[kBZRApplicationBundleIDKey] isEqualToString:@"foo"];
      });
    });

    it(@"should send error when validation has failed", ^{
      auto receiptValidationStatus = BZRInvalidReceiptValidationStatusWithError(
          $(BZRReceiptValidationErrorMalformedReceiptData));
      OCMStub([validatricksClient validateReceipt:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus:@"foo"];

      expect(validateSignal).will.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeReceiptValidationFailed &&
            [error.userInfo[kBZRApplicationBundleIDKey] isEqualToString:@"foo"];
      });
    });

    it(@"should store receipt data when validation was successful", ^{
      auto receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
      OCMStub([receiptValidationParameters receiptData]).andReturn(receiptData);
      auto receiptValidationStatus = BZRValidReceiptValidationStatus();
      OCMStub([validatricksClient validateReceipt:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      expect([validationStatusProvider fetchReceiptValidationStatus:@"foo"]).will.finish();

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
      OCMStub([validatricksClient validateReceipt:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      expect([validationStatusProvider fetchReceiptValidationStatus:@"foo"]).will.finish();

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
      OCMStub([validatricksClient validateReceipt:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      OCMReject([receiptDataCache storeReceiptData:OCMOCK_ANY applicationBundleID:OCMOCK_ANY
                                             error:[OCMArg anyObjectRef]]);

      expect([validationStatusProvider fetchReceiptValidationStatus:@"foo"]).will.finish();
    });

    it(@"should not store receipt data when receipt data is nil", ^{
      auto receiptValidationStatus = BZRValidReceiptValidationStatus();
      OCMStub([validatricksClient validateReceipt:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      OCMReject([receiptDataCache storeReceiptData:OCMOCK_ANY applicationBundleID:OCMOCK_ANY
                                             error:[OCMArg anyObjectRef]]);

      expect([validationStatusProvider fetchReceiptValidationStatus:@"foo"]).will.finish();
    });

    it(@"should return receipt validation status upon successful validation", ^{
      BZRReceiptValidationStatus *receiptValidationStatus =
          BZRValidReceiptValidationStatus();
      OCMStub([validatricksClient validateReceipt:OCMOCK_ANY])
          .andReturn([RACSignal return:receiptValidationStatus]);

      LLSignalTestRecorder *recorder =
          [[validationStatusProvider fetchReceiptValidationStatus:@"foo"] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[receiptValidationStatus]);
    });
  });
});

context(@"events signal", ^{
  it(@"should send events sent by the underlying receipt validator", ^{
    RACSubject *validatricksClientEventSubject = [RACSubject subject];
    OCMStub([validatricksClient eventsSignal]).andReturn(validatricksClientEventSubject);

    LLSignalTestRecorder *recorder = [validationStatusProvider.eventsSignal testRecorder];

    BZREvent *event = [[BZREvent alloc] initWithType:$(BZREventTypeReceiptValidationStatusReceived)
                                           eventInfo:@{}];
    [validatricksClientEventSubject sendNext:event];

    expect(recorder).will.sendValues(@[event]);
  });
});

SpecEnd
