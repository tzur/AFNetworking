// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUISingleChoiceMenuViewModel.h"

#import "CUIMenuItemModel.h"

SpecBegin(CUISingleChoiceMenuViewModel)

static NSURL * const kTestURL = [NSURL URLWithString:@"http://hello.world"];

__block CUISingleChoiceMenuViewModel *menu;
__block NSArray<CUIMenuItemModel *> *itemModels;

beforeEach(^{
  itemModels = @[
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"a" iconURL:kTestURL key:@""],
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"b" iconURL:kTestURL key:@""],
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"c" iconURL:kTestURL key:@""]
  ];
  menu = [[CUISingleChoiceMenuViewModel alloc] initWithItemModels:itemModels
                                                     selectedItem:itemModels[2]];
});

it(@"should start with selected item selected", ^{
  expect(menu.selectedItem).to.equal(itemModels[2]);
  expect(menu.itemViewModels[0].selected).to.beFalsy();
  expect(menu.itemViewModels[1].selected).to.beFalsy();
  expect(menu.itemViewModels[2].selected).to.beTruthy();
  expect(menu.itemViewModels.count).to.equal(itemModels.count);
});

it(@"should tap item", ^{
  [menu didTapItemAtIndex:1];
  expect(menu.selectedItem).to.equal(itemModels[1]);
  expect(menu.itemViewModels[0].selected).to.beFalsy();
  expect(menu.itemViewModels[1].selected).to.beTruthy();
  expect(menu.itemViewModels[2].selected).to.beFalsy();
});

it(@"should raise an exception when tap out of bounds", ^{
  expect(^{
    [menu didTapItemAtIndex:3];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise an exception when selected item is not from items", ^{
  CUIMenuItemModel *otherItem = [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"otherItem"
                                                                         iconURL:kTestURL key:@""];
  expect(^{
    CUISingleChoiceMenuViewModel __unused *newMenu =
        [[CUISingleChoiceMenuViewModel alloc] initWithItemModels:itemModels selectedItem:otherItem];
  }).to.raise(NSInvalidArgumentException);

  expect(^{
    [menu setItemModels:itemModels selectedItem:otherItem];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should update item models", ^{
  NSArray<CUIMenuItemModel *> *newItemModels = @[
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"1" iconURL:kTestURL key:@""],
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"2" iconURL:kTestURL key:@""]
  ];
  [menu setItemModels:newItemModels selectedItem:newItemModels[1]];
  expect(menu.selectedItem).to.equal(newItemModels[1]);
  expect(menu.itemViewModels[0].selected).to.beFalsy();
  expect(menu.itemViewModels[1].selected).to.beTruthy();
  expect(menu.itemViewModels.count).to.equal(newItemModels.count);
});

it(@"should mark all items with equal models as selected", ^{
  NSArray<CUIMenuItemModel *> *newItemModels = @[
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"1" iconURL:kTestURL key:@""],
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"2" iconURL:kTestURL key:@""],
    [[CUIMenuItemModel alloc] initWithLocalizedTitle:@"1" iconURL:kTestURL key:@""]
  ];
  [menu setItemModels:newItemModels selectedItem:newItemModels[0]];
  expect(menu.selectedItem).to.equal(newItemModels[0]);
  expect(menu.itemViewModels[0].selected).to.beTruthy();
  expect(menu.itemViewModels[1].selected).to.beFalsy();
  expect(menu.itemViewModels[2].selected).to.beTruthy();
});

SpecEnd
