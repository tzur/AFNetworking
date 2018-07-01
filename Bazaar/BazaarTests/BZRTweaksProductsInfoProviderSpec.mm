// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksProductsInfoProvider.h"

#import "BZRFakeProductsInfoProvider.h"
#import "BZRFakeTweakCollectionsProvider.h"
#import "BZRProduct.h"
#import "BZRReceiptModel+GenericSubscription.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"
#import "BZRTweaksSubscriptionCollectionsProvider.h"

/// Fake \c BZRTweaksOverrideSubscriptionProvider which provides readwrite access to the
/// \c overridingSubscription, and a \c RACSubject which forwards events to the
/// \c subscriptionSourceSignal signal.
@interface BZRTweaksFakeOverrideSubscriptionProvider : NSObject
    <BZRTweaksOverrideSubscriptionProvider>

/// Redeclare as readwrite.
@property (strong, readwrite, nonatomic) BZRReceiptSubscriptionInfo *overridingSubscription;

/// Events sent on this subject are sent on \c subscriptionSourceSignal.
@property (readonly, nonatomic)
    RACSubject<BZRTweaksSubscriptionSource *> *subscriptionSourceSubject;

@end

@implementation BZRTweaksFakeOverrideSubscriptionProvider

- (instancetype)init {
  if (self = [super init]) {
    _subscriptionSourceSubject = [[RACSubject alloc] init];
  }
  return self;
}

- (RACSignal<BZRTweaksSubscriptionSource *> *)subscriptionSourceSignal {
  return self.subscriptionSourceSubject;
}

@end

SpecBegin(BZRTweaksProductsInfoProvider)

__block BZRFakeProductsInfoProvider *productsInfoProvider;
__block BZRFakeTweakCollectionsProvider *subscriptionCollectionsProvider;
__block BZRTweaksFakeOverrideSubscriptionProvider *subscriptionCollectionSignalsProvider;
__block BZRReceiptSubscriptionInfo *genericActiveSubscription;
__block BZRTweaksProductsInfoProvider *tweaksProductInfoProvider;

beforeEach(^{
  productsInfoProvider = [[BZRFakeProductsInfoProvider alloc] init];
  [productsInfoProvider fillWithArbitraryData];
  subscriptionCollectionsProvider = [[BZRFakeTweakCollectionsProvider alloc] init];
  subscriptionCollectionSignalsProvider =
      [[BZRTweaksFakeOverrideSubscriptionProvider alloc] init];
  subscriptionCollectionsProvider.collections = @[];
  genericActiveSubscription  =
      [BZRReceiptSubscriptionInfo genericActiveSubscriptionWithPendingRenewalInfo];
  tweaksProductInfoProvider = [[BZRTweaksProductsInfoProvider alloc]
                               initWithProductInfoProvider:productsInfoProvider
                               subscriptionCollectionsProvider:subscriptionCollectionsProvider
                               overrideSubscriptionProvider:subscriptionCollectionSignalsProvider
                               genericActiveSubscription:genericActiveSubscription];
});

context(@"un-tweaked properties and methods", ^{
  it(@"should proxy properties to the underlying products info provider", ^{
    expect(tweaksProductInfoProvider.purchasedProducts)
        .to.equal(productsInfoProvider.purchasedProducts);
    expect(tweaksProductInfoProvider.acquiredViaSubscriptionProducts)
        .to.equal(productsInfoProvider.acquiredViaSubscriptionProducts);
    expect(tweaksProductInfoProvider.acquiredProducts)
        .to.equal(productsInfoProvider.acquiredProducts);
    expect(tweaksProductInfoProvider.allowedProducts)
        .to.equal(productsInfoProvider.allowedProducts);
    expect(tweaksProductInfoProvider.downloadedContentProducts)
        .to.equal(productsInfoProvider.downloadedContentProducts);
    expect(tweaksProductInfoProvider.receiptValidationStatus)
        .to.equal(productsInfoProvider.receiptValidationStatus);
    expect(tweaksProductInfoProvider.appStoreLocale)
        .to.equal(productsInfoProvider.appStoreLocale);
    expect(tweaksProductInfoProvider.productsJSONDictionary)
        .to.equal(productsInfoProvider.productsJSONDictionary);
    expect(tweaksProductInfoProvider.productsJSONDictionary)
        .to.equal(productsInfoProvider.productsJSONDictionary);
  });

  it(@"should proxy the isMultiAppSubscription method", ^{
    expect([tweaksProductInfoProvider isMultiAppSubscription:@""])
        .to.equal([productsInfoProvider isMultiAppSubscription:@""]);
  });

  it(@"should proxy the contentBundleForProduct method", ^{
    auto bundleRecorder = [[tweaksProductInfoProvider contentBundleForProduct:@""] testRecorder];

    [productsInfoProvider.contentBundleForProductSubject sendNext:[NSBundle mainBundle]];
    expect(bundleRecorder).to.sendValues(@[[NSBundle mainBundle]]);
  });
});

