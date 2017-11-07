// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

SpecBegin(Test)

it(@"should pass", ^{
  expect(@"foo").notTo.equal(@"bar");
});

SpecEnd
