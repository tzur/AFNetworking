// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "FBMutableTweak+RACSignalSupport.h"

SpecBegin(FBTweak_RACSignalSupport)

it(@"should send values when tweak changes", ^{
  auto tweak = [[FBMutableTweak alloc] initWithIdentifier:@"foo" name:@"bar" defaultValue:@9];
  tweak.currentValue = @1337;
  auto recorder = [[tweak shk_valueChanged] testRecorder];
  tweak.currentValue = nil;
  tweak.currentValue = @"bar";
  expect(recorder).to.sendValues(@[@1337, @9, @"bar"]);
});

SpecEnd
