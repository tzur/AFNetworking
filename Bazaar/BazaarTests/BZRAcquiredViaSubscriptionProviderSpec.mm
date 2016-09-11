// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAcquiredViaSubscriptionProvider.h"

#import "BZRKeychainStorage+TypeSafety.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRAcquiredViaSubscriptionProvider)

__block BZRKeychainStorage *keychainStorage;
__block BZRAcquiredViaSubscriptionProvider *provider;

beforeEach(^{
  keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  provider = [[BZRAcquiredViaSubscriptionProvider alloc] initWithKeychainStorage:keychainStorage];
});

context(@"loading from storage", ^{
  it(@"should treat nil from storage as empty set", ^{
    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet set]);
  });

  it(@"should determine set according to set from storage", ^{
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn([NSSet setWithObject:@"foo"]);

    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet setWithObject:@"foo"]);
  });
});

context(@"adding acquired via subscription product", ^{
  it(@"should add acquired via subscription identifier and save set to storage", ^{
    NSSet *expectedSet = [NSSet setWithArray:@[@"bar", @"foo"]];
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn([NSSet setWithObject:@"bar"]);
    OCMExpect([keychainStorage setValue:expectedSet forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

    [provider addAcquiredViaSubscriptionProduct:@"foo"];
    expect(provider.productsAcquiredViaSubscription).to.equal(expectedSet);

    OCMVerifyAll((id)keychainStorage);
  });
});

context(@"removing acquired via subscription product", ^{
  it(@"should remove acquired via subscription identifier and save set to storage", ^{
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn([NSSet setWithObject:@"foo"]);
    OCMExpect([keychainStorage setValue:[NSSet set] forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

    [provider removeAcquiredViaSubscriptionProduct:@"foo"];

    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet set]);
    OCMVerifyAll((id)keychainStorage);
  });
});

context(@"storage errors", ^{
  it(@"should return empty set if failed to read from storage", ^{
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg setTo:error]]);

    LLSignalTestRecorder *recorder = [provider.storageErrorsSignal testRecorder];

    expect([provider.productsAcquiredViaSubscription count]).to.equal(0);
    expect(recorder).will.sendValue(0, error);
  });

  it(@"should send storage error when saving set to storage has failed", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    OCMStub([keychainStorage setValue:OCMOCK_ANY forKey:OCMOCK_ANY
                                error:[OCMArg setTo:underlyingError]]);
    LLSignalTestRecorder *recorder = [provider.storageErrorsSignal testRecorder];

    [provider addAcquiredViaSubscriptionProduct:@"foo"];

    expect(recorder).will.matchValue(0, ^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeStoringDataToStorageFailed &&
          error.lt_underlyingError == underlyingError;
    });
  });
});

SpecEnd
