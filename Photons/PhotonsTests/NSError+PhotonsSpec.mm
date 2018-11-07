// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSError+Photons.h"

SpecBegin(NSError_Photons)

__block id<PTNDescriptor> descriptor;
__block NSError *underlyingError;

beforeEach(^{
  descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
  underlyingError = [NSError lt_errorWithCode:1338];
});

it(@"should create an error with an associated descriptor", ^{
  NSError *error = [NSError ptn_errorWithCode:1337 associatedDescriptor:descriptor];

  expect(error.code).to.equal(1337);
  expect(error.ptn_associatedDescriptor).to.equal(descriptor);
});

it(@"should create an error with associated descriptors", ^{
  NSError *error = [NSError ptn_errorWithCode:1337 associatedDescriptors:@[descriptor, descriptor]];

  expect(error.code).to.equal(1337);
  expect(error.ptn_associatedDescriptors).to.equal(@[descriptor, descriptor]);
});

it(@"should create an error with an associated descriptor and underlying error", ^{
  NSError *error = [NSError ptn_errorWithCode:1337 associatedDescriptor:descriptor
                              underlyingError:underlyingError];

  expect(error.code).to.equal(1337);
  expect(error.ptn_associatedDescriptor).to.equal(descriptor);
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

it(@"should create an error with associated descriptors and underlying error", ^{
  NSError *error = [NSError ptn_errorWithCode:1337 associatedDescriptors:@[descriptor, descriptor]
                              underlyingError:underlyingError];

  expect(error.code).to.equal(1337);
  expect(error.ptn_associatedDescriptors).to.equal(@[descriptor, descriptor]);
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

it(@"should create an error with an associated descriptor and description", ^{
  NSError *error = [NSError ptn_errorWithCode:1337 associatedDescriptor:descriptor
                                  description:@"foo"];

  expect(error.code).to.equal(1337);
  expect(error.ptn_associatedDescriptor).to.equal(descriptor);
  expect(error.lt_description).to.equal(@"foo");
});

it(@"should create an error with associated descriptors and description", ^{
  NSError *error = [NSError ptn_errorWithCode:1337 associatedDescriptors:@[descriptor, descriptor]
                                  description:@"foo"];

  expect(error.code).to.equal(1337);
  expect(error.ptn_associatedDescriptors).to.equal(@[descriptor, descriptor]);
  expect(error.lt_description).to.equal(@"foo");
});

SpecEnd
