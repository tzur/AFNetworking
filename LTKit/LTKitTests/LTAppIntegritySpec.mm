// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTAppIntegrity.h"

SpecBegin(LTAppIntegrity)

it(@"should return app entitlements", ^{
  auto _Nullable entitlements = LTAppEntitlements();

  expect(entitlements).notTo.beNil();
  expect(entitlements.count).to.beGreaterThan(0);

  // Should always exist (at least theoretically).
  expect(entitlements[@"application-identifier"]).notTo.beNil();
});

it(@"should not detect hijacked methods", ^{
  auto hijackedMethods = LTHijackedMethods();
  expect(hijackedMethods.size()).to.equal(0);
});

SpecEnd
