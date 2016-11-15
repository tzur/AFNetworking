// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRKeychainStorage.h"

#import "BZRKeychainHandler.h"
#import "NSErrorCodes+Bazaar.h"

/// Fake handler that provides empty implementations to \c BZRKeychainHandler's methods.
@interface BZRFakeKeychainHandler : NSObject <BZRKeychainHandler>
@end

@implementation BZRFakeKeychainHandler

- (nullable NSData *)dataForKey:(NSString __unused *)key
                          error:(NSError * __unused __autoreleasing *)error {
  return nil;
}

- (BOOL)setData:(nullable NSData __unused *)data forKey:(NSString __unused *)key
          error:(NSError * __unused __autoreleasing *)error {
  return NO;
}

/// Bazaar namespace error for the given underlying class error.
+ (NSError *)errorForUnderlyingError:(NSError *)underlyingError {
  return underlyingError;
}

@end

SpecBegin(BZRKeychainStorage)

__block id<BZRKeychainHandler> keychainHandler;

beforeEach(^{
  keychainHandler = OCMClassMock([BZRFakeKeychainHandler class]);
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
    NSData *archivedValue = [NSKeyedArchiver archivedDataWithRootObject:value];
    OCMExpect([keychainHandler setData:archivedValue forKey:key error:[OCMArg anyObjectRef]])
        .andReturn(YES);

    NSError *error;
    BOOL success = [secureStorage setValue:value forKey:key error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll((id)keychainHandler);
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
    NSString *key = @"foo";
    OCMExpect([keychainHandler setData:nil forKey:key error:[OCMArg anyObjectRef]])
        .andReturn(YES);

    NSError *error;
    BOOL success = [secureStorage setValue:nil forKey:key error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll((id)keychainHandler);
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
    id value = [secureStorage valueForKey:@"key" error:&error];

    expect(value).to.beNil();
    expect(error).to.equal(bazaarError);
  });
  
  it(@"should proxy write errors correctly", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    NSError *bazaarError = OCMClassMock([NSError class]);
    OCMStub([keychainHandler setData:OCMOCK_ANY forKey:OCMOCK_ANY
                               error:[OCMArg setTo:underlyingError]]);
    OCMStub([keychainHandler errorForUnderlyingError:underlyingError]).andReturn(bazaarError);

    NSError *error;
    BOOL success = [secureStorage setValue:@"value" forKey:@"key" error:&error];

    expect(success).to.beFalsy();
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
