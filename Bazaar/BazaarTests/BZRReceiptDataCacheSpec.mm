// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptDataCache.h"

#import "BZRKeychainStorageRoute.h"

SpecBegin(BZRReceiptDataCache)

__block BZRKeychainStorageRoute *keychainStorageRoute;
__block BZRReceiptDataCache *receiptDataCache;

beforeEach(^{
  keychainStorageRoute = OCMClassMock([BZRKeychainStorageRoute class]);
  receiptDataCache =
      [[BZRReceiptDataCache alloc] initWithKeychainStorageRoute:keychainStorageRoute];
});

context(@"retrieving receipt data from storage", ^{
  it(@"should use keychain storage route to retrieve data from storage", ^{
    NSData *expectedData =
        [NSJSONSerialization dataWithJSONObject:@{@"foo": @"bar"} options:0 error:nil];
    OCMStub([keychainStorageRoute valueForKey:OCMOCK_ANY serviceName:@"bar" error:nil])
        .andReturn(expectedData);

    auto data = [receiptDataCache receiptDataForApplicationBundleID:@"bar" error:nil];

    expect(data).to.equal(expectedData);
  });

  it(@"should set error and return nil in case keychain storage route returned error", ^{
    NSError *storageError = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorageRoute valueForKey:OCMOCK_ANY serviceName:@"bar"
                                        error:[OCMArg setTo:storageError]]);

    NSError *error;
    auto data = [receiptDataCache receiptDataForApplicationBundleID:@"bar" error:&error];

    expect(data).to.beNil();
    expect(error).to.equal(storageError);
  });
});

context(@"writing receipt data to storage", ^{
  it(@"should return YES when storing receipt data to storage was successful", ^{
    OCMStub([keychainStorageRoute setValue:OCMOCK_ANY forKey:OCMOCK_ANY serviceName:@"foo"
                                     error:[OCMArg anyObjectRef]]).andReturn(YES);

    NSData *receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    BOOL success = [receiptDataCache storeReceiptData:receiptData applicationBundleID:@"foo"
                                                error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should set error and return NO when there was an error storing receipt data to storage", ^{
    NSError *storageError = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorageRoute setValue:OCMOCK_ANY forKey:OCMOCK_ANY serviceName:@"foo"
                                     error:[OCMArg setTo:storageError]]);

    NSData *receiptData = [@"Receipt Data" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    BOOL success = [receiptDataCache storeReceiptData:receiptData applicationBundleID:@"foo"
                                                error:&error];

    expect(success).to.beFalsy();
    expect(error).to.equal(storageError);
  });
});

SpecEnd
