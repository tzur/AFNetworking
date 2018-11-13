// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import <LTKit/LTDateProvider.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <UICKeyChainStore/UICKeyChainStore.h>

#import "BZRIntegrationTestUtils.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRStore.h"
#import "BZRStoreConfiguration.h"
#import "BZRTestUtils.h"
#import "SKPaymentQueue+Bazaar.h"

SpecBegin(BZRReceiptValidationStatusIntegration)

__block UICKeyChainStore *keychainStore;
__block NSFileManager *fileManager;
__block SKPaymentQueue *paymentQueue;
__block id<LTDateProvider> dateProvider;
__block NSData *dataMock;
__block BZRStore *store;

beforeEach(^{
  keychainStore = OCMClassMock([UICKeyChainStore class]);
  OCMStub([(id)keychainStore keyChainStoreWithService:OCMOCK_ANY accessGroup:OCMOCK_ANY])
      .andReturn(keychainStore);
  fileManager = OCMPartialMock([NSFileManager defaultManager]);
  paymentQueue = OCMClassMock([SKPaymentQueue class]);
  OCMStub([(id)paymentQueue defaultQueue]).andReturn(paymentQueue);
  dateProvider = OCMClassMock([LTDateProvider class]);
  OCMStub([(id)dateProvider dateProvider]).andReturn(dateProvider);
  dataMock = OCMClassMock([NSData class]);
});

afterEach(^{
  [OHHTTPStubs removeAllStubs];
  keychainStore = nil;
  fileManager = nil;
  paymentQueue = nil;
  dateProvider = nil;
  dataMock = nil;
});

context(@"single app mode", ^{
  beforeEach(^{
    auto JSONFilePath = [LTPath pathWithPath:@"foo"];
    BZRStubFileManagerToReturnJSONWithASingleProduct(fileManager, JSONFilePath.path, @"foo");
    BZRStubDataMockReceiptData(dataMock, @"foofile");

    BZRStoreConfiguration *configuration =
        [[BZRStoreConfiguration alloc] initWithProductsListJSONFilePath:JSONFilePath
         productListDecryptionKey:nil keychainAccessGroup:nil expiredSubscriptionGracePeriod:1
         applicationUserID:nil applicationBundleID:[[NSBundle mainBundle] bundleIdentifier]
         bundledApplicationsIDs:nil multiAppSubscriptionClassifier:nil useiCloudUserID:NO
         activatePeriodicValidation:NO];

    store = [[BZRStore alloc] initWithConfiguration:configuration];
  });

  it(@"should return receipt validation status returned by the HTTP client", ^{
    auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
    BZRStubHTTPClientToReturnReceiptValidationStatus(receiptValidationStatus);
    auto expirationDateTime = receiptValidationStatus.receipt.subscription.expirationDateTime;
    OCMStub([dateProvider currentDate]).andReturn(expirationDateTime);

    expect([store validateReceipt]).will.complete();

    expect(store.receiptValidationStatus).to.equal(receiptValidationStatus);
  });

  it(@"should add grace period to a subscription that has just expired", ^{
    auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
    BZRStubHTTPClientToReturnReceiptValidationStatus(receiptValidationStatus);
    auto expirationDateTime = receiptValidationStatus.receipt.subscription.expirationDateTime;
    OCMStub([dateProvider currentDate]).andReturn(expirationDateTime);

    expect([store validateReceipt]).will.complete();

    auto expectedReceiptValidationStatus =
        [receiptValidationStatus
         modelByOverridingPropertyAtKeypath:
         @keypath(receiptValidationStatus, receipt.subscription.isExpired) withValue:@NO];
    expect(store.receiptValidationStatus).to.equal(expectedReceiptValidationStatus);
  });
});

SpecEnd
