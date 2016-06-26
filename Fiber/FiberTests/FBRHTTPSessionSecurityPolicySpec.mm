// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPSessionSecurityPolicy.h"

SpecBegin(FBRHTTPSessionSecurityPolicy)

context(@"standard security policy", ^{
  it(@"should create a security policy with the standard validation mode", ^{
    FBRHTTPSessionSecurityPolicy *policy = [FBRHTTPSessionSecurityPolicy standardSecurityPolicy];

    expect(policy.validationMode).to.equal(FBRCertificateValidationModeStandard);
    expect(policy.pinnedCertificates).to.beNil();
  });
});

context(@"certificate pinning security policy", ^{
  __block NSSet<NSData *> *certificates;

  beforeEach(^{
    certificates = [NSSet setWithObjects:[@"Foo" dataUsingEncoding:NSUTF8StringEncoding],
                    [@"Bar" dataUsingEncoding:NSUTF8StringEncoding], nil];
  });

  it(@"should create a security policy with pinned certificate validation", ^{
    FBRHTTPSessionSecurityPolicy *policy =
        [FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedCertificates:certificates];

    expect(policy.validationMode).to.equal(FBRCertificateValidationModePinnedCertificates);
    expect(policy.pinnedCertificates).to.equal(certificates);
  });

  it(@"should copy the set of pinned certificate upon initialization", ^{
    NSMutableSet *mutableCertificates = [certificates mutableCopy];
    FBRHTTPSessionSecurityPolicy *policy =
        [FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedCertificates:mutableCertificates];
    [mutableCertificates addObject:[@"Baz" dataUsingEncoding:NSUTF8StringEncoding]];

    expect(policy.pinnedCertificates).to.equal(certificates);
  });
});

context(@"public key pinning security policy", ^{
  __block NSSet<NSData *> *certificates;

  beforeEach(^{
    certificates = [NSSet setWithObjects:[@"Foo" dataUsingEncoding:NSUTF8StringEncoding],
                    [@"Bar" dataUsingEncoding:NSUTF8StringEncoding], nil];
  });

  it(@"should create a security policy with pinned public keys validation", ^{
    FBRHTTPSessionSecurityPolicy *policy =
        [FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedPublicKeysFromCertificates:
         certificates];

    expect(policy.validationMode).to.equal(FBRCertificateValidationModePinnedPublicKeys);
    expect(policy.pinnedCertificates).to.equal(certificates);
  });

  it(@"should copy the set of pinned certificate upon initialization", ^{
    NSMutableSet *mutableCertificates = [certificates mutableCopy];
    FBRHTTPSessionSecurityPolicy *policy =
        [FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedPublicKeysFromCertificates:
         mutableCertificates];
    [mutableCertificates addObject:[@"Baz" dataUsingEncoding:NSUTF8StringEncoding]];

    expect(policy.pinnedCertificates).to.equal(certificates);
  });
});

context(@"equality", ^{
  it(@"should inidcate that two identical objects are equal", ^{
    FBRHTTPSessionSecurityPolicy *securityPolicy =
        [FBRHTTPSessionSecurityPolicy standardSecurityPolicy];
    FBRHTTPSessionSecurityPolicy *anotherSecurityPolicy =
        [FBRHTTPSessionSecurityPolicy standardSecurityPolicy];

    expect([securityPolicy isEqual:anotherSecurityPolicy]).to.beTruthy();
  });

  it(@"should return the same hash for identical objects", ^{
    FBRHTTPSessionSecurityPolicy *securityPolicy =
        [FBRHTTPSessionSecurityPolicy standardSecurityPolicy];
    FBRHTTPSessionSecurityPolicy *anotherSecurityPolicy =
        [FBRHTTPSessionSecurityPolicy standardSecurityPolicy];

    expect(securityPolicy.hash).to.equal(anotherSecurityPolicy.hash);
  });

  it(@"should indicate that two non identical objects are not equal", ^{
    FBRHTTPSessionSecurityPolicy *securityPolicy =
        [FBRHTTPSessionSecurityPolicy standardSecurityPolicy];
    FBRHTTPSessionSecurityPolicy *anotherSecurityPolicy =
        [FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedCertificates:[NSSet set]];

    expect([securityPolicy isEqual:anotherSecurityPolicy]).to.beFalsy();
  });
});

SpecEnd
