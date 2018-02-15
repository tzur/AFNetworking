// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptModel.h"

#import "BZRReceiptEnvironment.h"
#import "NSValueTransformer+Bazaar.h"

/// Dictionary representing a JSON serialized object.
typedef NSDictionary<NSString *, id> BZRJSONDictionary;

#pragma mark -
#pragma mark BZRReceiptInAppPurchaseInfo
#pragma mark -

SpecBegin(BZRReceiptInAppPurchaseInfo)

context(@"initialization", ^{
  it(@"should not allow nil properties", ^{
    expect([BZRReceiptInAppPurchaseInfo optionalPropertyKeys].count).to.equal(0);
  });
});

it(@"should correctly build model with JSON dictionary", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"originalTransactionId": @"1337",
    @"originalPurchaseDateTime": @1337
  };
  NSError *error;

  BZRReceiptInAppPurchaseInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInAppPurchaseInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.productId).to.equal(@"foo");
  expect(model.originalTransactionId).to.equal(@"1337");
  expect(model.originalPurchaseDateTime).toNot.beNil();
});

it(@"should correctly transform original purchase date time value", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"originalTransactionId": @"1337",
    @"originalPurchaseDateTime": @1000
  };
  NSError *error;

  BZRReceiptInAppPurchaseInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInAppPurchaseInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.originalPurchaseDateTime).to.equal([NSDate dateWithTimeIntervalSince1970:1]);
});

it(@"should fail if the JSON dictionary is missing a mandatory key", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"originalTransactionId": @"1337"
  };
  NSError *error;

  BZRReceiptInAppPurchaseInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInAppPurchaseInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).toNot.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(model).to.beNil();
});

it(@"should fail if the JSON dictionary contains nil for a mandatory key", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"originalTransactionId": [NSNull null],
    @"originalPurchaseDateTime": @1337
  };
  NSError *error;

  BZRReceiptInAppPurchaseInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInAppPurchaseInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).toNot.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(model).to.beNil();
});

SpecEnd

#pragma mark -
#pragma mark BZRSubscriptionPendingRenewalInfo
#pragma mark -

SpecBegin(BZRSubscriptionPendingRenewalInfo)

it(@"should correctly build model with JSON dictionary where willAutoRenew is YES", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"willAutoRenew": @YES,
    @"expectedRenewalProductId": @"foo.bar"
  };
  NSError *error;

  BZRSubscriptionPendingRenewalInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRSubscriptionPendingRenewalInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.willAutoRenew).to.beTruthy();
  expect(model.expectedRenewalProductId).to.equal(@"foo.bar");
  expect(model.isPendingPriceIncreaseConsent).to.beFalsy();
  expect(model.expirationReason).to.beNil();
  expect(model.isInBillingRetryPeriod).to.beFalsy();
});

it(@"should correctly build model with JSON dictionary where willAutoRenew is NO", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"willAutoRenew": @NO,
    @"expirationReason": @"BZRSubscriptionExpirationReasonBillingError",
    @"isInBillingRetryPeriod": @YES
  };
  NSError *error;

  BZRSubscriptionPendingRenewalInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRSubscriptionPendingRenewalInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.willAutoRenew).to.beFalsy();
  expect(model.expectedRenewalProductId).to.beNil();
  expect(model.isPendingPriceIncreaseConsent).to.beFalsy();
  expect(model.expirationReason).to.equal($(BZRSubscriptionExpirationReasonBillingError));
  expect(model.isInBillingRetryPeriod).to.beTruthy();
});

it(@"should correctly build model if willAutoRenew is NO and expectedRenewalProductId is "
   "specified", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"willAutoRenew": @NO,
    @"expectedRenewalProductId": @"foo.bar",
    @"expirationReason": @"BZRSubscriptionExpirationReasonProductWasUnavailable"
  };
  NSError *error;

  BZRSubscriptionPendingRenewalInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRSubscriptionPendingRenewalInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.willAutoRenew).to.beFalsy();
  expect(model.expectedRenewalProductId).to.equal(@"foo.bar");
  expect(model.isPendingPriceIncreaseConsent).to.beFalsy();
  expect(model.expirationReason).to.equal($(BZRSubscriptionExpirationReasonProductWasUnavailable));
  expect(model.isInBillingRetryPeriod).to.beFalsy();
});

it(@"should correctly build model with JSON dictionary if expirationReason is invalid", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"willAutoRenew": @NO,
    @"expirationReason": @"BZRSubscriptionExpirationReasonUnknownError"
  };
  NSError *error;

  BZRSubscriptionPendingRenewalInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRSubscriptionPendingRenewalInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.willAutoRenew).to.beFalsy();
  expect(model.expectedRenewalProductId).to.beNil();
  expect(model.isPendingPriceIncreaseConsent).to.beFalsy();
  expect(model.expirationReason).to.equal($(BZRSubscriptionExpirationReasonUnknownError));
  expect(model.isInBillingRetryPeriod).to.beFalsy();
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

