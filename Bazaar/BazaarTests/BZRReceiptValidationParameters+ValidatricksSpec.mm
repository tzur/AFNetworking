// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationParameters+Validatricks.h"

SpecBegin(BZRReceiptValidationParameters_Validatricks)

static NSString * const kkRequestingApplicationIDKey = @"originBundle";
static NSString * const kReceiptDataKey = @"receipt";
static NSString * const kDeviceIDKey = @"idForVendor";
static NSString * const kAppStoreCountryCodeKey = @"appStoreCountryCode";
static NSString * const kBundleIDKey = @"bundle";
static NSString * const kUserIDKey = @"userID";

__block NSString *originBundleID;
__block NSData *receiptData;
__block NSString *bundleID;
__block NSUUID *deviceId;
__block NSString *userID;

beforeEach(^{
  originBundleID = @"foo";
  receiptData = [@"foo.bar" dataUsingEncoding:NSUTF8StringEncoding];
  bundleID = @"foo.bar";
  deviceId = [NSUUID UUID];
  userID = @"baz";
});

it(@"should provide a dictionary with the specified parameters", ^{
  BZRReceiptValidationParameters *parameters =
      [[BZRReceiptValidationParameters alloc]
       initWithCurrentApplicationBundleID:originBundleID applicationBundleID:bundleID
       receiptData:receiptData deviceID:deviceId appStoreLocale:[NSLocale currentLocale]
       userID:userID];
  NSDictionary *validatricksRequestParameters = [parameters validatricksRequestParameters];

  expect(validatricksRequestParameters[kkRequestingApplicationIDKey]).to.equal(originBundleID);
  expect([[NSData alloc] initWithBase64EncodedString:validatricksRequestParameters[kReceiptDataKey]
                                             options:0]).to.equal(receiptData);
  expect(validatricksRequestParameters[kBundleIDKey]).to.equal(bundleID);
  expect([[NSUUID alloc] initWithUUIDString:validatricksRequestParameters[kDeviceIDKey]]).to
      .equal(deviceId);
  expect(validatricksRequestParameters[kAppStoreCountryCodeKey]).to
      .equal([[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]);
});

it(@"should provide a dictionary without id for vendor if no device id is specified", ^{
  BZRReceiptValidationParameters *parameters =
      [[BZRReceiptValidationParameters alloc]
       initWithCurrentApplicationBundleID:originBundleID applicationBundleID:bundleID
       receiptData:nil deviceID:nil appStoreLocale:nil userID:nil];
  NSDictionary *validatricksRequestParameters = [parameters validatricksRequestParameters];

  expect(validatricksRequestParameters[kDeviceIDKey]).to.beNil();
  expect(validatricksRequestParameters[kReceiptDataKey]).to.beNil();
  expect(validatricksRequestParameters[kAppStoreCountryCodeKey]).to.beNil();
  expect(validatricksRequestParameters[kUserIDKey]).to.beNil();
});

SpecEnd
