// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "WFGradientView.h"

SpecBegin(WFGradientView)

it(@"should create a gradient view with default values", ^{
  WFGradientView *view = [[WFGradientView alloc] initWithFrame:CGRectZero];

  expect(view.startColor).to.equal([UIColor clearColor]);
  expect(view.endColor).to.equal([UIColor clearColor]);
  expect(view.startPoint).to.equal(CGPointMake(0, 0.5));
  expect(view.endPoint).to.equal(CGPointMake(1, 0.5));
});

it(@"should create a horizontal gradient", ^{
  WFGradientView *view = [WFGradientView horizontalGradientWithLeftColor:[UIColor blueColor]
                                                              rightColor:[UIColor greenColor]];

  expect(view.startColor).to.equal([UIColor blueColor]);
  expect(view.endColor).to.equal([UIColor greenColor]);
  expect(view.startPoint.x).to.equal(0);
  expect(view.endPoint.x).to.equal(1);
  expect(view.startPoint.y).to.equal(view.endPoint.y);
});

it(@"should create a vertical gradient", ^{
  WFGradientView *view = [WFGradientView verticalGradientWithTopColor:[UIColor blueColor]
                                                          bottomColor:[UIColor greenColor]];

  expect(view.startColor).to.equal([UIColor blueColor]);
  expect(view.endColor).to.equal([UIColor greenColor]);
  expect(view.startPoint.y).to.equal(0);
  expect(view.endPoint.y).to.equal(1);
  expect(view.startPoint.x).to.equal(view.endPoint.x);
});

it(@"should configure underlying CAGradientLayer correctly", ^{
  WFGradientView *view = [[WFGradientView alloc] initWithFrame:CGRectZero];

  view.startColor = [UIColor greenColor];
  view.endColor = [UIColor blueColor];
  view.startPoint = CGPointMake(0.75, 0.5);
  view.endPoint = CGPointMake(0.25, 0);

  CAGradientLayer *layer = (CAGradientLayer *)view.layer;
  expect(layer.startPoint).to.equal(view.startPoint);
  expect(layer.endPoint).to.equal(view.endPoint);

  expect(layer.colors.count).to.equal(2);
  expect(CGColorEqualToColor((CGColorRef)layer.colors.firstObject,
                             view.startColor.CGColor)).to.beTruthy();
  expect(CGColorEqualToColor((CGColorRef)layer.colors.lastObject,
                             view.endColor.CGColor)).to.beTruthy();
});

SpecEnd
