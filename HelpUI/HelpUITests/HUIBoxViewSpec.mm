// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIBoxView.h"

#import "HUIBoxTopView.h"

SpecBegin(HUIBoxView)

__block HUIBoxView *helpBoxView;
__block HUIBoxTopView *boxTopView;

beforeEach(^{
  helpBoxView = [[HUIBoxView alloc] initWithFrame:CGRectMake(0, 0, 260, 260)];
  [helpBoxView layoutIfNeeded];
  boxTopView = (HUIBoxTopView *)[helpBoxView wf_viewForAccessibilityIdentifier:@"BoxTop"];
});

it(@"should have valid content view", ^{
    expect(helpBoxView.contentView).toNot.beNil();
});

it(@"should create box title view with correct accessibility identifier", ^{
  expect(boxTopView).to.beKindOf([HUIBoxTopView class]);
});

it(@"should set title correctly", ^{
  helpBoxView.title = @"title";
  expect(boxTopView.title).to.equal(@"title");
});

it(@"should set body correctly", ^{
  helpBoxView.body = @"body";
  expect(boxTopView.body).to.equal(@"body");
});

it(@"should set icon correctly", ^{
  helpBoxView.iconURL = [NSURL URLWithString:@"icon"];
  expect(boxTopView.iconURL).to.equal([NSURL URLWithString:@"icon"]);
});

it(@"should return box height that keeps aspect ratio", ^{
  auto expectedAspectRatio = [HUISettings instance].contentAspectRatio;
  id boxTopMock = OCMClassMock([HUIBoxTopView class]);
  OCMStub([[[boxTopMock stub] ignoringNonObjectArgs] boxTopHeightForTitle:[OCMArg any]
                                                                     body:[OCMArg any]
                                                                  iconURL:[OCMArg any] width:0]
          ).andReturn(0);
  auto width = 520;
  auto height = [HUIBoxView boxHeightForTitle:nil body:nil iconURL:nil width:width];

  expect(height).to.beCloseTo(expectedAspectRatio * width);
});

SpecEnd
