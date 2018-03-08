// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIVideoCell.h"

#import <Wireframes/WFVideoView.h>

#import "HUIBoxView.h"
#import "HUIItem.h"

SpecBegin(HUIVideoCell)

__block HUIVideoCell *cell;

beforeEach(^{
  cell = [[HUIVideoCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
});

context(@"initialization", ^{
  it(@"should create video view", ^{
    expect([cell wf_viewForAccessibilityIdentifier:@"Video"]).to.beKindOf(WFVideoView.class);
  });

  it(@"should initialize with nil item", ^{
    expect(cell.item).to.beNil();
  });

  it(@"should initialize video view with correct propeties", ^{
    auto video = (WFVideoView *)[cell wf_viewForAccessibilityIdentifier:@"Video"];

    expect(video.videoGravity).to.equal(AVLayerVideoGravityResize);
    expect(video.repeatsOnEnd).to.beTruthy();
  });
});

context(@"properties", ^{
  __block HUIVideoItem *item;

  beforeEach(^{
    auto dict = @{
      @"type": @"video",
      @"title": @"title",
      @"body": @"body",
      @"icon_url": @"icon"
    };
    item = [MTLJSONAdapter modelOfClass:HUIVideoItem.class fromJSONDictionary:dict error:nil];
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
  __block WFVideoView *video;

  beforeEach(^{
    video = (WFVideoView *)[cell wf_viewForAccessibilityIdentifier:@"Video"];
  });

  it(@"should play video view on when animation starts", ^{
    [cell animatableCellStartAnimation];
    OCMVerify([video play]);
  });

  it(@"should pause video view on when animation pauses", ^{
    [cell animatableCellStopAnimation];
    OCMVerify([video pause]);
  });
});

SpecEnd
