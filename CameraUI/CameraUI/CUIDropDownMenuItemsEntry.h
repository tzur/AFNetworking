// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownEntry.h"

@protocol CUIMenuItemViewModel;

NS_ASSUME_NONNULL_BEGIN

/// Object that implements the \c CUIDropDownEntry protocol for a given \c CUIMenuItemViewModel
/// object.
///
/// For the \c mainBarItemView it generates a \c UIButton that conforms to the \c CUIMenuItemButton
/// protocol that shows the given \c CUIMenuItemViewModel object.
///
/// For the \c submenuView it generates a view that contains \c UIButtons that conform to the
/// \c CUIMenuItemButton protocol. These \c UIButtons show the \c subitems of the given
/// \c CUIMenuItemViewModel object, and are orderd verticaly according to the \c subitems order.
///
/// \c submenuView contains a \c UIStackView with accessibility identifier "StackView".
@interface CUIDropDownMenuItemsEntry : NSObject <CUIDropDownEntry>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes this object with the given \c item, and the \c Class of the views that should show
/// this item and its subitems.
///
/// The \c mainBarItemViewClass and \c submenuItemViewClass must be a \c UIButton that confroms to
/// the \c CUIMenuItemButton protocol, otherwise \c NSInvalidArgumentException is raised.
- (instancetype)initWithItem:(id<CUIMenuItemViewModel>)item
        mainBarItemViewClass:(Class)mainBarItemViewClass
        submenuItemViewClass:(Class)submenuItemViewClass NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
