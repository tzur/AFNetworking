// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRKeychainStorage+TypeSafety.h"

#import <UICKeyChainStore/UICKeyChainStore.h>

#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRKeychainStorage_TypeSafety)

__block NSString *key;
__block UICKeyChainStore *keychainStore;
__block BZRKeychainStorage *keychainStorage;

beforeEach(^{
  key = @"foo";
  keychainStore = OCMClassMock([UICKeyChainStore class]);;
  keychainStorage =
      OCMPartialMock([[BZRKeychainStorage alloc] initWithKeychainStore:keychainStore]);
});

context(@"loading values from storage", ^{
  it(@"should return nil and set error when value for key fails", ^{
    NSError *storageError = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorage valueForKey:OCMOCK_ANY error:[OCMArg setTo:storageError]]);

    NSError *error;
    NSArray *array = [keychainStorage valueOfClass:[NSArray class] forKey:key error:&error];

    expect(array).to.beNil();
    expect(error).to.equal(storageError);
  });

  it(@"should return nil and set error when class loaded from storage is not of the right type", ^{
    NSObject *object = OCMClassMock([NSObject class]);
    OCMStub([keychainStorage valueForKey:OCMOCK_ANY error:[OCMArg anyObjectRef]]).andReturn(object);

    NSError *error;
    NSArray *array = [keychainStorage valueOfClass:[NSArray class] forKey:key error:&error];

    expect(array).to.beNil();
    expect(error.lt_isLTDomain).to.beTruthy();
    expect(error.code).to.equal(BZRErrorCodeLoadingFromKeychainStorageFailed);
  });

  it(@"should return nil without setting error if no value is stored for the specified key", ^{
    NSError *error;
    NSArray *array = [keychainStorage valueOfClass:[NSArray class] forKey:key error:&error];

    expect(array).to.beNil();
    expect(error).to.beNil();
  });

  it(@"should return value returned from underlying value for key when no error occurred", ^{
    NSArray *expectedArray = OCMClassMock([NSArray class]);
    OCMStub([keychainStorage valueForKey:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn(expectedArray);

    NSError *error;
    NSArray *array = [keychainStorage valueOfClass:[NSArray class] forKey:key error:&error];

    expect(array).to.equal(expectedArray);
    expect(error).to.beNil();
  });
});

SpecEnd
