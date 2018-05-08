// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemIconButton.h"

#import "CUISimpleMenuItemViewModel.h"
#import "CUITheme.h"
#import "WFLoggingImageProvider.h"

SpecBegin(CUIMenuItemIconButton)

static UIColor * const kIconColor = [UIColor greenColor];
static UIColor * const kIconHighlightedColor = [UIColor redColor];
static NSURL * const kIconURL =
    [NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageB"];

__block CUIMenuItemIconButton *button;
__block CUISimpleMenuItemViewModel *model;
__block id themeMock;
__block WFLoggingImageProvider *imageProvider;

beforeEach(^{
  themeMock = LTMockClass([CUITheme class]);
  OCMStub([themeMock iconColor]).andReturn(kIconColor);
  OCMStub([themeMock iconHighlightedColor]).andReturn(kIconHighlightedColor);

  imageProvider = WFUseLoggingImageProvider();

  model = [[CUISimpleMenuItemViewModel alloc] init];
  model.iconURL = kIconURL;

  button = [[CUIMenuItemIconButton alloc] initWithModel:model];
});

it(@"should set the model property correctly", ^{
  expect(button.model).to.beIdenticalTo(model);
});

it(@"should set its image according to the icon URL", ^{
  button.frame = CGRectMake(0, 0, 44, 44);
  [button layoutIfNeeded];
  expect([button imageForState:UIControlStateNormal]).willNot.beNil();
  model.iconURL = nil;
  expect([button imageForState:UIControlStateNormal]).will.beNil();
  model.iconURL = kIconURL;
  expect([button imageForState:UIControlStateNormal]).willNot.beNil();
});

it(@"should load image correctly", ^{
  button.frame = CGRectMake(0, 0, 44, 44);
  [button layoutIfNeeded];
  [imageProvider waitUntilCompletion];
  expect(imageProvider.completedURLs.count).to.beGreaterThan(0);
  expect(imageProvider.errdURLs).to.haveCount(0);
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

it(@"should inquire the shared theme", ^{
  OCMVerify([themeMock iconColor]);
  OCMVerify([themeMock iconHighlightedColor]);
});

it(@"should call didTap when the button is tapped", ^{
  expect(model.didTapCounter).to.equal(0);
  [button sendActionsForControlEvents:UIControlEventTouchUpInside];
  expect(model.didTapCounter).will.equal(1);
});

it(@"should not retain itself", ^{
  __weak CUIMenuItemIconButton *weakButton;
  @autoreleasepool {
    CUIMenuItemIconButton *strongButton = [[CUIMenuItemIconButton alloc] initWithModel:model];
    weakButton = strongButton;
    expect(weakButton).notTo.beNil();
  }
  expect(weakButton).to.beNil();
});

SpecEnd
