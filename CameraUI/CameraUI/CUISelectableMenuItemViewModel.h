// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIMenuItemModel.h"
#import "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// View model for displaying a \c CUIMenuItemModel. Has a writable \c selected property that can be
/// set to indicate that this menu item is selected. The view model data is derived from
/// \c menuItemModel, its \c hidden property is always <tt> NO, subitems </tt> is \c nil and the
/// \c didTap method has no effect.
@interface CUISelectableMenuItemViewModel : NSObject <CUIMenuItemViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the view model with a model.
- (instancetype)initWithMenuItemModel:(CUIMenuItemModel *)menuItemModel NS_DESIGNATED_INITIALIZER;

/// This menu item model.
@property (readonly, nonatomic) CUIMenuItemModel *menuItemModel;

/// \c YES if this menu item is selected.
@property (nonatomic) BOOL selected;

@end

NS_ASSUME_NONNULL_END
