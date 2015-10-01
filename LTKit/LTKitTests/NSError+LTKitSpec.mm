// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSError+LTKit.h"

SpecBegin(NSError_LTKit)

static NSString * const kDescription = @"Foo Bar Baz";
static NSString * const kPath = @"/foo.txt";
static NSURL * const kURL = [NSURL URLWithString:@"http://www.lightricks.com"];

__block NSError *underlyingError;
__block NSArray *underlyingErrors;

beforeEach(^{
  underlyingError = [NSError lt_errorWithCode:LTErrorCodeFileNotFound];
  underlyingErrors = @[
    [NSError lt_errorWithCode:LTErrorCodeFileNotFound],
    [NSError lt_errorWithCode:LTErrorCodeFileAlreadyExists]
  ];
});

it(@"should create error with code and domain", ^{
  NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodeFileNotFound);
  expect(error.userInfo.count).to.equal(0);
});

it(@"should create error with code and userInfo", ^{
  NSDictionary *userInfo = @{@"foo": @7};
  NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound userInfo:userInfo];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodeFileNotFound);
  expect(error.userInfo).to.equal(userInfo);
});

it(@"should create error with underlyingError", ^{
  NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound
                             underlyingError:underlyingError];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodeFileNotFound);
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

it(@"should create error with underlyingErrors", ^{
  NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound
                             underlyingErrors:underlyingErrors];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodeFileNotFound);
  expect(error.lt_underlyingErrors).to.equal(underlyingErrors);
});

it(@"should create error with description", ^{
  NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound description:kDescription];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodeFileNotFound);
  expect(error.lt_description).to.equal(kDescription);
});

it(@"should create error with path", ^{
  NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound path:kPath];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodeFileNotFound);
  expect(error.lt_path).to.equal(kPath);
});

it(@"should create error with path and underlyingError", ^{
  NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound path:kPath
                             underlyingError:underlyingError];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodeFileNotFound);
  expect(error.lt_path).to.equal(kPath);
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

it(@"should create error with url", ^{
  NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound url:kURL];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodeFileNotFound);
  expect(error.lt_url).to.equal(kURL);
});

it(@"should create error with url and underlyingError", ^{
  NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound url:kURL
                             underlyingError:underlyingError];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodeFileNotFound);
  expect(error.lt_url).to.equal(kURL);
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

it(@"should create error with system error", ^{
  errno = ENODEV;
  NSError *error = [NSError lt_errorWithSystemError];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodePOSIX);
  expect(error.lt_systemError).to.equal(@(ENODEV));
  expect(error.lt_systemErrorMessage.length).to.beGreaterThan(0);
});

it(@"should create error with system error even if there's no error", ^{
  errno = 0;
  NSError *error = [NSError lt_errorWithSystemError];

  expect(error.domain).to.equal(kLTErrorDomain);
  expect(error.code).to.equal(LTErrorCodePOSIX);
  expect(error.lt_systemError).to.equal(@(0));
  expect(error.lt_systemErrorMessage.length).to.beGreaterThan(0);
});

SpecEnd