context(@"subscription tweaking", ^{
  it(@"should send the on-device subscription before the subscriptionSourceSignal sends events", ^{
    expect(tweaksProductInfoProvider.subscriptionInfo)
        .to.equal(productsInfoProvider.subscriptionInfo);
    expect(tweaksProductInfoProvider.receiptValidationStatus.receipt.subscription)
        .to.equal(productsInfoProvider.subscriptionInfo);
  });

  it(@"should send the on-device subscription when the subscriptionSourceSignal sends "
     "'OnDevice'", ^{
    [subscriptionCollectionSignalsProvider.subscriptionSourceSubject
     sendNext:(id)@(BZRTweaksSubscriptionSourceOnDevice)];

    expect(tweaksProductInfoProvider.subscriptionInfo)
        .to.equal(productsInfoProvider.subscriptionInfo);
    expect(tweaksProductInfoProvider.receiptValidationStatus.receipt.subscription)
        .to.equal(productsInfoProvider.subscriptionInfo);
  });

  it(@"should send nil subscription when the subscriptionSourceSignal sends 'NoSubscription'", ^{
    [subscriptionCollectionSignalsProvider.subscriptionSourceSubject
     sendNext:(id)@(BZRTweaksSubscriptionSourceNoSubscription)];

    expect(tweaksProductInfoProvider.subscriptionInfo).to.beNil();
    expect(tweaksProductInfoProvider.receiptValidationStatus.receipt.subscription).to.beNil();
  });

  it(@"should send customized subscription when the subscriptionSourceSignal sends"
     "'CustomizedSubscription'", ^{
    auto overridingSubscriptionInfo =
        BZRReceiptValidationStatusWithSubscriptionIdentifier(@"fig.bar").receipt.subscription;
    subscriptionCollectionSignalsProvider.overridingSubscription = overridingSubscriptionInfo;
    [subscriptionCollectionSignalsProvider.subscriptionSourceSubject
     sendNext:(id)@(BZRTweaksSubscriptionSourceCustomizedSubscription)];

    expect(tweaksProductInfoProvider.subscriptionInfo).to.equal(overridingSubscriptionInfo);
    expect(tweaksProductInfoProvider.receiptValidationStatus.receipt.subscription)
        .equal(overridingSubscriptionInfo);
  });

  it(@"should send the generic subscription when the subscriptionSourceSignal sends "
     "'GenericActive'", ^{
    [subscriptionCollectionSignalsProvider.subscriptionSourceSubject
     sendNext:(id)@(BZRTweaksSubscriptionSourceGenericActive)];

    expect(tweaksProductInfoProvider.subscriptionInfo).to.equal(genericActiveSubscription);
    expect(tweaksProductInfoProvider.receiptValidationStatus.receipt.subscription)
        .equal(genericActiveSubscription);
  });
});

