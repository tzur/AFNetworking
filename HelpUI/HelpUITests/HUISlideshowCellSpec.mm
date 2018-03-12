// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUISlideshowCell.h"

#import <Wireframes/WFSlideshowView.h>

#import "HUIBoxView.h"
#import "HUIItem.h"

SpecBegin(HUISlideshowCell)

__block HUISlideshowCell *cell;

beforeEach(^{
  cell = [[HUISlideshowCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
});

it(@"should initialize properly", ^{
  auto slideshowClass = WFSlideshowView.class;
  auto slideshow = [cell wf_viewForAccessibilityIdentifier:@"Slideshow"];

  expect(slideshow).to.beKindOf(slideshowClass);
  expect(((WFSlideshowView *)slideshow).transition).to.equal(WFSlideshowTransitionCurtain);
  expect(cell.item).to.beNil();
});

context(@"properties", ^{
  __block HUISlideshowItem *item;

  beforeEach(^{
    auto dict = @{
      @"type": @"slideshow",
      @"title": @"title",
      @"body": @"body",
      @"icon_url": @"icon",
    };
    item = [MTLJSONAdapter modelOfClass:HUISlideshowItem.class fromJSONDictionary:dict error:nil];
  });

  it(@"should set box title correctly", ^{
    cell.item = item;
    expect(cell.boxView.title).to.equal(@"title");
  });

  it(@"should set body correctly", ^{
    cell.item = item;
    expect(cell.boxView.body).to.equal(@"body");
  });

  it(@"should set icon URL correctly", ^{
    cell.item = item;
    expect(cell.boxView.iconURL).to.equal([NSURL URLWithString:@"icon"]);
  });
});

context(@"animatable cell", ^{
  __block WFSlideshowView *slideshow;

  beforeEach(^{
    slideshow = (WFSlideshowView *)[cell wf_viewForAccessibilityIdentifier:@"Slideshow"];
  });

  it(@"should play slideshow view when animation starts", ^{
    [cell startAnimation];
    OCMVerify([slideshow play]);
  });

  it(@"should pause slideshow view when animation pauses", ^{
    [cell stopAnimation];
    OCMVerify([slideshow pause]);
  });
});

SpecEnd
