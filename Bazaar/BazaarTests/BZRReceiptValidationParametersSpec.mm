// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationParameters.h"

SpecBegin(BZRReceiptValidationParameters)

context(@"default parameters", ^{
  __block NSString *bundleID;
  __block NSString *currentApplicationBundleID;
  __block NSData *receiptData;
  __block NSLocale *appStoreLocale;
  __block NSString *userID;

  beforeEach(^{
    bundleID = @"foo.bar.baz";
    currentApplicationBundleID = @"foo";

    receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    appStoreLocale = [NSLocale currentLocale];
    userID = @"baz";
  });

  it(@"should initialize with the specified parameters", ^{
    NSData *receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *bundleID = @"foo.bar";
    NSUUID *deviceId = [NSUUID UUID];

    BZRReceiptValidationParameters *parameters =
        [[BZRReceiptValidationParameters alloc] initWithCurrentApplicationBundleID:bundleID
         applicationBundleID:bundleID receiptData:receiptData deviceID:deviceId appStoreLocale:nil
         userID:userID];

    expect(parameters.currentApplicationBundleID).to.equal(bundleID);
    expect(parameters.applicationBundleID).to.equal(bundleID);
    expect(parameters.deviceID).to.equal(deviceId);
    expect(parameters.receiptData).to.equal(receiptData);
    expect(parameters.appStoreLocale).to.beNil();
    expect(parameters.userID).to.equal(userID);
  });
});

SpecEnd
