// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptModel.h"

#pragma mark -
#pragma mark BZRReceiptInAppPurchaseInfo
#pragma mark -

SpecBegin(BZRReceiptInAppPurchaseInfo)

context(@"initialization", ^{
  it(@"should not allow nil properties", ^{
    expect([BZRReceiptInAppPurchaseInfo optionalPropertyKeys].count).to.equal(0);
  });
});

SpecEnd

#pragma mark -
#pragma mark BZRReceiptSubscriptionInfo
#pragma mark -

SpecBegin(BZRReceiptSubscriptionInfo)

context(@"initialization", ^{
  it(@"should correctly specify optional properties", ^{
    NSSet<NSString *> *nullableProperties = [BZRReceiptSubscriptionInfo optionalPropertyKeys];

    expect(nullableProperties.count).to.equal(3);
    expect(nullableProperties).to
        .contain(@instanceKeypath(BZRReceiptSubscriptionInfo, lastPurchaseDateTime));
    expect(nullableProperties).to
        .contain(@instanceKeypath(BZRReceiptSubscriptionInfo, cancellationDateTime));
    expect(nullableProperties).to
        .contain(@instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo));
  });
});

SpecEnd

#pragma mark -
#pragma mark BZRReceiptInfo
#pragma mark -

SpecBegin(BZRReceiptInfo)

context(@"initialization", ^{
  it(@"should correctly specifiy optional properties", ^{
    NSSet<NSString *> *nullableProperties = [BZRReceiptInfo optionalPropertyKeys];

    expect(nullableProperties.count).to.equal(3);
    expect(nullableProperties).to
        .contain(@instanceKeypath(BZRReceiptInfo, originalPurchaseDateTime));
    expect(nullableProperties).to.contain(@instanceKeypath(BZRReceiptInfo, inAppPurchases));
    expect(nullableProperties).to.contain(@instanceKeypath(BZRReceiptInfo, subscription));
  });
});

SpecEnd
