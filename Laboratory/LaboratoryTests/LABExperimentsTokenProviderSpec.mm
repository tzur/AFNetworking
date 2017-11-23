// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABExperimentsTokenProvider.h"

#import <LTKit/LTRandom.h>
#import <LTKitTestUtils/LTFakeStorage.h>

SpecBegin(LABExperimentsTokenProvider)

__block LTFakeStorage *storage;
__block LTRandom *random;
__block LABExperimentsTokenProvider *provider;

beforeEach(^{
  storage = [[LTFakeStorage alloc] init];
  random = OCMClassMock(LTRandom.class);
  OCMStub([random randomDouble]).andReturn(0.3);
  provider = [[LABExperimentsTokenProvider alloc] initWithStorage:storage random:random];
});

it(@"should generate random token", ^{
  expect(provider.experimentsToken).to.equal(0.3);
});

it(@"should persist the experiments token", ^{
  random = OCMClassMock(LTRandom.class);
  OCMStub([random randomDouble]).andReturn(0.6);
  auto newProvider = [[LABExperimentsTokenProvider alloc] initWithStorage:storage random:random];
  expect(newProvider.experimentsToken).to.equal(0.3);
});

it(@"should expose new experiments token if storage has wrong data", ^{
  for (id key in storage.storage) {
    storage.storage[key] = @"foo";
  }
  random = OCMClassMock(LTRandom.class);
  OCMStub([random randomDouble]).andReturn(0.6);
  auto newProvider = [[LABExperimentsTokenProvider alloc] initWithStorage:storage random:random];
  expect(newProvider.experimentsToken).to.equal(0.6);
});

SpecEnd
