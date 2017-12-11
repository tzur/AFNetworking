// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationParametersProvider.h"

#import "BZRAppStoreLocaleCache.h"
#import "BZRReceiptDataCache.h"
#import "BZRReceiptValidationParameters.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRReceiptValidationParametersProvider)

__block BZRReceiptDataCache *receiptDataCache;
__block BZRAppStoreLocaleCache *appStoreLocaleCache;
__block NSString *currentApplicationBundleID;
__block BZRReceiptValidationParametersProvider *parametersProvider;

beforeEach(^{
  receiptDataCache = OCMClassMock([BZRReceiptDataCache class]);
  appStoreLocaleCache = OCMClassMock([BZRAppStoreLocaleCache class]);
  currentApplicationBundleID = @"foo";
  parametersProvider =
      [[BZRReceiptValidationParametersProvider alloc]
       initWithAppStoreLocaleCache:appStoreLocaleCache receiptDataCache:receiptDataCache
       currentApplicationBundleID:currentApplicationBundleID];
});

context(@"loading app store locale from cache", ^{
  it(@"should be nil if app store locale not found in cache", ^{
    expect([parametersProvider appStoreLocale]).to.beNil();
  });

  it(@"should be nil if there was an error loading the app store locale", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([appStoreLocaleCache appStoreLocaleForBundleID:currentApplicationBundleID
                                                     error:[OCMArg setTo:error]]);

    expect([parametersProvider appStoreLocale]).to.beNil();
  });
});

context(@"storing app store locale to cache", ^{
  it(@"should store app store locale to cache after it has been set", ^{
    NSLocale *appStoreLocale = [NSLocale currentLocale];

    parametersProvider.appStoreLocale = appStoreLocale;

    OCMVerify([appStoreLocaleCache appStoreLocaleForBundleID:currentApplicationBundleID
                                                       error:[OCMArg anyObjectRef]]);
  });

  it(@"should not store app store locale if the new value is identical to the old one", ^{
    NSLocale *appStoreLocale = [NSLocale currentLocale];
    parametersProvider.appStoreLocale = appStoreLocale;

    OCMReject([appStoreLocaleCache appStoreLocaleForBundleID:currentApplicationBundleID
                                                       error:[OCMArg anyObjectRef]]);

    parametersProvider.appStoreLocale = [NSLocale currentLocale];
  });
});

context(@"KVO-compliance", ^{
  it(@"should update when app store locale changes", ^{
    RACSignal *appStoreLocaleSignal = [RACObserve(parametersProvider, appStoreLocale) testRecorder];

    parametersProvider.appStoreLocale = [NSLocale currentLocale];

    expect(appStoreLocaleSignal).to.sendValues(@[
      [NSNull null],
      [NSLocale currentLocale]
    ]);
  });
});

context(@"providing receipt validation parameters", ^{
  it(@"should return parameters with the correct current application bundle ID and device ID", ^{
    NSData *receiptData = [@"Bar Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([receiptDataCache receiptDataForApplicationBundleID:@"bar"
        error:[OCMArg anyObjectRef]]).andReturn(receiptData);

    auto receiptValidationParameters =
        [parametersProvider receiptValidationParametersForApplication:@"bar"];

    expect(receiptValidationParameters.currentApplicationBundleID).to
        .equal(currentApplicationBundleID);
    expect(receiptValidationParameters.deviceID).to
        .equal([[UIDevice currentDevice] identifierForVendor]);
  });

  it(@"should return receipt data of the bundle ID that was requested", ^{
    NSData *receiptData = [@"Bar Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([receiptDataCache receiptDataForApplicationBundleID:@"bar"
        error:[OCMArg anyObjectRef]]).andReturn(receiptData);

    auto receiptValidationParameters =
        [parametersProvider receiptValidationParametersForApplication:@"bar"];

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
         currentApplicationBundleID];

    expect(receiptValidationParameters.receiptData).to.equal(receiptDataFromFile);
  });

  it(@"should return nil if receipt data was not found", ^{
    expect([parametersProvider receiptValidationParametersForApplication:@"bar"])
        .to.beNil();
  });

  it(@"should return App Store locale of the bundle ID that was requested", ^{
    NSData *receiptData = [@"Bar Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([receiptDataCache receiptDataForApplicationBundleID:@"bar"
        error:[OCMArg anyObjectRef]]).andReturn(receiptData);

    NSLocale *appStoreLocale = [NSLocale localeWithLocaleIdentifier:@"de_DE"];
    OCMStub([appStoreLocaleCache appStoreLocaleForBundleID:@"bar"
        error:[OCMArg anyObjectRef]]).andReturn(appStoreLocale);

    auto receiptValidationParameters =
        [parametersProvider receiptValidationParametersForApplication:@"bar"];

    expect(receiptValidationParameters.appStoreLocale).to.equal(appStoreLocale);
  });

  it(@"should insert the current application's App Store locale from the property rather than from "
     "cache", ^{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptDataFromFile =
        [@"Receipt Data from file" dataUsingEncoding:NSUTF8StringEncoding];
    id mockData = OCMClassMock([NSData class]);
    OCMStub([mockData dataWithContentsOfURL:receiptURL]).andReturn(receiptDataFromFile);

    parametersProvider.appStoreLocale = [NSLocale currentLocale];

    auto receiptValidationParameters =
        [parametersProvider receiptValidationParametersForApplication:
         currentApplicationBundleID];

    expect(receiptValidationParameters.appStoreLocale).to.equal(parametersProvider.appStoreLocale);
  });
});

SpecEnd
