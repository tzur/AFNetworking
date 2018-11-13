// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import <LTKit/LTDateProvider.h>
#import <LTKit/LTPath.h>
#import <LTKit/NSArray+NSSet.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <UICKeyChainStore/UICKeyChainStore.h>

#import "BZRIntegrationTestUtils.h"
#import "BZRPaymentQueueAdapter.h"
#import "BZRProduct.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRStore.h"
#import "BZRStoreConfiguration.h"
#import "BZRStoreKitRequestsFactory.h"
#import "BZRTestUtils.h"
#import "SKPaymentQueue+Bazaar.h"
#import "SKProductsRequest+RACSignalSupport.h"

/// Associates a transaction with an \c SKPayment.
@interface SKPaymentTransaction (AssociatedPayment)

/// Payment associated with the transaction.
@property (strong, nonatomic, nullable) SKPayment *bzr_associatedPayment;

@end

void BZRStubSKProudctWithDataFromBZRProduct(SKProduct *skProduct, BZRProduct *bzrProduct) {
  OCMStub(skProduct.localizedDescription).andReturn(@"");
  OCMStub(skProduct.localizedTitle).andReturn(@"");
  OCMStub(skProduct.price).andReturn(@10);
  OCMStub(skProduct.priceLocale).andReturn([NSLocale currentLocale]);
  OCMStub(skProduct.productIdentifier).andReturn(bzrProduct.identifier);
  OCMStub(skProduct.localizedDescription).andReturn(@"");
  OCMStub(skProduct.downloadable).andReturn(NO);
  OCMStub(skProduct.downloadContentLengths).andReturn(@[@0]);
  OCMStub(skProduct.downloadContentVersion).andReturn(@"1");
}

void BZRPreparePaymentQueueForPaymentAddition(SKPaymentQueue *paymentQueue,
                                              id<SKPaymentTransactionObserver> paymentQueueAdapter,
                                              NSString *transactionID) {
  OCMStub([paymentQueue addPayment:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained SKPayment *payment;
    [invocation getArgument:&payment atIndex:2];
    auto purchasingTransaction = BZRMockedSKPaymentTransaction(@"subscription.foo.productId",
        transactionID, SKPaymentTransactionStatePurchasing, [NSDate date], payment);

    auto purchasedTransaction = BZRMockedSKPaymentTransaction(@"subscription.foo.productId",
        transactionID, SKPaymentTransactionStatePurchased, [NSDate date], payment);
    OCMStub([purchasedTransaction bzr_associatedPayment]).andReturn(payment);

    [paymentQueueAdapter paymentQueue:paymentQueue updatedTransactions:@[purchasingTransaction]];
    [paymentQueueAdapter paymentQueue:paymentQueue updatedTransactions:@[purchasedTransaction]];
    [paymentQueueAdapter paymentQueue:paymentQueue removedTransactions:@[purchasedTransaction]];
  });
}

void BZRPreparePaymentQueueForTransaction(SKPaymentQueue *paymentQueue, NSString *transactionID) {
  __block id<SKPaymentTransactionObserver> paymentQueueAdapter;
  OCMExpect([paymentQueue addTransactionObserver:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
    __unsafe_unretained id<SKPaymentTransactionObserver> internalPaymentQueueAdapter;
    [invocation getArgument:&internalPaymentQueueAdapter atIndex:2];
    paymentQueueAdapter = internalPaymentQueueAdapter;
    BZRPreparePaymentQueueForPaymentAddition(paymentQueue, paymentQueueAdapter, transactionID);
  });
}

