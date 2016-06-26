// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemIconButton.h"

#import <WireframesTests/WFFakePaintCodeModule.h>

#import "CUISimpleMenuItemViewModel.h"
#import "CUISharedTheme.h"

#import <Wireframes/UIButton+ViewModel.h>

SpecBegin(CUIMenuItemIconButton)

static UIColor * const kIconColor = [UIColor greenColor];
static UIColor * const kIconHighlightedColor = [UIColor redColor];
static NSURL * const kIconURL =
    [NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageB"];

__block CUIMenuItemIconButton *button;
__block CUISimpleMenuItemViewModel *model;
__block id themeMock;

beforeEach(^{
  themeMock = LTMockProtocol(@protocol(CUITheme));
  OCMStub([themeMock iconColor]).andReturn(kIconColor);
  OCMStub([themeMock iconHighlightedColor]).andReturn(kIconHighlightedColor);
  model = [[CUISimpleMenuItemViewModel alloc] init];
  model.iconURL = kIconURL;
  button = [[CUIMenuItemIconButton alloc] initWithModel:model];
});

it(@"should raise an exception when initialized with nil model", ^{
  CUISimpleMenuItemViewModel *model = nil;
  expect(^{
    CUIMenuItemIconButton * __unused button = [[CUIMenuItemIconButton alloc] initWithModel:model];
  }).to.raise(NSInvalidArgumentException);
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

it(@"should inquire the shared theme", ^{
  OCMVerify([themeMock iconColor]);
  OCMVerify([themeMock iconHighlightedColor]);
});

it(@"should call didTap when the button is tapped", ^{
  expect(model.didTapCounter).to.equal(0);
  [button sendActionsForControlEvents:UIControlEventTouchUpInside];
  expect(model.didTapCounter).will.equal(1);
});

SpecEnd
