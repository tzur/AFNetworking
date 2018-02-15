// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptModel.h"

#import "BZRReceiptEnvironment.h"
#import "NSValueTransformer+Bazaar.h"

/// Dictionary representing a JSON serialized object.
typedef NSDictionary<NSString *, id> BZRJSONDictionary;

#pragma mark -
#pragma mark BZRValidatricksReceiptInAppPurchaseInfo
#pragma mark -

SpecBegin(BZRValidatricksReceiptInAppPurchaseInfo)

it(@"should provide property key to JSON key mapping", ^{
  NSDictionary<NSString *, NSString *> *JSONKeyPaths =
      [BZRValidatricksReceiptInAppPurchaseInfo JSONKeyPathsByPropertyKey];
  for (NSString *propertyKey in [BZRValidatricksReceiptInAppPurchaseInfo propertyKeys]) {
    expect(JSONKeyPaths[propertyKey]).toNot.beNil();
  }
});

it(@"should correctly build model with JSON dictionary", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"originalTransactionId": @"1337",
    @"originalPurchaseDateTime": @1337
  };
  NSError *error;

  BZRValidatricksReceiptInAppPurchaseInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInAppPurchaseInfo class]
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

  BZRValidatricksReceiptInAppPurchaseInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInAppPurchaseInfo class]
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

  BZRValidatricksReceiptInAppPurchaseInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInAppPurchaseInfo class]
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

  BZRValidatricksReceiptInAppPurchaseInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInAppPurchaseInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).toNot.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(model).to.beNil();
});

SpecEnd

#pragma mark -
#pragma mark BZRValidatricksSubscriptionPendingRenewalInfo
#pragma mark -

SpecBegin(BZRValidatricksSubscriptionPendingRenewalInfo)

it(@"should provide property key to JSON key mapping", ^{
  NSDictionary<NSString *, NSString *> *JSONKeyPaths =
      [BZRValidatricksSubscriptionPendingRenewalInfo JSONKeyPathsByPropertyKey];
  for (NSString *propertyKey in [BZRValidatricksSubscriptionPendingRenewalInfo propertyKeys]) {
    expect(JSONKeyPaths[propertyKey]).toNot.beNil();
  }
});

it(@"should correctly build model with JSON dictionary where willAutoRenew is YES", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"willAutoRenew": @YES,
    @"expectedRenewalProductId": @"foo.bar"
  };
  NSError *error;

  BZRValidatricksSubscriptionPendingRenewalInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksSubscriptionPendingRenewalInfo class]
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
    @"expirationReason": @"billingError",
    @"isInBillingRetryPeriod": @YES
  };
  NSError *error;

  BZRValidatricksSubscriptionPendingRenewalInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksSubscriptionPendingRenewalInfo class]
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
    @"expirationReason": @"productWasUnavailable"
  };
  NSError *error;

  BZRValidatricksSubscriptionPendingRenewalInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksSubscriptionPendingRenewalInfo class]
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
    @"expirationReason": @"InvalidExpirationReason"
  };
  NSError *error;

  BZRValidatricksSubscriptionPendingRenewalInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksSubscriptionPendingRenewalInfo class]
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
#pragma mark BZRValidatricksReceiptSubscriptionInfo
#pragma mark -

SpecBegin(BZRValidatricksReceiptSubscriptionInfo)

it(@"should provide property key to JSON key mapping", ^{
  NSDictionary<NSString *, NSString *> *JSONKeyPaths =
      [BZRValidatricksReceiptSubscriptionInfo JSONKeyPathsByPropertyKey];
  for (NSString *propertyKey in [BZRValidatricksReceiptSubscriptionInfo propertyKeys]) {
    expect(JSONKeyPaths[propertyKey]).toNot.beNil();
  }
});

it(@"should correctly build model with JSON dictionary", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"expired": @YES,
    @"originalTransactionId": @"1337",
    @"originalPurchaseDateTime": @1337,
    @"expiresDateTime": @1337
  };
  NSError *error;

  BZRValidatricksReceiptSubscriptionInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptSubscriptionInfo class]
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
    @"expired": @YES,
    @"originalTransactionId": @"1337",
    @"originalPurchaseDateTime": @1000,
    @"expiresDateTime": @1000,
    @"cancellationDateTime": @1000,
    @"lastPurchaseDateTime": @1000
  };
  NSError *error;

  BZRValidatricksReceiptSubscriptionInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptSubscriptionInfo class]
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
    @"expiresDateTime": @1337
  };
  NSError *error;

  BZRValidatricksReceiptSubscriptionInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptSubscriptionInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).toNot.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(model).to.beNil();
});

