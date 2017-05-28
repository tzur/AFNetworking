// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSError+Laboratory.h"

SpecBegin(NSError_Laboratory)

__block NSError *underlyingError;

beforeEach(^{
  underlyingError = [NSError lt_errorWithCode:1338];
});

it(@"should create an error with an associated experiment", ^{
  NSError *error = [NSError lab_errorWithCode:1337 associatedExperiment:@"MyExperiment"];

  expect(error.code).to.equal(1337);
  expect(error.lab_associatedExperiment).to.equal(@"MyExperiment");
});

it(@"should create an error with an associated experiment and underlying error", ^{
  NSError *error = [NSError lab_errorWithCode:1337 associatedExperiment:@"MyExperiment"
                              underlyingError:underlyingError];

  expect(error.code).to.equal(1337);
  expect(error.lab_associatedExperiment).to.equal(@"MyExperiment");
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

it(@"should create an error with an associated variant", ^{
  NSError *error = [NSError lab_errorWithCode:1337 associatedVariant:@"MyVariant"];

  expect(error.code).to.equal(1337);
  expect(error.lab_associatedVariant).to.equal(@"MyVariant");
});

it(@"should create an error with an associated variant and underlying error", ^{
  NSError *error = [NSError lab_errorWithCode:1337 associatedVariant:@"MyVariant"
                              underlyingError:underlyingError];

  expect(error.code).to.equal(1337);
  expect(error.lab_associatedVariant).to.equal(@"MyVariant");
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

it(@"should create an error with an asociated assignment key", ^{
  NSError *error = [NSError lab_errorWithCode:1337 associatedAssignmentKey:@"MyKey"];

  expect(error.code).to.equal(1337);
  expect(error.lab_associatedAssignmentKey).to.equal(@"MyKey");
});

it(@"should create an error with an associated experiment and associated variant", ^{
  NSError *error = [NSError lab_errorWithCode:1337 associatedExperiment:@"MyExperiment"
                            associatedVariant:@"MyVariant"];

  expect(error.code).to.equal(1337);
  expect(error.lab_associatedExperiment).to.equal(@"MyExperiment");
  expect(error.lab_associatedVariant).to.equal(@"MyVariant");
});

it(@"should create an error with associated experiment, variant and underlying error", ^{
  NSError *error = [NSError lab_errorWithCode:1337 associatedExperiment:@"MyExperiment"
                            associatedVariant:@"MyVariant" underlyingError:underlyingError];

  expect(error.code).to.equal(1337);
  expect(error.lab_associatedExperiment).to.equal(@"MyExperiment");
  expect(error.lab_associatedVariant).to.equal(@"MyVariant");
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

SpecEnd
