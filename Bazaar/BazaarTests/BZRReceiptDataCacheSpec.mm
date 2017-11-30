// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptDataCache.h"

#import "BZRKeychainStorageRoute.h"

SpecBegin(BZRReceiptDataCache)

__block BZRKeychainStorageRoute *keychainStorageRoute;
__block NSString *currentApplicationBundleID;
__block BZRReceiptDataCache *receiptDataCache;

beforeEach(^{
  keychainStorageRoute = OCMClassMock([BZRKeychainStorageRoute class]);
  currentApplicationBundleID = @"foo";
  receiptDataCache =
      [[BZRReceiptDataCache alloc] initWithKeychainStorageRoute:keychainStorageRoute
                                     currentApplicationBundleID:currentApplicationBundleID];
});

context(@"retrieving receipt data from storage", ^{
  it(@"should use keychain storage route to retrieve data from storage", ^{
    NSData *expectedData =
        [NSJSONSerialization dataWithJSONObject:@{@"foo": @"bar"} options:0 error:nil];
    OCMStub([keychainStorageRoute valueForKey:OCMOCK_ANY serviceName:@"bar" error:nil])
        .andReturn(expectedData);

    auto data = [receiptDataCache receiptDataForBundleID:@"bar" error:nil];

    expect(data).to.equal(expectedData);
  });

  it(@"should return error in case keychain storage route returned error", ^{
    NSError *storageError = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorageRoute valueForKey:OCMOCK_ANY serviceName:@"bar"
                                        error:[OCMArg setTo:storageError]]);

    NSError *error;
    auto data = [receiptDataCache receiptDataForBundleID:@"bar" error:&error];

    expect(data).to.beNil();
    expect(error).to.equal(storageError);
  });
});

context(@"writing receipt data to storage", ^{
  it(@"should store non-nil receipt data to storage", ^{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    id mockData = OCMClassMock([NSData class]);
    OCMStub([mockData dataWithContentsOfURL:receiptURL]).andReturn(receiptData);

    [receiptDataCache storeReceiptData];

    OCMVerify([keychainStorageRoute setValue:receiptData forKey:OCMOCK_ANY serviceName:@"foo"
                                       error:[OCMArg anyObjectRef]]);
  });

  it(@"should not store nil receipt data to storage", ^{
    id mockData = OCMClassMock([NSData class]);
    OCMStub([mockData dataWithContentsOfURL:OCMOCK_ANY]);

    OCMReject([keychainStorageRoute setValue:OCMOCK_ANY forKey:OCMOCK_ANY serviceName:@"foo"
                                       error:[OCMArg anyObjectRef]]);

    [receiptDataCache storeReceiptData];
  });
});

SpecEnd
