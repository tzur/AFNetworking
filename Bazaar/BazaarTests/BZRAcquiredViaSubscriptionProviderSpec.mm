// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAcquiredViaSubscriptionProvider.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRAcquiredViaSubscriptionProvider)

__block BZRKeychainStorage *keychainStorage;
__block BZRAcquiredViaSubscriptionProvider *provider;

beforeEach(^{
  keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  provider = [[BZRAcquiredViaSubscriptionProvider alloc] initWithKeychainStorage:keychainStorage];
});

context(@"initialization", ^{
  it(@"should load acquired products set on initialization", ^{
    OCMExpect([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn([NSSet setWithObject:@"foo"]);
    provider = [[BZRAcquiredViaSubscriptionProvider alloc] initWithKeychainStorage:keychainStorage];

    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet setWithObject:@"foo"]);
    OCMVerifyAll(keychainStorage);
  });
});

context(@"loading from storage", ^{
  it(@"should return empty set if the storage is empty", ^{
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]);

    NSSet<NSString *> *productsAcquiredViaSubscription =
        [provider refreshProductsAcquiredViaSubscription:nil];

    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet set]);
    expect(productsAcquiredViaSubscription).to.equal([NSSet set]);
  });

  it(@"should update acquired products after loading from cache", ^{
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn([NSSet setWithObject:@"foo"]);

    NSSet<NSString *> *productsAcquiredViaSubscription =
        [provider refreshProductsAcquiredViaSubscription:nil];

    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet setWithObject:@"foo"]);
    expect(productsAcquiredViaSubscription).to.equal(provider.productsAcquiredViaSubscription);
  });

  it(@"should return nil if failed to read from storage", ^{
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
                                    error:[OCMArg setTo:[NSError lt_errorWithCode:1337]]]);

    NSSet<NSString *> *productsAcquiredViaSubscription =
        [provider refreshProductsAcquiredViaSubscription:nil];

    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet set]);
    expect(productsAcquiredViaSubscription).to.beNil();
  });

  it(@"should not modify acquired products set if failed to read from storage", ^{
    OCMExpect([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn([NSSet setWithObject:@"foo"]);
    [provider refreshProductsAcquiredViaSubscription:nil];

    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
                                    error:[OCMArg setTo:[NSError lt_errorWithCode:1337]]]);

    [provider refreshProductsAcquiredViaSubscription:nil];

    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet setWithObject:@"foo"]);
  });
});

context(@"KVO compliance", ^{
  it(@"should notify the observer when acquired products set changes", ^{
    LLSignalTestRecorder *recorder =
        [RACObserve(provider, productsAcquiredViaSubscription) testRecorder];

    NSSet<NSString *> *acquiredProducts = [NSSet setWithObject:@"foo"];
    OCMStub([keychainStorage valueOfClass:[NSSet class] forKey:OCMOCK_ANY
                                    error:[OCMArg anyObjectRef]]).andReturn(acquiredProducts);

    [provider refreshProductsAcquiredViaSubscription:nil];

    expect(recorder).to.sendValues(@[[NSSet set], acquiredProducts]);
  });
});

context(@"adding acquired via subscription product", ^{
  it(@"should add acquired via subscription product identifier and save set to storage", ^{
    NSSet *expectedSet = [NSSet setWithArray:@[@"bar", @"foo"]];
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn([NSSet setWithObject:@"bar"]);
    OCMExpect([keychainStorage setValue:expectedSet forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]]);
    [provider refreshProductsAcquiredViaSubscription:nil];

    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet setWithObject:@"bar"]);
    [provider addAcquiredViaSubscriptionProduct:@"foo"];
    expect(provider.productsAcquiredViaSubscription).to.equal(expectedSet);

    OCMVerifyAll(keychainStorage);
  });

  it(@"should add acquired via subscription product identifiers and save set to storage", ^{
    NSSet *expectedSet = [NSSet setWithArray:@[@"bar", @"foo", @"baz"]];
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn([NSSet setWithObject:@"bar"]);
    OCMExpect([keychainStorage setValue:expectedSet forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]]);
    [provider refreshProductsAcquiredViaSubscription:nil];

    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet setWithObject:@"bar"]);
    [provider addAcquiredViaSubscriptionProducts:[NSSet setWithArray:@[@"foo", @"baz"]]];
    expect(provider.productsAcquiredViaSubscription).to.equal(expectedSet);

    OCMVerifyAll(keychainStorage);
  });
});

context(@"removing acquired via subscription product", ^{
  it(@"should remove acquired via subscription identifier and save set to storage", ^{
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn([NSSet setWithObject:@"foo"]);
    [provider refreshProductsAcquiredViaSubscription:nil];
    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet setWithObject:@"foo"]);

    OCMExpect([keychainStorage setValue:[NSSet set] forKey:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

    [provider removeAcquiredViaSubscriptionProduct:@"foo"];

    expect(provider.productsAcquiredViaSubscription).to.equal([NSSet set]);
    OCMVerifyAll(keychainStorage);
  });
});

SpecEnd
