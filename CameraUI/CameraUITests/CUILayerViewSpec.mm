// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUILayerView.h"

SpecBegin(CUILayerView)

static const CGRect kRect = CGRectMake(1, 2, 3, 4);

__block CUILayerView *layerView;
__block CALayer *internalLayer;

beforeEach(^{
  internalLayer = [[CALayer alloc] init];
  layerView = [[CUILayerView alloc] initWithLayer:internalLayer];
});

it(@"should add the view layer as the internal layer super layer", ^{
  expect(internalLayer.superlayer).to.equal(layerView.layer);
});

it(@"should change frame when layoutSubviews", ^{
  expect(internalLayer.frame).to.equal(CGRectZero);
  layerView.frame = kRect;
  [layerView layoutSubviews];
  expect(internalLayer.frame).to.equal(layerView.bounds);
});

SpecEnd
