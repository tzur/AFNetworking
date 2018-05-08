// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemTextButton.h"

#import "CUISimpleMenuItemViewModel.h"
#import "CUITheme.h"

SpecBegin(CUIMenuItemTextButton)

static NSString * const kTitle = @"Title text";
static UIColor * const kTitleColor = [UIColor greenColor];
static UIColor * const kTitleHighlightedColor = [UIColor redColor];
static UIFont * const kTitleFont = [UIFont italicSystemFontOfSize:25];
static UIFont * const kTitleHighlightedFont = [UIFont boldSystemFontOfSize:12];

__block CUIMenuItemTextButton *button;
__block CUISimpleMenuItemViewModel *model;
__block id themeMock;

beforeEach(^{
  themeMock = LTMockClass([CUITheme class]);
  OCMStub([themeMock titleColor]).andReturn(kTitleColor);
  OCMStub([themeMock titleHighlightedColor]).andReturn(kTitleHighlightedColor);
  OCMStub([themeMock titleFont]).andReturn(kTitleFont);
  OCMStub([themeMock titleHighlightedFont]).andReturn(kTitleHighlightedFont);
  model = [[CUISimpleMenuItemViewModel alloc] init];
  model.title = kTitle;
  button = [[CUIMenuItemTextButton alloc] initWithModel:model];
});

it(@"should set the model property correctly", ^{
  expect(button.model).to.beIdenticalTo(model);
});

it(@"should update the text property according to the model", ^{
  expect(button.currentTitle).will.equal(kTitle);
  model.title = @"New title";
  expect(button.currentTitle).will.equal(@"New title");
});

it(@"should update the selected property according to the model", ^{
  model.selected = YES;
  expect(button.selected).will.equal(YES);
  model.selected = NO;
  expect(button.selected).will.equal(NO);
});

it(@"should update the hidden property according to the model", ^{
  model.hidden = YES;
  expect(button.hidden).will.equal(YES);
  model.hidden = NO;
  expect(button.hidden).will.equal(NO);
});

it(@"should update the enabled property according to the model", ^{
  model.enabled = YES;
  expect(button.enabled).will.equal(YES);
  model.enabled = NO;
  expect(button.enabled).will.equal(NO);
});

it(@"should update the alpha property according to the enabled property", ^{
  model.enabled = YES;
  expect(button.alpha).to.equal(1.0);
  model.enabled = NO;
  expect(button.alpha).to.beCloseTo(0.4);
  model.enabled = YES;
  expect(button.alpha).to.equal(1.0);
});

it(@"should set the text format according to the shared theme", ^{
  expect(button.titleLabel.textColor).to.equal(kTitleColor);
  expect([button titleColorForState:UIControlStateSelected]).to.equal(kTitleHighlightedColor);
  expect([button titleColorForState:UIControlStateHighlighted]).to.equal(kTitleHighlightedColor);
  expect(button.titleLabel.font).to.equal(kTitleFont);
});

it(@"should update the font according to selected property", ^{
  expect(button.titleLabel.font).to.equal(kTitleFont);
  model.selected = YES;
  expect(button.titleLabel.font).to.equal(kTitleHighlightedFont);
  model.selected = NO;
  expect(button.titleLabel.font).to.equal(kTitleFont);
});

it(@"should call didTap when the button is tapped", ^{
  expect(model.didTapCounter).to.equal(0);
  [button sendActionsForControlEvents:UIControlEventTouchUpInside];
  expect(model.didTapCounter).will.equal(1);
});

SpecEnd
