// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "UIFont+Size.h"

SpecBegin(UIFont_Size)

it(@"should return font size same as the given single control point", ^{
  WFHeightToFontSizeDictionary *controlPoint = @{@10: @20};
  expect([UIFont wf_fontSizeForAvailableHeight:4 withControlPoints:controlPoint])
      .to.equal(@20);
});

it(@"should return correct font size for control points", ^{
  WFHeightToFontSizeDictionary *controlPoints = @{
    @10: @15,
    @15: @22,
    @20: @20,
    @30: @30,
    @40: @55
  };
  expect([UIFont wf_fontSizeForAvailableHeight:20 withControlPoints:controlPoints])
      .to.equal(@20);
  expect([UIFont wf_fontSizeForAvailableHeight:25 withControlPoints:controlPoints])
      .to.equal(@25);
  expect([UIFont wf_fontSizeForAvailableHeight:30 withControlPoints:controlPoints])
      .to.equal(@30);
});

it(@"should clamp result to the extremum control point's font size", ^{
  WFHeightToFontSizeDictionary *controlPoints = @{
    @55: @22,
    @70: @30,
    @62: @24
  };
  expect([UIFont wf_fontSizeForAvailableHeight:71 withControlPoints:controlPoints])
      .to.equal(@30);
  expect([UIFont wf_fontSizeForAvailableHeight:53 withControlPoints:controlPoints])
      .to.equal(@22);
});

it(@"should raise if there are no control points", ^{
  expect(^{
    [UIFont wf_fontSizeForAvailableHeight:7 withControlPoints:@{}];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should round the result to the nearest integer", ^{
  WFHeightToFontSizeDictionary *controlPoints = @{
    @10: @1,
    @20: @2
  };
  expect([UIFont wf_fontSizeForAvailableHeight:12 withControlPoints:controlPoints])
      .to.equal(@1);
  expect([UIFont wf_fontSizeForAvailableHeight:18 withControlPoints:controlPoints])
      .to.equal(@2);
});

it(@"should interpolate the result correctly", ^{
  WFHeightToFontSizeDictionary *controlPoints = @{
    @1: @10,
    @2: @20
  };
  expect([UIFont wf_fontSizeForAvailableHeight:1.2 withControlPoints:controlPoints])
      .to.equal(@12);
  expect([UIFont wf_fontSizeForAvailableHeight:1.8 withControlPoints:controlPoints])
      .to.equal(@18);
});

it(@"should interpolate the result correctly when there are control points with the same size", ^{
  WFHeightToFontSizeDictionary *controlPoints = @{
    @10: @100,
    @20: @100
  };
  expect([UIFont wf_fontSizeForAvailableHeight:10 withControlPoints:controlPoints])
      .to.equal(@100);
  expect([UIFont wf_fontSizeForAvailableHeight:15 withControlPoints:controlPoints])
      .to.equal(@100);
  expect([UIFont wf_fontSizeForAvailableHeight:20 withControlPoints:controlPoints])
      .to.equal(@100);
});

it(@"should interpolate the result correctly when the given heights are floats", ^{
  WFHeightToFontSizeDictionary *controlPoints = @{
    @1.1: @11,
    @2.1: @21
  };
  expect([UIFont wf_fontSizeForAvailableHeight:1.2 withControlPoints:controlPoints])
      .to.equal(@12);
  expect([UIFont wf_fontSizeForAvailableHeight:1.8 withControlPoints:controlPoints])
      .to.equal(@18);
});

it(@"should interpolate the result correctly when the given font sizes are floats", ^{
  WFHeightToFontSizeDictionary *controlPoints = @{
    @11: @1.1,
    @21: @2.1
  };
  expect([UIFont wf_fontSizeForAvailableHeight:14 withControlPoints:controlPoints])
      .to.equal(@1);
  expect([UIFont wf_fontSizeForAvailableHeight:16 withControlPoints:controlPoints])
      .to.equal(@2);
});

SpecEnd
