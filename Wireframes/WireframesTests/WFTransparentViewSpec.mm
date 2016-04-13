// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "WFTransparentView.h"

SpecBegin(WFTransparentView)

__block WFTransparentView *view;

beforeEach(^{
  view = [[WFTransparentView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
});

it(@"should be transparent to touches outside subviews", ^{
  expect([view pointInside:CGPointMake(0, 0) withEvent:nil]).to.beFalsy();
  expect([view pointInside:CGPointMake(10, 10) withEvent:nil]).to.beFalsy();
});

it(@"should not be transparent to touches for non transparent subview", ^{
  UIView *subview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
  [view addSubview:subview];

  expect([view pointInside:CGPointMake(0, 0) withEvent:nil]).to.beTruthy();
  expect([view pointInside:CGPointMake(10, 10) withEvent:nil]).to.beFalsy();
});

it(@"should be transparent to touches for a hidden subview", ^{
  UIView *subview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
  subview.hidden = YES;
  [view addSubview:subview];

  expect([view pointInside:CGPointMake(0, 0) withEvent:nil]).to.beFalsy();
  expect([view pointInside:CGPointMake(10, 10) withEvent:nil]).to.beFalsy();
});

it(@"should be transparent to touches for a zero alpha subview", ^{
  UIView *subview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
  subview.alpha = 0;
  [view addSubview:subview];

  expect([view pointInside:CGPointMake(0, 0) withEvent:nil]).to.beFalsy();
  expect([view pointInside:CGPointMake(10, 10) withEvent:nil]).to.beFalsy();
});

SpecEnd
