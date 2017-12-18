// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptModel+HelperProperties.h"

SpecBegin(BZRReceiptModel_HelperProperties)

context(@"effective expiration date", ^{
  __block BZRReceiptSubscriptionInfo *subscription;

  beforeEach(^{
    subscription = [BZRReceiptSubscriptionInfo modelWithDictionary:@{
      @instanceKeypath(BZRReceiptSubscriptionInfo, productId): @"foo",
      @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"bar",
      @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime): [NSDate date],
      @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime):
          [NSDate dateWithTimeIntervalSinceNow:1337],
      @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @NO
    } error:nil];
  });

  it(@"should return the expiration date if the cancellation date is nil", ^{
    expect(subscription.effectiveExpirationDate).to.equal(subscription.expirationDateTime);
  });

  it(@"should return the expiration date if it is earlier than the cancellation date", ^{
    subscription = [subscription
                    modelByOverridingProperty:@keypath(subscription, cancellationDateTime)
                    withValue:[NSDate dateWithTimeIntervalSinceNow:2000]];
    expect(subscription.effectiveExpirationDate).to.equal(subscription.expirationDateTime);
  });

  it(@"should return the cancellation date if it is earlier than the expiration date", ^{
    subscription = [subscription
                    modelByOverridingProperty:@keypath(subscription, cancellationDateTime)
                    withValue:[NSDate dateWithTimeIntervalSinceNow:1000]];
    expect(subscription.effectiveExpirationDate).to.equal(subscription.cancellationDateTime);
  });
});

context(@"is active", ^{
  it(@"should return NO if the subscription is expired", ^{
    BZRReceiptSubscriptionInfo *subscription = [BZRReceiptSubscriptionInfo modelWithDictionary:@{
      @instanceKeypath(BZRReceiptSubscriptionInfo, productId): @"foo",
      @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"bar",
      @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime): [NSDate date],
      @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime):
          [NSDate dateWithTimeIntervalSinceNow:1337],
      @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @YES
    } error:nil];

    expect(subscription.isActive).to.beFalsy();
  });

  it(@"should return NO if the cancellation date is not nil", ^{
    BZRReceiptSubscriptionInfo *subscription = [BZRReceiptSubscriptionInfo modelWithDictionary:@{
      @instanceKeypath(BZRReceiptSubscriptionInfo, productId): @"foo",
      @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"bar",
      @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime): [NSDate date],
      @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime):
          [NSDate dateWithTimeIntervalSinceNow:1337],
      @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @NO,
      @instanceKeypath(BZRReceiptSubscriptionInfo, cancellationDateTime):
          [NSDate dateWithTimeIntervalSinceNow:1337]
    } error:nil];

    expect(subscription.isActive).to.beFalsy();
  });

  it(@"should return YES if the subscription is not expired and the cancellation date is nil", ^{
    BZRReceiptSubscriptionInfo *subscription = [BZRReceiptSubscriptionInfo modelWithDictionary:@{
      @instanceKeypath(BZRReceiptSubscriptionInfo, productId): @"foo",
      @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"bar",
      @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime): [NSDate date],
      @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime):
          [NSDate dateWithTimeIntervalSinceNow:1337],
      @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @NO
    } error:nil];

    expect(subscription.isActive).to.beTruthy();
  });
});

SpecEnd
