// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationParameters.h"

SpecBegin(BZRReceiptValidationParameters)

context(@"default parameters", ^{
  __block id mainBundleMock;
  __block NSString *bundleId;

  beforeEach(^{
    bundleId = @"foo.bar.baz";
    mainBundleMock = OCMPartialMock([NSBundle mainBundle]);
    OCMStub([mainBundleMock bundleIdentifier]).andReturn(bundleId);
  });

  afterEach(^{
    mainBundleMock = nil;
  });
  
  context(@"receipt data is available", ^{
    __block id receiptData;

    beforeEach(^{
      NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
      receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
      id mockData = OCMClassMock([NSData class]);
      OCMStub([mockData dataWithContentsOfURL:receiptURL]).andReturn(receiptData);
    });

    it(@"should initialize with default parameters", ^{
      BZRReceiptValidationParameters *parameters =
          [BZRReceiptValidationParameters defaultParameters];

      expect(parameters).toNot.beNil();
      expect(parameters.applicationBundleId).to.equal([[NSBundle mainBundle] bundleIdentifier]);
      expect(parameters.deviceId).to.equal([[UIDevice currentDevice] identifierForVendor]);
      expect(parameters.receiptData).to.equal(receiptData);
      expect(parameters.appStoreLocale).to.beNil();
    });
  });

  context(@"receipt data is not available", ^{
    beforeEach(^{
      NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
      id mockData = OCMClassMock([NSData class]);
      OCMStub([mockData dataWithContentsOfURL:receiptURL]);
    });

    it(@"should return nil if failed to read receipt data", ^{
      BZRReceiptValidationParameters *parameters =
          [BZRReceiptValidationParameters defaultParameters];

      expect(parameters).to.beNil();
    });
  });
});

context(@"initialization with specific parameters", ^{
  it(@"should initialize with the specified parameters", ^{
    NSData *receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *bundleId = @"foo.bar.baz";
    NSUUID *deviceId = [NSUUID UUID];
    BZRReceiptValidationParameters *parameters =
        [[BZRReceiptValidationParameters alloc] initWithReceiptData:receiptData
                                                applicationBundleId:bundleId deviceId:deviceId
                                                     appStoreLocale:[NSLocale currentLocale]];

    expect(parameters.receiptData).to.equal(receiptData);
    expect(parameters.applicationBundleId).to.equal(bundleId);
    expect(parameters.deviceId).to.equal(deviceId);
    expect(parameters.appStoreLocale).to.equal([NSLocale currentLocale]);
  });
});

SpecEnd
