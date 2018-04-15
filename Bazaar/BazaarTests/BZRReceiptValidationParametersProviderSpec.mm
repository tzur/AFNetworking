// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationParametersProvider.h"

#import "BZRFakeAppStoreLocaleProvider.h"
#import "BZRReceiptDataCache.h"
#import "BZRReceiptValidationParameters.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRReceiptValidationParametersProvider)

__block BZRReceiptDataCache *receiptDataCache;
__block BZRFakeAppStoreLocaleProvider *appStoreLocaleProvider;
__block NSString *currentApplicationBundleID;
__block NSString *userID;
__block BZRReceiptValidationParametersProvider *parametersProvider;

beforeEach(^{
  receiptDataCache = OCMClassMock([BZRReceiptDataCache class]);
  appStoreLocaleProvider = [[BZRFakeAppStoreLocaleProvider alloc] init];
  currentApplicationBundleID = @"foo";
  userID = @"bar";
  parametersProvider =
      [[BZRReceiptValidationParametersProvider alloc]
       initWithAppStoreLocaleProvider:appStoreLocaleProvider receiptDataCache:receiptDataCache
       currentApplicationBundleID:currentApplicationBundleID];
});

context(@"providing receipt validation parameters", ^{
  it(@"should return parameters with the correct parameters", ^{
    NSData *receiptData = [@"Bar Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([receiptDataCache receiptDataForApplicationBundleID:@"bar"
        error:[OCMArg anyObjectRef]]).andReturn(receiptData);

    auto receiptValidationParameters =
        [parametersProvider receiptValidationParametersForApplication:@"bar" userID:userID];

    expect(receiptValidationParameters.currentApplicationBundleID).to
        .equal(currentApplicationBundleID);
    expect(receiptValidationParameters.deviceID).to
        .equal([[UIDevice currentDevice] identifierForVendor]);
    expect(receiptValidationParameters.userID).to.equal(userID);
  });

  it(@"should return receipt data of the bundle ID that was requested", ^{
    NSData *receiptData = [@"Bar Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([receiptDataCache receiptDataForApplicationBundleID:@"bar"
        error:[OCMArg anyObjectRef]]).andReturn(receiptData);

    auto receiptValidationParameters =
        [parametersProvider receiptValidationParametersForApplication:@"bar" userID:userID];

    expect(receiptValidationParameters.receiptData).to.equal(receiptData);
  });

  it(@"should request the receipt data of the current application bundle ID from the receipt data "
     "file", ^{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptDataFromFile =
        [@"Receipt Data from file" dataUsingEncoding:NSUTF8StringEncoding];
    id mockData = OCMClassMock([NSData class]);
    OCMStub([mockData dataWithContentsOfURL:receiptURL]).andReturn(receiptDataFromFile);

    auto receiptValidationParameters =
        [parametersProvider receiptValidationParametersForApplication:
         currentApplicationBundleID userID:userID];

    expect(receiptValidationParameters.receiptData).to.equal(receiptDataFromFile);
  });

  it(@"should return parameters if receipt data was not found and user ID is not nil", ^{
    expect([parametersProvider receiptValidationParametersForApplication:@"bar" userID:userID])
        .toNot.beNil();
  });

  it(@"should return parameters if receipt data was found and user ID is nil", ^{
    NSData *receiptData = [@"Bar Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([receiptDataCache receiptDataForApplicationBundleID:@"bar"
        error:[OCMArg anyObjectRef]]).andReturn(receiptData);

    expect([parametersProvider receiptValidationParametersForApplication:@"bar" userID:nil])
        .toNot.beNil();
  });

  it(@"should return nil if receipt data was not found and user ID is nil", ^{
    expect([parametersProvider receiptValidationParametersForApplication:@"bar" userID:nil])
        .to.beNil();
  });

  it(@"should return App Store locale of the bundle ID that was requested", ^{
    NSData *receiptData = [@"Bar Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([receiptDataCache receiptDataForApplicationBundleID:@"bar"
        error:[OCMArg anyObjectRef]]).andReturn(receiptData);

    NSLocale *appStoreLocale = [NSLocale localeWithLocaleIdentifier:@"de_DE"];
    OCMStub([appStoreLocaleProvider appStoreLocaleForBundleID:@"bar"
        error:[OCMArg anyObjectRef]]).andReturn(appStoreLocale);

    auto receiptValidationParameters =
        [parametersProvider receiptValidationParametersForApplication:@"bar" userID:userID];

    expect(receiptValidationParameters.appStoreLocale).to.equal(appStoreLocale);
  });

  it(@"should insert the current application's App Store locale from the property rather than from "
     "cache", ^{
    NSLocale *appStoreLocale = [NSLocale localeWithLocaleIdentifier:@"de_DE"];
    appStoreLocaleProvider.appStoreLocale = appStoreLocale;

    auto receiptValidationParameters =
        [parametersProvider receiptValidationParametersForApplication:
         currentApplicationBundleID userID:userID];

    expect(receiptValidationParameters.appStoreLocale).to.equal(appStoreLocale);
  });
});

SpecEnd
