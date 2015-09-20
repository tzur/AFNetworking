// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTNextIterationPlacement.h"

#import "LTFbo.h"
#import "LTTexture.h"

SpecBegin(LTNextIterationPlacement)

it(@"should initialize with correct values", ^{
  id texture = [OCMockObject mockForClass:[LTTexture class]];
  id fbo = [OCMockObject mockForClass:[LTFbo class]];

  LTNextIterationPlacement *placement = [[LTNextIterationPlacement alloc]
                                         initWithSourceTexture:texture andTargetFbo:fbo];

  expect(placement.sourceTexture).to.equal(texture);
  expect(placement.targetFbo).to.equal(fbo);
});

SpecEnd
