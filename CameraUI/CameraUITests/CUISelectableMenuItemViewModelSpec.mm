// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUISelectableMenuItemViewModel.h"

#import "CUIMenuItemModel.h"

SpecBegin(CUISelectableMenuItemViewModel)

__block CUISelectableMenuItemViewModel *selectableMenuItemViewModel;
__block NSURL *url;
__block CUIMenuItemModel *model;

beforeEach(^{
  url = [[NSURL alloc] initWithString:@"http://hello.world"];
  model = [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"title" iconURL:url key:@"key"];
  selectableMenuItemViewModel = [[CUISelectableMenuItemViewModel alloc]
      initWithMenuItemModel:model];
});

it(@"should have init properties", ^{
  expect(selectableMenuItemViewModel.title).to.equal(@"title");
  expect(selectableMenuItemViewModel.iconURL).to.equal(url);
  expect(selectableMenuItemViewModel.menuItemModel).to.beIdenticalTo(model);
  expect(selectableMenuItemViewModel.hidden).to.beFalsy();
  expect(selectableMenuItemViewModel.subitems).to.beNil;
  expect(selectableMenuItemViewModel.selected).to.beFalsy();
  expect(selectableMenuItemViewModel.enabled).to.beTruthy();
});

it(@"should not change after didtap", ^{
  [selectableMenuItemViewModel didTap];
  expect(selectableMenuItemViewModel.title).to.equal(@"title");
  expect(selectableMenuItemViewModel.iconURL).to.equal(url);
  expect(selectableMenuItemViewModel.menuItemModel).to.beIdenticalTo(model);
  expect(selectableMenuItemViewModel.hidden).to.beFalsy();
  expect(selectableMenuItemViewModel.subitems).to.beNil;
  expect(selectableMenuItemViewModel.selected).to.beFalsy();
  expect(selectableMenuItemViewModel.enabled).to.beTruthy();
});

it(@"should change selected", ^{
  selectableMenuItemViewModel.selected = YES;
  expect(selectableMenuItemViewModel.selected).to.beTruthy();
});

SpecEnd
