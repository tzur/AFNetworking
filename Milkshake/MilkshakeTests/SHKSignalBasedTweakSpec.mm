// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKSignalBasedTweak.h"

SpecBegin(SHKSignalBasedTweak)

it(@"should update the current value according to value sent in the signal", ^{
  RACSubject *currentValueSignal = [RACSubject subject];
  auto tweak = [[SHKSignalBasedTweak alloc] initWithIdentifier:@"foo" name:@"bar"
                                            currentValueSignal:currentValueSignal];
  expect(tweak.currentValue).to.beNil();
  [currentValueSignal sendNext:@"flop"];
  expect(tweak.currentValue).to.equal(@"flop");
  [currentValueSignal sendNext:@1337];
  expect(tweak.currentValue).to.equal(@1337);
});

SpecEnd
