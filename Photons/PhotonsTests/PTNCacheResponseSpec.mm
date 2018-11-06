// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheResponse.h"

SpecBegin(PTNCacheResponse)

it(@"should initialize a cache response", ^{
  UIImage *image = [[UIImage alloc] init];
  NSDictionary *info = @{@"foo": @"bar"};
  PTNCacheResponse *cacheResponse = [[PTNCacheResponse alloc] initWithData:image info:info];

  expect(cacheResponse.data).to.equal(image);
  expect(cacheResponse.info).to.equal(info);
});

context(@"equality", ^{
  __block PTNCacheResponse *firstResponse;
  __block PTNCacheResponse *secondResponse;
  __block PTNCacheResponse *otherResponse;

  beforeEach(^{
    UIImage *image = [[UIImage alloc] init];
    NSDictionary *info = @{@"foo": @"bar"};

    firstResponse = [[PTNCacheResponse alloc] initWithData:image info:info];
    secondResponse = [[PTNCacheResponse alloc] initWithData:image info:info];
    otherResponse = [[PTNCacheResponse alloc] initWithData:[[UIImage alloc] init] info:@{}];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstResponse).to.equal(secondResponse);
    expect(secondResponse).to.equal(firstResponse);

    expect(firstResponse).notTo.equal(otherResponse);
    expect(secondResponse).notTo.equal(otherResponse);
  });

  it(@"should create proper hash", ^{
    expect(firstResponse.hash).to.equal(secondResponse.hash);
  });
});

SpecEnd
