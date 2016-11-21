// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "NSString+Bazaar.h"

SpecBegin(NSString_Bazaar)

context(@"variant for product identifier", ^{
  it(@"should concatenate identifier with variant suffix", ^{
    NSString *identifier = @"foo";
    expect([identifier bzr_variantWithSuffix:@"bar"]).to.equal(@"foo.Variant.bar");
  });
});

context(@"base product identifier", ^{
  it(@"should return the receiver if variant suffix was not found", ^{
    NSString *identifier = @"foo.Var";
    expect([identifier bzr_baseProductIdentifier]).to.equal(identifier);
  });

  it(@"should return correct base identifier", ^{
    NSString *identifier = @"foo.Variant.bar";
    expect([identifier bzr_baseProductIdentifier]).to.equal(@"foo");
  });
});

SpecEnd
