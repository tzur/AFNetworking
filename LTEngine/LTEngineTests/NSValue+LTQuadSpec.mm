// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "NSValue+LTQuad.h"

SpecBegin(NSValue_LTQuad)

it(@"should box and unbox a given quad", ^{
  lt::Quad quad = lt::Quad::canonicalSquare();
  NSValue *value = [NSValue valueWithLTQuad:quad];
  expect([value LTQuadValue] == quad).to.beTruthy();
});

SpecEnd
