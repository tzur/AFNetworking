// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIMenuItemModel.h"
#import "CUIMenuViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Menu view model with exactly one menu item selected at a given time. This view model is
/// initialized with an array of \c CUIMenuItemModel that define the menu items.
///
/// @note If the array holds a group of equal \c CUIMenuItemModels, they will all be considered as
/// representing the same state, selecting one item will mark its whole group as selected.
@interface CUISingleChoiceMenuViewModel : NSObject <CUIMenuViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes this menu model with \c itemModels array, and selects \c selectedItem.
- (instancetype)initWithItemModels:(NSArray<CUIMenuItemModel *> *)itemModels
                      selectedItem:(CUIMenuItemModel *)selectedItem NS_DESIGNATED_INITIALIZER;

/// Sets a new \c itemModels array, and selects \c selectedItem.
- (void)setItemModels:(NSArray<CUIMenuItemModel *> *)itemModels
         selectedItem:(CUIMenuItemModel *)selectedItem;

/// Currently selected item.
@property (readonly, nonatomic) CUIMenuItemModel *selectedItem;

@end

NS_ASSUME_NONNULL_END
