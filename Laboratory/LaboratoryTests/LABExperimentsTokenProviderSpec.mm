// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABExperimentsTokenProvider.h"

#import <LTKit/LTRandom.h>

#import "LABFakeStorage.h"

SpecBegin(LABExperimentsTokenProvider)

__block LABFakeStorage *storage;
__block LTRandom *random;
__block LABExperimentsTokenProvider *provider;

beforeEach(^{
  storage = [[LABFakeStorage alloc] init];
  random = OCMClassMock(LTRandom.class);
});

it(@"should generate random token", ^{
  OCMStub([random randomDouble]).andReturn(0.3);
  provider = [[LABExperimentsTokenProvider alloc] initWithStorage:storage random:random];
  expect(provider.experimentsToken).to.equal(0.3);
});

it(@"should persist the experiments token", ^{
  OCMStub([random randomDouble]).andReturn(0.3);
  provider = [[LABExperimentsTokenProvider alloc] initWithStorage:storage random:random];
  random = OCMClassMock(LTRandom.class);
  OCMStub([random randomDouble]).andReturn(0.6);
  expect(provider.experimentsToken).to.equal(0.3);
});

it(@"should expose new experiments token if storage is empty", ^{
  OCMStub([random randomDouble]).andReturn(0.3);
  provider = [[LABExperimentsTokenProvider alloc] initWithStorage:storage random:random];
  storage = [[LABFakeStorage alloc] init];
  random = OCMClassMock(LTRandom.class);
  OCMStub([random randomDouble]).andReturn(0.6);
  provider = [[LABExperimentsTokenProvider alloc] initWithStorage:storage random:random];
  expect(provider.experimentsToken).to.equal(0.6);
});

it(@"should expose new experiments token if storage is has wront data", ^{
  OCMStub([random randomDouble]).andReturn(0.3);
  provider = [[LABExperimentsTokenProvider alloc] initWithStorage:storage random:random];
  for (id key in storage.storage) {
    storage.storage[key] = @"foo";
  }
  random = OCMClassMock(LTRandom.class);
  OCMStub([random randomDouble]).andReturn(0.6);
  provider = [[LABExperimentsTokenProvider alloc] initWithStorage:storage random:random];
  expect(provider.experimentsToken).to.equal(0.6);
});

it(@"should expose new experiments token if storage is has wront data", ^{
  for (id key in storage.storage) {
    storage.storage[key] = @"foo";
  }
  random = OCMClassMock(LTRandom.class);
  OCMStub([random randomDouble]).andReturn(0.6);
  provider = [[LABExperimentsTokenProvider alloc] initWithStorage:storage random:random];
  expect(provider.experimentsToken).to.equal(0.6);
});

SpecEnd
