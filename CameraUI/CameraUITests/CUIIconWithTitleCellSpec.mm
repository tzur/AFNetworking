// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIIconWithTitleCell.h"

#import "CUIMenuItemViewModel.h"
#import "CUISimpleMenuItemViewModel.h"
#import "CUITheme.h"

@interface CUIIconWithTitleCell (ForTesting)
@property (readonly, nonatomic) UILabel *titleLabel;
@property (readonly, nonatomic) UIImageView *iconView;
@end

SpecBegin(CUIIconWithTitleCell)

static NSString * const kIconPath = @"paintcode://WFFakePaintCodeModule/ImageB";
static UIColor * const kIconColor = [UIColor cyanColor];
static UIColor * const kIconHighlightedColor = [UIColor yellowColor];
static UIColor * const kTitleColor = [UIColor blueColor];
static UIColor * const kTitleHighlightedColor = [UIColor redColor];
static UIColor * const kMenuBackgroundColor = [UIColor greenColor];
static UIFont * const kTitleFont = [UIFont italicSystemFontOfSize:7];

__block CUIIconWithTitleCell *iconWithTitleCell;
__block id themeMock;

beforeEach(^{
  themeMock = LTMockClass([CUITheme class]);
  OCMStub([themeMock titleColor]).andReturn(kTitleColor);
  OCMStub([themeMock titleHighlightedColor]).andReturn(kTitleHighlightedColor);
  OCMStub([themeMock menuBackgroundColor]).andReturn(kMenuBackgroundColor);
  OCMStub([themeMock titleFont]).andReturn(kTitleFont);
  OCMStub([themeMock iconColor]).andReturn(kIconColor);
  OCMStub([themeMock iconHighlightedColor]).andReturn(kIconHighlightedColor);

  iconWithTitleCell = [[CUIIconWithTitleCell alloc] initWithFrame:CGRectZero];
});

context(@"use shared theme", ^{
  it(@"should use title colors", ^{
    expect(iconWithTitleCell.titleLabel.textColor).to.equal(kTitleColor);
    expect(iconWithTitleCell.titleLabel.highlightedTextColor).to.equal(kTitleHighlightedColor);
  });

  it(@"should use background color", ^{
    expect(iconWithTitleCell.backgroundColor).to.equal(kMenuBackgroundColor);
  });

  it(@"should use title font", ^{
    expect(iconWithTitleCell.titleLabel.font).to.equal(kTitleFont);
  });

  it(@"should use icon colors", ^{
    CUISimpleMenuItemViewModel *fakeViewModel = [[CUISimpleMenuItemViewModel alloc] init];
    fakeViewModel.iconURL = [NSURL URLWithString:kIconPath];
    iconWithTitleCell.viewModel = fakeViewModel;
    OCMVerify([themeMock iconHighlightedColor]);
    OCMVerify([themeMock iconColor]);
  });
});

context(@"use model", ^{
  static NSString * const kTitle = @"title";
  static NSString * const kTitle2 = @"title2";

  __block CUISimpleMenuItemViewModel *fakeViewModel;

  beforeEach(^{
    fakeViewModel = [[CUISimpleMenuItemViewModel alloc] init];
    fakeViewModel.hidden = YES;
    fakeViewModel.title = kTitle;
    fakeViewModel.iconURL = [NSURL URLWithString:kIconPath];
    iconWithTitleCell.viewModel = fakeViewModel;
  });

  it(@"should not use the hidden property", ^{
    expect(iconWithTitleCell.titleLabel.hidden).to.beFalsy();
    expect(iconWithTitleCell.iconView.hidden).to.beFalsy();
    expect(iconWithTitleCell.hidden).to.beFalsy();
  });

  it(@"should have model title", ^{
    expect(iconWithTitleCell.titleLabel.text).to.equal(kTitle);
    fakeViewModel.title = @"title2";
    expect(iconWithTitleCell.titleLabel.text).to.equal(kTitle2);
  });

  it(@"should have model title after model change", ^{
    expect(iconWithTitleCell.titleLabel.text).to.equal(kTitle);
    CUISimpleMenuItemViewModel *fakeViewModel2 = [[CUISimpleMenuItemViewModel alloc] init];
    fakeViewModel2.title = kTitle2;
    iconWithTitleCell.viewModel = fakeViewModel2;
    expect(iconWithTitleCell.titleLabel.text).to.equal(kTitle2);
  });

  it(@"should have model select as highlight", ^{
    fakeViewModel.selected = NO;
    expect(iconWithTitleCell.titleLabel.highlighted).to.beFalsy();
    expect(iconWithTitleCell.iconView.highlighted).to.beFalsy();
    fakeViewModel.selected = YES;
    expect(iconWithTitleCell.titleLabel.highlighted).to.beTruthy();
    expect(iconWithTitleCell.iconView.highlighted).to.beTruthy();
  });

  it(@"should have model select as highlight after model change", ^{
    CUISimpleMenuItemViewModel *fakeViewModel2 = [[CUISimpleMenuItemViewModel alloc] init];
    fakeViewModel2.selected = YES;
    iconWithTitleCell.viewModel = fakeViewModel2;
    expect(iconWithTitleCell.titleLabel.highlighted).to.beTruthy();
    expect(iconWithTitleCell.iconView.highlighted).to.beTruthy();
    fakeViewModel2.selected = NO;
    expect(iconWithTitleCell.titleLabel.highlighted).to.beFalsy();
    expect(iconWithTitleCell.iconView.highlighted).to.beFalsy();
  });

  it(@"should not select when cell selected", ^{
    iconWithTitleCell.selected = YES;
    expect(iconWithTitleCell.titleLabel.highlighted).to.beFalsy();
    expect(iconWithTitleCell.selected).to.beFalsy();
  });

  it(@"should not highlighted when cell highlighted", ^{
    iconWithTitleCell.highlighted = YES;
    expect(iconWithTitleCell.titleLabel.highlighted).to.beFalsy();
    expect(iconWithTitleCell.highlighted).to.beFalsy();
  });

  it(@"should not call did tap when cell selected", ^{
    iconWithTitleCell.selected = YES;
    expect(fakeViewModel.didTapCounter).to.equal(0);
    expect(fakeViewModel.selected).to.beFalsy();
  });

  it(@"should not call did tap when selected", ^{
    fakeViewModel.selected = YES;
    expect(fakeViewModel.didTapCounter).to.equal(0);
    expect(iconWithTitleCell.titleLabel.highlighted).to.beTruthy();
  });

  it(@"should use an icon", ^{
    iconWithTitleCell.frame = CGRectMake(0, 0, 500, 500);
    [iconWithTitleCell layoutIfNeeded];
    expect(iconWithTitleCell.iconView.image).willNot.beNil();
  });

  it(@"should set icon to nil", ^{
    iconWithTitleCell.frame = CGRectMake(0, 0, 500, 500);
    [iconWithTitleCell layoutIfNeeded];
    expect(iconWithTitleCell.iconView.image).willNot.beNil();
    fakeViewModel.iconURL = nil;
    expect(iconWithTitleCell.iconView.image).will.beNil();
  });
});

SpecEnd
