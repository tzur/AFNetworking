// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUISingleChoiceMenuViewModel.h"

#import "CUISelectableMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUISingleChoiceMenuViewModel ()

/// Items view models, each view model controls an item in the menu.
@property (strong, nonatomic) NSArray<CUISelectableMenuItemViewModel *> *itemViewModels;

/// Currently selected item.
@property (readwrite, nonatomic) CUIMenuItemModel *selectedItem;

@end

@implementation CUISingleChoiceMenuViewModel

- (instancetype)initWithItemModels:(NSArray<CUIMenuItemModel *> *)itemModels
                      selectedItem:(CUIMenuItemModel *)selectedItem {
  if (self = [super init]) {
    [self setItemModels:itemModels selectedItem:selectedItem];
  }
  return self;
}

- (void)setItemModels:(NSArray<CUIMenuItemModel *> *)itemModels
         selectedItem:(CUIMenuItemModel *)selectedItem {
  LTParameterAssert([itemModels containsObject:selectedItem],
                   @"Selected item must be one of the menu items");
  [self setItemModels:itemModels];
  self.selectedItem = selectedItem;
}

- (void)setItemModels:(NSArray<CUIMenuItemModel *> *)itemModels {
  self.itemViewModels = [itemModels.rac_sequence
      map:(id)^CUISelectableMenuItemViewModel *(CUIMenuItemModel *itemModel) {
        return [[CUISelectableMenuItemViewModel alloc] initWithMenuItemModel:itemModel];
      }].array;
}

- (void)setSelectedItem:(CUIMenuItemModel *)selectedItem {
  _selectedItem = selectedItem;
  for (CUISelectableMenuItemViewModel *itemViewModel in self.itemViewModels) {
    itemViewModel.selected = [itemViewModel.menuItemModel isEqual:selectedItem];
  }
}

#pragma mark -
#pragma mark CUISingleChoiceMenuViewModel
#pragma mark -

- (void)didTapItemAtIndex:(NSUInteger)itemIndex {
  LTParameterAssert(itemIndex >= 0 && itemIndex < self.itemViewModels.count,
      @"item index is out of bounds");
  self.selectedItem = self.itemViewModels[itemIndex].menuItemModel;
}

@end

NS_ASSUME_NONNULL_END
