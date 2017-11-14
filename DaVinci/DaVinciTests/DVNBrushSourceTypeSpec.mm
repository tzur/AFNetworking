// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushSourceType.h"

SpecBegin(DVNBrushSourceType)

it(@"should have correct values", ^{
  // The specific values of the enumeration keys are important since the DVNBrush fragment shader
  // relies on them.
  expect($(DVNBrushSourceTypeColor).value).to.equal(0);
  expect($(DVNBrushSourceTypeSourceTexture).value).to.equal(1);
  expect($(DVNBrushSourceTypeOverlayTexture).value).to.equal(2);
});

SpecEnd
