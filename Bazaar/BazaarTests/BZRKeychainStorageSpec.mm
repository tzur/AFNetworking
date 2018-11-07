// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRKeychainStorage.h"

#import <UICKeyChainStore/UICKeyChainStore.h>

#import "BZREvent.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRKeychainStorage)

__block UICKeyChainStore *keychainStore;

beforeEach(^{
  keychainStore = OCMClassMock([UICKeyChainStore class]);
});

context(@"initialization", ^{
  it(@"should initialize with keychain handler", ^{
    BZRKeychainStorage *keychainStorage =
        [[BZRKeychainStorage alloc] initWithKeychainStore:keychainStore];
    expect(keychainStorage).toNot.beNil();
  });
});

context(@"keychain storage", ^{
  __block BZRKeychainStorage *secureStorage;

  beforeEach(^{
    secureStorage = [[BZRKeychainStorage alloc] initWithKeychainStore:keychainStore];
  });

  it(@"should store values correctly", ^{
    NSString *key = @"key";
    NSString *value = @"value";
    NSData *archivedValue = [NSKeyedArchiver archivedDataWithRootObject:value];
    OCMExpect([keychainStore setData:archivedValue forKey:key error:[OCMArg anyObjectRef]])
        .andReturn(YES);

    NSError *error;
    BOOL success = [secureStorage setValue:value forKey:key error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll(keychainStore);
  });

  it(@"should read values correctly", ^{
    NSString *key = @"key";
    NSString *value = @"value";
    OCMStub([keychainStore dataForKey:key error:[OCMArg anyObjectRef]])
        .andReturn([NSKeyedArchiver archivedDataWithRootObject:value]);
    NSError *error;
    id<NSSecureCoding> storedValue = [secureStorage valueForKey:key error:&error];
    expect(storedValue).to.equal(value);
    expect(error).to.beNil();
  });

  it(@"should allow nil value", ^{
    NSString *key = @"foo";
    OCMExpect([keychainStore setData:nil forKey:key error:[OCMArg anyObjectRef]])
        .andReturn(YES);

    NSError *error;
    BOOL success = [secureStorage setValue:nil forKey:key error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll(keychainStore);
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
    OCMStub([keychainStore dataForKey:[OCMArg any] error:[OCMArg setTo:underlyingError]]);

    NSError *error;
    id value = [secureStorage valueForKey:@"key" error:&error];

    expect(value).to.beNil();
    expect(error.code).to.equal(BZRErrorCodeLoadingFromKeychainStorageFailed);
    expect(error.lt_underlyingError).to.equal(underlyingError);
  });

  it(@"should send error event when read failed", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    OCMStub([keychainStore dataForKey:[OCMArg any] error:[OCMArg setTo:underlyingError]]);

    NSError *error;
    auto recorder = [secureStorage.eventsSignal testRecorder];
    [secureStorage valueForKey:@"key" error:&error];

    expect(recorder).to.matchValue(0, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] && event.eventError == error;
    });
  });

  it(@"should proxy write errors correctly", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    OCMStub([keychainStore setData:OCMOCK_ANY forKey:OCMOCK_ANY
                               error:[OCMArg setTo:underlyingError]]);

    NSError *error;
    BOOL success = [secureStorage setValue:@"value" forKey:@"key" error:&error];

    expect(success).to.beFalsy();
    expect(error.code).to.equal(BZRErrorCodeStoringToKeychainStorageFailed);
    expect(error.lt_underlyingError).to.equal(underlyingError);
  });

  it(@"should send error event when write failed", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    OCMStub([keychainStore setData:OCMOCK_ANY forKey:OCMOCK_ANY
                               error:[OCMArg setTo:underlyingError]]);

    NSError *error;
    auto recorder = [secureStorage.eventsSignal testRecorder];
    [secureStorage setValue:@"value" forKey:@"key" error:&error];

    expect(recorder).to.matchValue(0, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] && event.eventError == error;
    });
  });

  it(@"should return nil and err for values not archived appropriately", ^{
    NSString *key = @"key";
    OCMStub([keychainStore dataForKey:key error:[OCMArg anyObjectRef]])
        .andReturn([@"foo" dataUsingEncoding:NSUTF8StringEncoding]);
    NSError *error;
    id<NSSecureCoding> storedValue = [secureStorage valueForKey:key error:&error];
    expect(storedValue).to.beNil();
    expect(error.code).to.equal(BZRErrorCodeKeychainStorageArchivingError);
  });

  pending(@"should return nil and err for invalid archive data");
});

context(@"shared keychain access group", ^{
  context(@"application identifier prefix is defined", ^{
    static NSString * const kAppIdentifierPrefix = @"ABC123";

    __block NSBundle *mainBundle;

    beforeEach(^{
      mainBundle = OCMPartialMock([NSBundle mainBundle]);
      OCMStub([mainBundle objectForInfoDictionaryKey:@"AppIdentifierPrefix"])
          .andReturn(kAppIdentifierPrefix);
    });

    afterEach(^{
      mainBundle = nil;
    });

    it(@"should prepend the application identifier prefix", ^{
      NSString *accessGroup = @"com.lightricks.storage";
      NSString *sharedAccessGroup =
          [BZRKeychainStorage accessGroupWithAppIdentifierPrefix:accessGroup];

      expect(sharedAccessGroup).to
          .equal([kAppIdentifierPrefix stringByAppendingString:accessGroup]);
    });

    it(@"should return the default shared access group", ^{
      expect([BZRKeychainStorage defaultSharedAccessGroup]).toNot.beNil();
    });
  });

  context(@"application identifier prefix is not defined", ^{
    it(@"should return nil instead of the shared access group", ^{
      NSString *accessGroup = @"com.lightricks.storage";
      NSString *sharedAccessGroup =
          [BZRKeychainStorage accessGroupWithAppIdentifierPrefix:accessGroup];

      expect(sharedAccessGroup).to.beNil();
    });

    it(@"should raise an exception when try to get the default shared access group", ^{
      expect(^{
        [BZRKeychainStorage defaultSharedAccessGroup];
      }).to.raise(NSInternalInconsistencyException);
    });
  });
});

SpecEnd