context(@"allowed products tweaking", ^{
  __block NSSet<NSString *> *allNonConsumableProductsIdentifiers;

  beforeEach(^{
    auto firstNonConsumableProduct =
        BZRProductWithIdentifierAndType(@"firstNonConsumableProduct",
                                        $(BZRProductTypeNonConsumable));
    auto secondNonConsumableProduct =
        BZRProductWithIdentifierAndType(@"secondNonConsumableProduct",
                                        $(BZRProductTypeNonConsumable));

    auto consumableProduct =
        BZRProductWithIdentifierAndType(@"consumableProduct",
                                        $(BZRProductTypeConsumable));
    auto renewableSubscriptionProduct =
        BZRProductWithIdentifierAndType(@"renewableSubscriptionProduct",
                                        $(BZRProductTypeRenewableSubscription));
    auto nonRenewableSubscriptionProduct =
        BZRProductWithIdentifierAndType(@"nonRenewableSubscriptionProduct",
                                        $(BZRProductTypeNonRenewingSubscription));

    allNonConsumableProductsIdentifiers = @[
      firstNonConsumableProduct.identifier,
      secondNonConsumableProduct.identifier
    ].lt_set;

    productsInfoProvider.allowedProducts = @[firstNonConsumableProduct.identifier].lt_set;

    productsInfoProvider.productsJSONDictionary = @{
      firstNonConsumableProduct.identifier: firstNonConsumableProduct,
      secondNonConsumableProduct.identifier: secondNonConsumableProduct,
      consumableProduct.identifier: consumableProduct,
      renewableSubscriptionProduct.identifier: renewableSubscriptionProduct,
      nonRenewableSubscriptionProduct.identifier: nonRenewableSubscriptionProduct
    };
  });

  it(@"should be empty when the subscriptionSourceSignal sends 'NoSubscription'", ^{
    [subscriptionCollectionSignalsProvider.subscriptionSourceSubject
     sendNext:(id)@(BZRTweaksSubscriptionSourceNoSubscription)];
    expect(tweaksProductInfoProvider.allowedProducts).to.beEmpty();
  });

  it(@"should be the same as the on-device allowedProducts before the subscriptionSourceSignal "
     "sends events'", ^{
    expect(tweaksProductInfoProvider.allowedProducts)
        .to.equal(productsInfoProvider.allowedProducts);
  });

  it(@"should be the same as the on-device allowedProducts when the subscriptionSourceSignal sends"
     "'OnDevice'", ^{
    [subscriptionCollectionSignalsProvider.subscriptionSourceSubject
     sendNext:(id)@(BZRTweaksSubscriptionSourceOnDevice)];
    expect(tweaksProductInfoProvider.allowedProducts)
        .to.equal(productsInfoProvider.allowedProducts);
  });

  it(@"should contain all the non-consumable products when the subscriptionSourceSignal sends"
     "'CustomizedSubscription' and the overriding subscription is not expired", ^{
    subscriptionCollectionSignalsProvider.overridingSubscription =
        BZRReceiptValidationStatusWithExpiry(NO).receipt.subscription;
    [subscriptionCollectionSignalsProvider.subscriptionSourceSubject
     sendNext:(id)@(BZRTweaksSubscriptionSourceCustomizedSubscription)];

    expect(tweaksProductInfoProvider.allowedProducts).to.equal(allNonConsumableProductsIdentifiers);
   });

  it(@"should be empty when the subscriptionSourceSignal sends 'CustomizedSubscription' and the "
     "overriding subscription is expired", ^{
    subscriptionCollectionSignalsProvider.overridingSubscription =
        BZRReceiptValidationStatusWithExpiry(YES).receipt.subscription;
    [subscriptionCollectionSignalsProvider.subscriptionSourceSubject
     sendNext:(id)@(BZRTweaksSubscriptionSourceCustomizedSubscription)];

    expect(tweaksProductInfoProvider.allowedProducts).to.equal([NSSet set]);
   });

  it(@"should contain all the non-consumable products when the subscriptionSourceSignal"
     "sends GenericActive'", ^{
    [subscriptionCollectionSignalsProvider.subscriptionSourceSubject
     sendNext:(id)@(BZRTweaksSubscriptionSourceGenericActive)];
    expect(tweaksProductInfoProvider.allowedProducts).to.equal(allNonConsumableProductsIdentifiers);
  });
});

SpecEnd
