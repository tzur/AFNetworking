// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "WFGradientView.h"

SpecBegin(WFGradientView)

it(@"should create a gradient view with default values", ^{
  WFGradientView *view = [[WFGradientView alloc] initWithFrame:CGRectZero];

  expect(view.startColor).to.equal([UIColor clearColor]);
  expect(view.endColor).to.equal([UIColor clearColor]);
  expect(view.colors).to.equal(@[[UIColor clearColor], [UIColor clearColor]]);
  expect(view.startPoint).to.equal(CGPointMake(0, 0.5));
  expect(view.endPoint).to.equal(CGPointMake(1, 0.5));
});

context(@"horizontal gradient", ^{
  it(@"should create with colors", ^{
    WFGradientView *view = [WFGradientView horizontalGradientWithLeftColor:[UIColor blueColor]
                                                                rightColor:[UIColor greenColor]];

    expect(view.startColor).to.equal([UIColor blueColor]);
    expect(view.endColor).to.equal([UIColor greenColor]);
    expect(view.colors).to.equal(@[[UIColor blueColor], [UIColor greenColor]]);
    expect(view.startPoint.x).to.equal(0);
    expect(view.endPoint.x).to.equal(1);
    expect(view.startPoint.y).to.equal(view.endPoint.y);
  });

  it(@"should create with nil colors", ^{
    WFGradientView *view = [WFGradientView horizontalGradientWithLeftColor:nil rightColor:nil];

    expect(view.startColor).to.equal([UIColor clearColor]);
    expect(view.endColor).to.equal([UIColor clearColor]);
    expect(view.colors).to.equal(@[[UIColor clearColor], [UIColor clearColor]]);
    expect(view.startPoint.x).to.equal(0);
    expect(view.endPoint.x).to.equal(1);
    expect(view.startPoint.y).to.equal(view.endPoint.y);
  });
});

context(@"vertical gradient", ^{
  it(@"should create with colors", ^{
    WFGradientView *view = [WFGradientView verticalGradientWithTopColor:[UIColor blueColor]
                                                            bottomColor:[UIColor greenColor]];

    expect(view.startColor).to.equal([UIColor blueColor]);
    expect(view.endColor).to.equal([UIColor greenColor]);
    expect(view.colors).to.equal(@[[UIColor blueColor], [UIColor greenColor]]);
    expect(view.startPoint.y).to.equal(0);
    expect(view.endPoint.y).to.equal(1);
    expect(view.startPoint.x).to.equal(view.endPoint.x);
  });

  it(@"should create with nil colors", ^{
    WFGradientView *view = [WFGradientView verticalGradientWithTopColor:nil bottomColor:nil];

    expect(view.startColor).to.equal([UIColor clearColor]);
    expect(view.endColor).to.equal([UIColor clearColor]);
    expect(view.colors).to.equal(@[[UIColor clearColor], [UIColor clearColor]]);
    expect(view.startPoint.y).to.equal(0);
    expect(view.endPoint.y).to.equal(1);
    expect(view.startPoint.x).to.equal(view.endPoint.x);
  });
});

context(@"colors", ^{
  __block WFGradientView *view;

  beforeEach(^{
    view = [[WFGradientView alloc] initWithFrame:CGRectZero];
  });

  it(@"should copy colors", ^{
    NSMutableArray *colors = [@[[UIColor redColor], [UIColor blueColor]] mutableCopy];
    view.colors = colors;
    expect(view.colors).to.equal(colors);
    expect(view.colors).notTo.beIdenticalTo(colors);
  });

  it(@"should update colors when setting startColor", ^{
    view.startColor = [UIColor redColor];
    expect(view.colors).to.equal(@[[UIColor redColor], [UIColor clearColor]]);
  });

  it(@"should update colors when setting endColor", ^{
    view.endColor = [UIColor blueColor];
    expect(view.colors).to.equal(@[[UIColor clearColor], [UIColor blueColor]]);
  });

  it(@"should update startColor and endColor when setting colors", ^{
    view.colors = @[[UIColor redColor], [UIColor blueColor]];
    expect(view.startColor).to.equal([UIColor redColor]);
    expect(view.endColor).to.equal([UIColor blueColor]);
  });

  it(@"should raise if trying to set an empty array", ^{
    expect(^{
      view.colors = @[];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to set to an array with a single element", ^{
    expect(^{
      view.colors = @[[UIColor redColor]];
    }).to.raise(NSInvalidArgumentException);
  });

  context(@"reset colors", ^{
    beforeEach(^{
      view.colors = @[[UIColor redColor], [UIColor blueColor]];
    });

    it(@"should reset colors when set to nil", ^{
      view.colors = nil;
      expect(view.colors).to.equal(@[[UIColor clearColor], [UIColor clearColor]]);
    });

    it(@"should reset startColor when set to nil", ^{
      view.startColor = nil;
      expect(view.startColor).to.equal([UIColor clearColor]);
    });

    it(@"should reset endColor when set to nil", ^{
      view.endColor = nil;
      expect(view.endColor).to.equal([UIColor clearColor]);
    });
  });
});

it(@"should configure underlying CAGradientLayer correctly", ^{
  WFGradientView *view = [[WFGradientView alloc] initWithFrame:CGRectZero];

  view.colors = @[[UIColor greenColor], [UIColor redColor], [UIColor blueColor]];
  view.startPoint = CGPointMake(0.75, 0.5);
  view.endPoint = CGPointMake(0.25, 0);

  CAGradientLayer *layer = (CAGradientLayer *)view.layer;
  expect(layer.startPoint).to.equal(view.startPoint);
  expect(layer.endPoint).to.equal(view.endPoint);

  expect(layer.colors.count).to.equal(3);
  expect(CGColorEqualToColor((CGColorRef)layer.colors.firstObject,
                             view.startColor.CGColor)).to.beTruthy();
  expect(CGColorEqualToColor((CGColorRef)layer.colors.lastObject,
                             view.endColor.CGColor)).to.beTruthy();
  expect(CGColorEqualToColor((CGColorRef)layer.colors[1],
                             view.colors[1].CGColor)).to.beTruthy();
});

SpecEnd
