// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRKeychainHandler.h"

#import "BZRKeychainStorage.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRKeychainStorage)

__block id<BZRKeychainHandler> keychainHandler;

beforeEach(^{
  keychainHandler = OCMProtocolMock(@protocol(BZRKeychainHandler));
});

context(@"initialization", ^{
  it(@"should initialize with keychain handler", ^{
    BZRKeychainStorage *keychainStorage =
      [[BZRKeychainStorage alloc] initWithKeychainHandler:keychainHandler];
    expect(keychainStorage).toNot.beNil();
  });
});

context(@"keychain storage", ^{
  __block BZRKeychainStorage *secureStorage;

  beforeEach(^{
    secureStorage = [[BZRKeychainStorage alloc] initWithKeychainHandler:keychainHandler];
  });

  it(@"should store values correctly", ^{
    NSString *key = @"key";
    NSString *value = @"value";
    NSError *error;
    [secureStorage setValue:value forKey:key error:&error];
    expect(error).to.beNil();
    OCMVerify([keychainHandler setData:[NSKeyedArchiver archivedDataWithRootObject:value]
                                forKey:key error:[OCMArg anyObjectRef]]);
  });
  
  it(@"should read values correctly", ^{
    NSString *key = @"key";
    NSString *value = @"value";
    OCMStub([keychainHandler dataForKey:key error:[OCMArg anyObjectRef]])
        .andReturn([NSKeyedArchiver archivedDataWithRootObject:value]);
    NSError *error;
    id<NSSecureCoding> storedValue = [secureStorage valueForKey:key error:&error];
    expect(storedValue).to.equal(value);
    expect(error).to.beNil();
  });

  it(@"should allow nil value", ^{
    NSError *error;
    [secureStorage setValue:nil forKey:@"someKey" error:&error];
    expect(error).to.beNil();
    OCMVerify([keychainHandler setData:nil forKey:@"someKey" error:[OCMArg anyObjectRef]]);
  });
  
  it(@"should return nil for non-existing values", ^{
    NSString *nonExistingKey = @"nonExistingKey";
    NSError *error;
    id<NSSecureCoding> storedValue = [secureStorage valueForKey:nonExistingKey error:&error];
    expect(error).to.beNil();
    expect(storedValue).to.beNil();
  });

  it(@"should proxy read errors correctly", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    NSError *bazaarError = OCMClassMock([NSError class]);
    OCMStub([keychainHandler dataForKey:[OCMArg any] error:[OCMArg setTo:underlyingError]]);
    OCMStub([keychainHandler errorForUnderlyingError:underlyingError]).andReturn(bazaarError);
    NSError *error;
    [secureStorage valueForKey:@"key" error:&error];
    expect(error).to.equal(bazaarError);
  });
  
  it(@"should proxy write errors correctly", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    NSError *bazaarError = OCMClassMock([NSError class]);
    OCMStub([keychainHandler setData:OCMOCK_ANY forKey:OCMOCK_ANY
                               error:[OCMArg setTo:underlyingError]]);
    OCMStub([keychainHandler errorForUnderlyingError:underlyingError]).andReturn(bazaarError);
    NSError *error;
    [secureStorage setValue:@"value" forKey:@"key" error:&error];
    expect(error).to.equal(bazaarError);
  });
  
  it(@"should return nil and err for values not archived appropriately", ^{
    NSString *key = @"key";
    OCMStub([keychainHandler dataForKey:key error:[OCMArg anyObjectRef]])
        .andReturn([@"foo" dataUsingEncoding:NSUTF8StringEncoding]);
    NSError *error;
    id<NSSecureCoding> storedValue = [secureStorage valueForKey:key error:&error];
    expect(storedValue).to.beNil();
    expect(error.code).to.equal(BZRErrorCodeKeychainStorageArchivingError);
  });
  
  pending(@"should return nil and err for invalid archive data");
});

SpecEnd
