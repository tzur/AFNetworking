// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTSplitComplexMat.h"

SpecBegin(LTSplitComplexMat)

it(@"should initialize empty matrices", ^{
  LTSplitComplexMat *splitComplex = [[LTSplitComplexMat alloc] init];

  expect(splitComplex.real.empty()).to.beTruthy();
  expect(splitComplex.imag.empty()).to.beTruthy();
});

it(@"should initialize with matrices", ^{
  cv::Mat1f real(16, 16);
  cv::Mat1f imag(16, 16);

  LTSplitComplexMat *splitComplex = [[LTSplitComplexMat alloc] initWithReal:real imag:imag];

  expect($(splitComplex.real)).to.equalMat($(real));
  expect($(splitComplex.imag)).to.equalMat($(imag));
});

SpecEnd
