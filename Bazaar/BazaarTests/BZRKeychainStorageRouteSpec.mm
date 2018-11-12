// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRKeychainStorageRoute.h"

#import "BZRKeychainStorage.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRKeychainStorageRoute)

__block BZRKeychainStorage *keychainStorageWithDefaultService;
__block NSString *customServiceName;
__block BZRKeychainStorage *keychainStorageWithCustomService;
__block BZRKeychainStorageRoute *keychainStorageRoute;

beforeEach(^{
  keychainStorageWithDefaultService = OCMClassMock([BZRKeychainStorage class]);
  OCMStub([keychainStorageWithDefaultService service])
      .andReturn([BZRKeychainStorage defaultService]);
  keychainStorageWithCustomService = OCMClassMock([BZRKeychainStorage class]);
  customServiceName = @"foo";
  OCMStub([keychainStorageWithCustomService service]).andReturn(customServiceName);
  keychainStorageRoute = [[BZRKeychainStorageRoute alloc] initWithMultiKeychainStorage:
                          @[keychainStorageWithDefaultService, keychainStorageWithCustomService]];
});

context(@"loading data from storage", ^{
  it(@"should load value from the correct keychain storage", ^{
    NSString *key = @"foo";
    OCMStub([keychainStorageWithDefaultService valueForKey:key error:[OCMArg anyObjectRef]])
        .andReturn(@"bar");

    expect([keychainStorageRoute valueForKey:key serviceName:nil error:nil]).to.equal(@"bar");
  });

  it(@"should set error and return nil if no keychain storage with the service name was found", ^{
    NSError *error;
    id _Nullable value = [keychainStorageRoute valueForKey:@"foo" serviceName:@"baz" error:&error];

    expect(value).to.beNil();
    expect(error.code).to.equal(BZRErrorCodeServiceNameNotFound);
  });

  it(@"should set error and return nil if there was error in keychain storage", ^{
    NSError *keychainStorageError = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorageWithDefaultService valueForKey:OCMOCK_ANY
                                                     error:[OCMArg setTo:keychainStorageError]]);

    NSError *error;
    id _Nullable value = [keychainStorageRoute valueForKey:@"foo" serviceName:nil error:&error];

    expect(value).to.beNil();
    expect(error).to.equal(keychainStorageError);
  });
});

context(@"storing data to storage", ^{
  it(@"should store value to the correct keychain storage", ^{
    NSString *key = @"foo";
    OCMStub([keychainStorageWithCustomService setValue:@"bar" forKey:key
                                                 error:[OCMArg anyObjectRef]]).andReturn(YES);

    NSError *error;
    BOOL success = [keychainStorageRoute setValue:@"bar" forKey:key serviceName:customServiceName
                                            error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll(keychainStorageWithCustomService);
  });

  it(@"should set error and return NO if no keychain storage with the service name was found", ^{
    NSError *error;
    BOOL success =
        [keychainStorageRoute setValue:@"bar" forKey:@"foo" serviceName:@"baz" error:&error];

    expect(success).to.beFalsy();
    expect(error.code).to.equal(BZRErrorCodeServiceNameNotFound);
  });

  it(@"should set error and return NO if there was error in keychain storage", ^{
    NSError *keychainStorageError = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorageWithCustomService setValue:OCMOCK_ANY forKey:OCMOCK_ANY
                                      error:[OCMArg setTo:keychainStorageError]]).andReturn(NO);

    NSError *error;
    BOOL success = [keychainStorageRoute setValue:@"bar" forKey:@"foo" serviceName:customServiceName
                                            error:&error];

    expect(success).to.equal(NO);
    expect(error).to.equal(keychainStorageError);
  });
});

SpecEnd
