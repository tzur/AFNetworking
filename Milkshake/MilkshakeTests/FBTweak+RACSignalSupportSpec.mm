// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "FBTweak+RACSignalSupport.h"

SpecBegin(FBTweak_RACSignalSupport)

it(@"should send values when tweak changes", ^{
  auto tweak = [[FBTweak alloc] initWithIdentifier:@"foo"];
  tweak.currentValue = @1337;
  auto recorder = [[tweak shk_valueChanged] testRecorder];
  tweak.currentValue = nil;
  tweak.currentValue = @"bar";
  expect(recorder).to.sendValues(@[@1337, [NSNull null], @"bar"]);
});

SpecEnd
