// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "NSValueTransformer+Photons.h"

SpecBegin(NSValueTransformer_Photons)

__block NSValueTransformer *transformer;

static NSString * const kURLString = @"https://www.foo.com/bar";

beforeEach(^{
  transformer = [NSValueTransformer valueTransformerForName:kPTNURLValueTransformer];
});

afterEach(^{
  transformer = nil;
});

it(@"should initialize correctly", ^{
  expect(transformer).toNot.beNil();
});

it(@"should forward transform URLs", ^{
  NSURL *url = [transformer transformedValue:kURLString];

  expect(url.scheme).to.equal(@"https");
  expect(url.host).to.equal(@"www.foo.com");
  expect(url.path).to.equal(@"/bar");
});

it(@"should reverse transform string URLs", ^{
  NSURL *url = [NSURL URLWithString:kURLString];

  expect([transformer reverseTransformedValue:url]).to.equal(kURLString);
});

it(@"should transform nil to nil", ^{
  expect([transformer transformedValue:nil]).to.beNil();
  expect([transformer reverseTransformedValue:nil]).to.beNil();
});

it(@"should return nil for invalid forward transform attempts", ^{
  expect([transformer transformedValue:[[NSObject alloc] init]]).to.beNil();
});

it(@"should assert upon invalid reverse transform attempts", ^{
  expect(^{
    [transformer reverseTransformedValue:[[NSObject alloc] init]];
  }).to.raise(NSInvalidArgumentException);
});

SpecEnd
