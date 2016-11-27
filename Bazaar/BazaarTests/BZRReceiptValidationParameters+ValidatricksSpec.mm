// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationParameters+Validatricks.h"

SpecBegin(BZRReceiptValidationParameters_Validatricks)

static NSString * const kReceiptDataKey = @"receipt";
static NSString * const kBundleIdKey = @"bundle";
static NSString * const kDeviceIdKey = @"idForVendor";
static NSString * const kAppStoreCountryCodeKey = @"appStoreCountryCode";

__block NSData *receiptData;
__block NSString *bundleId;
__block NSUUID *deviceId;

beforeEach(^{
  receiptData = [@"foo.bar" dataUsingEncoding:NSUTF8StringEncoding];
  bundleId = @"foo.bar";
  deviceId = [NSUUID UUID];
});

it(@"should provide a dictionary with the specified parameters", ^{
  BZRReceiptValidationParameters *parameters =
      [[BZRReceiptValidationParameters alloc] initWithReceiptData:receiptData
                                              applicationBundleId:bundleId deviceId:deviceId
                                                   appStoreLocale:[NSLocale currentLocale]];
  NSDictionary *validatricksRequestParameters = [parameters validatricksRequestParameters];

  expect([[NSData alloc] initWithBase64EncodedString:validatricksRequestParameters[kReceiptDataKey]
                                             options:0]).to.equal(receiptData);
  expect(validatricksRequestParameters[kBundleIdKey]).to.equal(bundleId);
  expect([[NSUUID alloc] initWithUUIDString:validatricksRequestParameters[kDeviceIdKey]]).to
      .equal(deviceId);
  expect(validatricksRequestParameters[kAppStoreCountryCodeKey]).to
      .equal([[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]);
});

it(@"should provide a dictionary with out id for vendor if no device id is specified", ^{
  BZRReceiptValidationParameters *parameters =
  [[BZRReceiptValidationParameters alloc] initWithReceiptData:receiptData
                                          applicationBundleId:bundleId deviceId:nil
                                               appStoreLocale:nil];
  NSDictionary *validatricksRequestParameters = [parameters validatricksRequestParameters];

  expect([[NSData alloc] initWithBase64EncodedString:validatricksRequestParameters[kReceiptDataKey]
                                             options:0]).to.equal(receiptData);
  expect(validatricksRequestParameters[kBundleIdKey]).to.equal(bundleId);
  expect(validatricksRequestParameters[kDeviceIdKey]).to.beNil();
  expect(validatricksRequestParameters[kAppStoreCountryCodeKey]).to.beNil();
});

SpecEnd
