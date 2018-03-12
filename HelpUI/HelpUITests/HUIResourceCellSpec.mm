// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import <Wireframes/WFImageLoader.h>

#import "HUIResourceCell+Protected.h"

SpecBegin(HUIResourceCell_Protected)

__block HUIResourceCell *cell;

beforeEach(^{
  cell = [[HUIResourceCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
});

it(@"should create box view", ^{
  expect([cell wf_viewForAccessibilityIdentifier:@"Box"]).to.beKindOf(UIView.class);
});

SpecEnd
