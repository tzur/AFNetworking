// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTAppIntegrity.h"

/// Required since the test suite runs as logic test and doesn't link with an actual binary.
int main(int, char * _Nonnull[]) {
  return 0;
}

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
