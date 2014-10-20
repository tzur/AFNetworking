// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "UIColor+Vector.h"

SpecBegin(UIColor_Vector)

const LTVector4 kClear(0, 0, 0, 0);
const LTVector4 kWhite(1, 1, 1, 1);
const LTVector4 kBlack(0, 0, 0, 1);
const LTVector4 kRed(1, 0, 0, 1);
const LTVector4 kGreen(0, 1, 0, 1);
const LTVector4 kBlue(0, 0, 1, 1);

it(@"should create color with vector", ^{
  expect([UIColor lt_colorWithLTVector:kClear]).to.equal([UIColor colorWithRed:0 green:0
                                                                          blue:0 alpha:0]);
  expect([UIColor lt_colorWithLTVector:kBlack]).to.equal([UIColor colorWithRed:0 green:0
                                                                          blue:0 alpha:1]);
  expect([UIColor lt_colorWithLTVector:kWhite]).to.equal([UIColor colorWithRed:1 green:1
                                                                          blue:1 alpha:1]);
  expect([UIColor lt_colorWithLTVector:kRed]).to.equal([UIColor redColor]);
  expect([UIColor lt_colorWithLTVector:kGreen]).to.equal([UIColor greenColor]);
  expect([UIColor lt_colorWithLTVector:kBlue]).to.equal([UIColor blueColor]);
});

context(@"from UIColor", ^{
  it(@"should create rgba vector with color", ^{
    expect([UIColor clearColor].lt_ltVector).to.equal(kClear);
    expect([UIColor blackColor].lt_ltVector).to.equal(kBlack);
    expect([UIColor whiteColor].lt_ltVector).to.equal(kWhite);
    expect([UIColor redColor].lt_ltVector).to.equal(kRed);
    expect([UIColor greenColor].lt_ltVector).to.equal(kGreen);
    expect([UIColor blueColor].lt_ltVector).to.equal(kBlue);
  });

  it(@"should create hsva vector with color", ^{
    expect([UIColor clearColor].lt_ltVectorHSVA).to.equal(kClear);
    expect([UIColor blackColor].lt_ltVectorHSVA).to.equal(kBlack);
    expect([UIColor whiteColor].lt_ltVectorHSVA).to.equal(LTVector4(0, 0, 1, 1));
    expect([UIColor redColor].lt_ltVectorHSVA).to.equal(LTVector4(1, 1, 1, 1));
    expect(([UIColor greenColor].lt_ltVectorHSVA - LTVector4(1.0 / 3, 1, 1, 1))
              .length()).to.beCloseTo(0);
    expect(([UIColor blueColor].lt_ltVectorHSVA - LTVector4(2.0 / 3, 1, 1, 1))
              .length()).to.beCloseTo(0);
  });

  it(@"should create cv::Vec4b with color", ^{
    expect(LTCVVec4bToLTVector4([UIColor clearColor].lt_cvVector)).to.equal(kClear);
    expect(LTCVVec4bToLTVector4([UIColor blackColor].lt_cvVector)).to.equal(kBlack);
    expect(LTCVVec4bToLTVector4([UIColor whiteColor].lt_cvVector)).to.equal(kWhite);
    expect(LTCVVec4bToLTVector4([UIColor redColor].lt_cvVector)).to.equal(kRed);
    expect(LTCVVec4bToLTVector4([UIColor greenColor].lt_cvVector)).to.equal(kGreen);
    expect(LTCVVec4bToLTVector4([UIColor blueColor].lt_cvVector)).to.equal(kBlue);
  });
});

SpecEnd
