// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptModel.h"

#import "BZRReceiptEnvironment.h"
#import "NSValueTransformer+Validatricks.h"

#pragma mark -
#pragma mark BZRValidatricksReceiptInAppPurchaseInfo
#pragma mark -

SpecBegin(BZRValidatricksReceiptInAppPurchaseInfo)

__block NSDictionary *JSONKeysMapping;

beforeEach(^{
  JSONKeysMapping = [BZRValidatricksReceiptInAppPurchaseInfo JSONKeyPathsByPropertyKey];
});

it(@"should provide property key to JSON key mapping", ^{
  for (NSString *propertyKey in [BZRValidatricksReceiptInAppPurchaseInfo propertyKeys]) {
    expect(JSONKeysMapping[propertyKey]).toNot.beNil();
  }
});

it(@"should correctly build model with JSON dictionary", ^{
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo, productId)]: @"foo",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo,
                                     originalTransactionId)]: @"1337",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo,
                                     originalPurchaseDateTime)]: @1337
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
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo, productId)]: @"foo",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo,
                                     originalTransactionId)]: @"1337",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo,
                                     originalPurchaseDateTime)]: @1000
  };
  NSError *error;
  BZRValidatricksReceiptInAppPurchaseInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInAppPurchaseInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.originalPurchaseDateTime).to.equal([NSDate dateWithTimeIntervalSince1970:1]);
});

it(@"should fail if the JSON dictionary is missing a mandatory key", ^{
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo, productId)]: @"foo",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo,
                                     originalTransactionId)]: @"1337"
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
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo, productId)]: @"foo",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo,
                                     originalTransactionId)]: [NSNull null],
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo,
                                     originalPurchaseDateTime)]: @1337
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
#pragma mark BZRValidatricksReceiptSubscriptionInfo
#pragma mark -

SpecBegin(BZRValidatricksReceiptSubscriptionInfo)

__block NSDictionary *JSONKeysMapping;

beforeEach(^{
  JSONKeysMapping = [BZRValidatricksReceiptSubscriptionInfo JSONKeyPathsByPropertyKey];
});

it(@"should provide property key to JSON key mapping", ^{
  for (NSString *propertyKey in [BZRValidatricksReceiptSubscriptionInfo propertyKeys]) {
    expect(JSONKeysMapping[propertyKey]).toNot.beNil();
  }
});

it(@"should correctly build model with JSON dictionary", ^{
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, productId)]: @"foo",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, isExpired)]: @YES,
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     originalTransactionId)]: @"1337",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     originalPurchaseDateTime)]: @1337,
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     expirationDateTime)]: @1337
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

it(@"should correctly date time values", ^{
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, productId)]: @"foo",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, isExpired)]: @YES,
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     originalTransactionId)]: @"1337",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     originalPurchaseDateTime)]: @1000,
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     expirationDateTime)]: @1000,
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     cancellationDateTime)]: @1000,
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     lastPurchaseDateTime)]: @1000
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
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, productId)]: @"foo",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     originalTransactionId)]: @"1337",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     originalPurchaseDateTime)]: @1337,
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     expirationDateTime)]: @1337
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
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, productId)]: @"foo",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, isExpired)]: @YES,
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     originalTransactionId)]: @"1337",
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     originalPurchaseDateTime)]: [NSNull null],
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptSubscriptionInfo,
                                     expirationDateTime)]: @1337
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

__block NSDictionary *JSONKeysMapping;
__block BZRValidatricksReceiptInAppPurchaseInfo *inAppPurchase;
__block NSDictionary *inAppPurchaseJSONDictionary;
__block BZRValidatricksReceiptSubscriptionInfo *subscription;
__block NSDictionary *subscriptionJSONDictionary;

beforeEach(^{
  JSONKeysMapping = [BZRValidatricksReceiptInfo JSONKeyPathsByPropertyKey];

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
  for (NSString *propertyKey in [BZRValidatricksReceiptInfo propertyKeys]) {
    expect(JSONKeysMapping[propertyKey]).toNot.beNil();
  }
});

it(@"should correctly build model with JSON dictionary", ^{
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInfo, environment)]:
        kValidatricksProductionEnvironment
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
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInfo, environment)]:
        kValidatricksProductionEnvironment
  };
  NSError *error;
  BZRValidatricksReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.environment).to.equal($(BZRReceiptEnvironmentProduction));
});

it(@"should correctly transform the in app purchases array", ^{
  NSArray *inAppPurchases = @[inAppPurchaseJSONDictionary, inAppPurchaseJSONDictionary];
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInfo, environment)]:
        kValidatricksSandboxEnvironment,
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInfo, inAppPurchases)]: inAppPurchases
  };
  NSError *error;
  BZRValidatricksReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.inAppPurchases).to.equal(@[inAppPurchase, inAppPurchase]);
});

it(@"should correctly transform the subscription model", ^{
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInfo, environment)]:
        kValidatricksSandboxEnvironment,
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInfo, subscription)]:
        subscriptionJSONDictionary
  };
  NSError *error;
  BZRValidatricksReceiptInfo *model =
      [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptInfo class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(model.subscription).to.equal(subscription);
});

it(@"should fail if the JSON dictionary is missing a mandatory key", ^{
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInfo, inAppPurchases)]:
        @[inAppPurchaseJSONDictionary],
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInfo, subscription)]:
        subscriptionJSONDictionary
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
  NSDictionary *JSONDictionary = @{
    JSONKeysMapping[@instanceKeypath(BZRValidatricksReceiptInfo, environment)]: [NSNull null]
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