it(@"should correctly build model with JSON dictionary", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"isExpired": @YES,
    @"originalTransactionId": @"1337",
    @"originalPurchaseDateTime": @1337,
    @"expirationDateTime": @1337
  };
  NSError *error;

  BZRReceiptSubscriptionInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptSubscriptionInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.productId).to.equal(@"foo");
  expect(model.isExpired).to.beTruthy();
  expect(model.originalTransactionId).to.equal(@"1337");
  expect(model.originalPurchaseDateTime).toNot.beNil();
  expect(model.expirationDateTime).toNot.beNil();
  expect(model.lastPurchaseDateTime).to.beNil();
  expect(model.cancellationDateTime).to.beNil();
});

it(@"should correctly transform date time values", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"isExpired": @YES,
    @"originalTransactionId": @"1337",
    @"originalPurchaseDateTime": @1000,
    @"expirationDateTime": @1000,
    @"cancellationDateTime": @1000,
    @"lastPurchaseDateTime": @1000
  };
  NSError *error;

  BZRReceiptSubscriptionInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptSubscriptionInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.originalPurchaseDateTime).to.equal([NSDate dateWithTimeIntervalSince1970:1]);
  expect(model.expirationDateTime).to.equal([NSDate dateWithTimeIntervalSince1970:1]);
  expect(model.cancellationDateTime).to.equal([NSDate dateWithTimeIntervalSince1970:1]);
  expect(model.lastPurchaseDateTime).to.equal([NSDate dateWithTimeIntervalSince1970:1]);
});

it(@"should fail if the JSON dictionary is missing a mandatory key", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"originalTransactionId": @"1337",
    @"originalPurchaseDateTime": @1337,
    @"expirationDateTime": @1337
  };
  NSError *error;

  BZRReceiptSubscriptionInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptSubscriptionInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).toNot.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(model).to.beNil();
});

it(@"should fail if the JSON dictionary contains nil for a mandatory key", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"isExpired": @YES,
    @"originalTransactionId": @"1337",
    @"originalPurchaseDateTime": [NSNull null],
    @"expirationDateTime": @1337
  };
  NSError *error;

  BZRReceiptSubscriptionInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptSubscriptionInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).toNot.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(model).to.beNil();
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

__block BZRReceiptInAppPurchaseInfo *inAppPurchase;
__block BZRJSONDictionary *inAppPurchaseJSONDictionary;
__block BZRReceiptSubscriptionInfo *subscription;
__block BZRJSONDictionary *subscriptionJSONDictionary;

beforeEach(^{
  NSDate *dateTime = [NSDate dateWithTimeIntervalSince1970:1337];
  inAppPurchase = [[BZRReceiptInAppPurchaseInfo alloc] initWithDictionary:@{
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, productId): @"foo",
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, originalTransactionId): @"bar",
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, originalPurchaseDateTime): dateTime
  } error:nil];
  inAppPurchaseJSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:inAppPurchase];

  subscription = [[BZRReceiptSubscriptionInfo alloc] initWithDictionary:@{
    @instanceKeypath(BZRReceiptSubscriptionInfo, productId): @"foo",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"bar",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime): dateTime,
    @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime): dateTime,
    @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @NO
  } error:nil];
  subscriptionJSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:subscription];
});

it(@"should correctly build model with JSON dictionary", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": @"BZRReceiptEnvironmentProduction"
  };
  NSError *error;

  BZRReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.environment).toNot.beNil();
  expect(model.inAppPurchases).to.beNil();
  expect(model.subscription).to.beNil();
});

it(@"should correctly transform receipt environment value", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": @"BZRReceiptEnvironmentProduction"
  };
  NSError *error;

  BZRReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.environment).to.equal($(BZRReceiptEnvironmentProduction));
});

it(@"should correctly transform the original purchase date time", ^{
  NSNumber *originalPurchaseDateTime = @1337000;
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": @"BZRReceiptEnvironmentSandbox",
    @"originalPurchaseDateTime": originalPurchaseDateTime
  };
  NSError *error;

  BZRReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.originalPurchaseDateTime).to.equal([NSDate dateWithTimeIntervalSince1970:1337]);
});

it(@"should correctly transform the in app purchases array", ^{
  NSArray<BZRJSONDictionary *> *inAppPurchases =
      @[inAppPurchaseJSONDictionary, inAppPurchaseJSONDictionary];
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": @"BZRReceiptEnvironmentSandbox",
    @"inAppPurchases": inAppPurchases
  };
  NSError *error;

  BZRReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.inAppPurchases).to.equal(@[inAppPurchase, inAppPurchase]);
});

it(@"should correctly transform the subscription model", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": @"BZRReceiptEnvironmentSandbox",
    @"subscription": subscriptionJSONDictionary
  };
  NSError *error;

  BZRReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.subscription).to.equal(subscription);
});

it(@"should fail if the JSON dictionary is missing a mandatory key", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"inAppPurchases": @[inAppPurchaseJSONDictionary],
    @"subscription": subscriptionJSONDictionary
  };
  NSError *error;

  BZRReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).toNot.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(model).to.beNil();
});

it(@"should fail if the JSON dictionary contains nil value for a mandatory key", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": [NSNull null]
  };
  NSError *error;

  BZRReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).toNot.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(model).to.beNil();
});

SpecEnd
