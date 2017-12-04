// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAppStoreLocaleCache.h"

#import "BZRKeychainStorageRoute.h"

SpecBegin(BZRAppStoreLocaleCache)

__block BZRKeychainStorageRoute *keychainStorageRoute;
__block NSString *currentApplicationBundleID;
__block BZRAppStoreLocaleCache *appStoreLocaleCache;

beforeEach(^{
  keychainStorageRoute = OCMClassMock([BZRKeychainStorageRoute class]);
  currentApplicationBundleID = @"foo";
  appStoreLocaleCache =
      [[BZRAppStoreLocaleCache alloc] initWithKeychainStorageRoute:keychainStorageRoute];
});

context(@"retrieving App Store locale from storage", ^{
  it(@"should use keychain storage route to retrieve locale from storage", ^{
    NSLocale *expectedLocale = [NSLocale currentLocale];
    OCMStub([keychainStorageRoute valueForKey:OCMOCK_ANY serviceName:@"bar" error:nil])
        .andReturn(expectedLocale.localeIdentifier);

    auto appStoreLocale = [appStoreLocaleCache appStoreLocaleForBundleID:@"bar" error:nil];

    expect(appStoreLocale.localeIdentifier).to.equal(expectedLocale.localeIdentifier);
  });

  it(@"should return error in case keychain storage route returned error", ^{
    NSError *storageError = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorageRoute valueForKey:OCMOCK_ANY serviceName:@"bar"
                                        error:[OCMArg setTo:storageError]]);

    NSError *error;
    auto appStoreLocale = [appStoreLocaleCache appStoreLocaleForBundleID:@"bar" error:&error];

    expect(appStoreLocale).to.beNil();
    expect(error).to.equal(storageError);
  });
});

context(@"writing App Store locale to storage", ^{
  it(@"should return YES if storing App Store locale to storage was successful", ^{
    OCMStub([keychainStorageRoute setValue:[NSLocale currentLocale].localeIdentifier
                                    forKey:OCMOCK_ANY serviceName:@"foo"
                                     error:[OCMArg anyObjectRef]]).andReturn(YES);

    NSError *error;
    BOOL success = [appStoreLocaleCache storeAppStoreLocale:[NSLocale currentLocale]
                                                   bundleID:currentApplicationBundleID
                                                      error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
  });

  it(@"should return NO and populate error when an error occurred", ^{
    NSError *error;
    NSError *storageError = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorageRoute setValue:[NSLocale currentLocale].localeIdentifier
                                    forKey:OCMOCK_ANY serviceName:@"foo"
                                     error:[OCMArg setTo:storageError]]);

    BOOL success = [appStoreLocaleCache storeAppStoreLocale:[NSLocale currentLocale]
                                                   bundleID:currentApplicationBundleID
                                                      error:&error];

    expect(success).to.beFalsy();
    expect(error).to.equal(storageError);
  });
});

SpecEnd
