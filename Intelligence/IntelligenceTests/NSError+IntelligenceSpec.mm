// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSError+Intelligence.h"

SpecBegin(NSError_Intelligence)

__block NSError *underlyingError;
__block NSData *record;

beforeEach(^{
  underlyingError = [NSError lt_errorWithCode:1338];
  record = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
});

it(@"should create an error with a json record", ^{
  NSError *error = [NSError int_errorWithCode:1337 record:record];

  expect(error.code).to.equal(1337);
  expect(error.int_record).to.equal(record);
});

it(@"should create an error with a json record and underlying error", ^{
  NSError *error = [NSError int_errorWithCode:1337 record:record underlyingError:underlyingError];

  expect(error.code).to.equal(1337);
  expect(error.int_record).to.equal(record);
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

SpecEnd