it(@"should fail if the JSON dictionary contains nil for a mandatory key", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"productId": @"foo",
    @"expired": @YES,
    @"originalTransactionId": @"1337",
    @"originalPurchaseDateTime": [NSNull null],
    @"expiresDateTime": @1337
  };
  NSError *error;

  BZRValidatricksReceiptSubscriptionInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptSubscriptionInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).toNot.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(model).to.beNil();
});

SpecEnd

#pragma mark -
#pragma mark BZRValidatricksReceiptInfo
#pragma mark -

SpecBegin(BZRValidatricksReceiptInfo)

static NSString * const kValidatricksSandboxEnvironment =
    [[NSValueTransformer bzr_validatricksReceiptEnvironmentValueTransformer]
     reverseTransformedValue:$(BZRReceiptEnvironmentSandbox)];
static NSString * const kValidatricksProductionEnvironment =
    [[NSValueTransformer bzr_validatricksReceiptEnvironmentValueTransformer]
     reverseTransformedValue:$(BZRReceiptEnvironmentProduction)];

__block BZRValidatricksReceiptInAppPurchaseInfo *inAppPurchase;
__block BZRJSONDictionary *inAppPurchaseJSONDictionary;
__block BZRValidatricksReceiptSubscriptionInfo *subscription;
__block BZRJSONDictionary *subscriptionJSONDictionary;

beforeEach(^{
  NSDate *dateTime = [NSDate dateWithTimeIntervalSince1970:1337];
  inAppPurchase = [[BZRValidatricksReceiptInAppPurchaseInfo alloc] initWithDictionary:@{
    @instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo, productId): @"foo",
    @instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo, originalTransactionId): @"bar",
    @instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo, originalPurchaseDateTime): dateTime
  } error:nil];
  inAppPurchaseJSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:inAppPurchase];

  subscription = [[BZRValidatricksReceiptSubscriptionInfo alloc] initWithDictionary:@{
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, productId): @"foo",
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, originalTransactionId): @"bar",
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, originalPurchaseDateTime): dateTime,
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, expirationDateTime): dateTime,
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, isExpired): @NO
  } error:nil];
  subscriptionJSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:subscription];
});

it(@"should provide property key to JSON key mapping", ^{
  NSDictionary<NSString *, NSString *> *JSONKeyPaths =
      [BZRValidatricksReceiptInfo JSONKeyPathsByPropertyKey];
  for (NSString *propertyKey in [BZRValidatricksReceiptInfo propertyKeys]) {
    expect(JSONKeyPaths[propertyKey]).toNot.beNil();
  }
});

it(@"should correctly build model with JSON dictionary", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": kValidatricksProductionEnvironment
  };
  NSError *error;

  BZRValidatricksReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.environment).toNot.beNil();
  expect(model.inAppPurchases).to.beNil();
  expect(model.subscription).to.beNil();
});

it(@"should correctly transform receipt environment value", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": kValidatricksProductionEnvironment
  };
  NSError *error;

  BZRValidatricksReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.environment).to.equal($(BZRReceiptEnvironmentProduction));
});

it(@"should correctly transform the original purchase date time", ^{
  NSNumber *originalPurchaseDateTime = @1337000;
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": kValidatricksSandboxEnvironment,
    @"originalPurchaseDateTime": originalPurchaseDateTime
  };
  NSError *error;

  BZRValidatricksReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.originalPurchaseDateTime).to.equal([NSDate dateWithTimeIntervalSince1970:1337]);
});

it(@"should correctly transform the in app purchases array", ^{
  NSArray<BZRJSONDictionary *> *inAppPurchases =
      @[inAppPurchaseJSONDictionary, inAppPurchaseJSONDictionary];
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": kValidatricksSandboxEnvironment,
    @"inAppPurchases": inAppPurchases
  };
  NSError *error;

  BZRValidatricksReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.inAppPurchases).to.equal(@[inAppPurchase, inAppPurchase]);
});

it(@"should correctly transform the subscription model", ^{
  BZRJSONDictionary *JSONDictionary = @{
    @"environment": kValidatricksSandboxEnvironment,
    @"subscription": subscriptionJSONDictionary
  };
  NSError *error;

  BZRValidatricksReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInfo class]
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

  BZRValidatricksReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInfo class]
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

  BZRValidatricksReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).toNot.beNil();
  expect(error.lt_isLTDomain).to.beTruthy();
  expect(model).to.beNil();
});

SpecEnd