SpecBegin(BZRFullIntegrationSpec)

  __block BZRReceiptValidationStatus *receiptValidationStatus;
  __block UICKeyChainStore *keychainStore;
  __block NSFileManager *fileManager;
  __block SKPaymentQueue *paymentQueue;
  __block LTDateProvider *dateProvider;
  __block NSData *dataMock;
  __block BZRStoreKitRequestsFactory *requestsFactory;
  __block LTPath *JSONFilePath;
  __block BZRProduct *subscriptionProduct;
  __block BZRStore *store;

  beforeEach(^{
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);

    keychainStore = OCMClassMock([UICKeyChainStore class]);
    OCMStub([(id)keychainStore keyChainStoreWithService:OCMOCK_ANY accessGroup:OCMOCK_ANY])
        .andReturn(keychainStore);
    fileManager = OCMPartialMock([NSFileManager defaultManager]);
    paymentQueue = OCMClassMock([SKPaymentQueue class]);
    OCMStub([(id)paymentQueue defaultQueue]).andReturn(paymentQueue);
    dateProvider = OCMClassMock([LTDateProvider class]);
    OCMStub([(id)dateProvider dateProvider]).andReturn(dateProvider);
    dataMock = OCMClassMock([NSData class]);
    requestsFactory = OCMClassMock([BZRStoreKitRequestsFactory class]);

    JSONFilePath = [LTPath pathWithPath:@"foo"];
    subscriptionProduct = BZRProductWithIdentifierAndType(@"subscription.foo.productId",
        $(BZRProductTypeRenewableSubscription));
    BZRStubFileManagerToReturnJSONWithProducts(fileManager, JSONFilePath.path, @[
      subscriptionProduct
    ]);
    BZRStubDataMockReceiptData(dataMock, @"foofile");

    SKProduct *subscriptionSKProduct = OCMClassMock([SKProduct class]);
    BZRStubSKProudctWithDataFromBZRProduct(subscriptionSKProduct, subscriptionProduct);

    auto productsResponse = BZRMockedProductsResponseWithSKProducts(@[subscriptionSKProduct]);

    SKProductsRequest *productsRequest = OCMClassMock([SKProductsRequest class]);
    OCMStub([(id)requestsFactory defaultFactory]).andReturn(requestsFactory);
    OCMStub([requestsFactory productsRequestWithIdentifiers:
             @[subscriptionProduct.identifier].lt_set]).andReturn(productsRequest);
    OCMStub([productsRequest statusSignal]).andReturn([RACSignal return:productsResponse]);

    OCMStub([dateProvider currentDate])
        .andReturn(receiptValidationStatus.receipt.subscription.expirationDateTime);
  });

  afterEach(^{
    [OHHTTPStubs removeAllStubs];
    keychainStore = nil;
    fileManager = nil;
    paymentQueue = nil;
    dateProvider = nil;
    dataMock = nil;
    [(id)requestsFactory stopMocking];
  });

it(@"should buy a subscription and be subscribed", ^{
  // We wish to simulate a behaviour where before purchase Validatricks returns an empty receipt
  // validation status, and after purchase, returns the status with the purchased subscription.
  BZRStubHTTPClientToReturnReceiptValidationStatusesInOrder(
      @[BZREmptyReceiptValidationStatus(), receiptValidationStatus]);
  auto firstTransactionId = receiptValidationStatus.receipt.transactions[0].transactionId;
  BZRPreparePaymentQueueForTransaction(paymentQueue, firstTransactionId);
  BZRStubFileManagerToReturnJSONWithASingleProduct(fileManager, JSONFilePath.path, @"foo");
  BZRStubDataMockReceiptData(dataMock, @"foofile");

  auto configuration =
    [[BZRStoreConfiguration alloc] initWithProductsListJSONFilePath:JSONFilePath
     productListDecryptionKey:nil keychainAccessGroup:nil expiredSubscriptionGracePeriod:1
     applicationUserID:nil applicationBundleID:[[NSBundle mainBundle] bundleIdentifier]
     bundledApplicationsIDs:nil multiAppSubscriptionClassifier:nil useiCloudUserID:NO
     activatePeriodicValidation:NO];
  store = [[BZRStore alloc] initWithConfiguration:configuration];

  // First the product info should be fetched, then a purchase should complete and finally the
  // subscription should be not expired.
  auto fetchProductSignal = [store fetchProductsInfo:@[subscriptionProduct.identifier].lt_set];

  auto purchaseSignal = [store purchaseProduct:subscriptionProduct.identifier];

  expect(fetchProductSignal).will.complete();
  expect(purchaseSignal).will.complete();
  expect(store.subscriptionInfo).toNot.beNil();
  expect(store.subscriptionInfo.isExpired).to.beFalsy();
});

SpecEnd
