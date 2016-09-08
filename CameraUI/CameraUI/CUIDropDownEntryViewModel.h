// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

@protocol CUIMenuItemViewModel;

/// View-model for an entry in a drop down view.
@interface CUIDropDownEntryViewModel : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c mainBarItem as the item that should be presented in the main bar
/// of the drop down view, \c mainBarItemViewClass as the view that should present the item, and
/// \c submenuItemsViewClass as the view that should present the item's \c subitems (if exist).
///
/// @note the \c mainBarItemViewClass and \c submenuItemsViewClass must be a \c UIView that confroms
/// to the \c CUIMenuItemView protocol, otherwise \c NSInvalidArgumentException is raised.
- (CUIDropDownEntryViewModel *)initWithMainBarItem:(id<CUIMenuItemViewModel>)mainBarItem
                              mainBarItemViewClass:(Class)mainBarItemViewClass
                             submenuItemsViewClass:(Class)submenuItemsViewClass;

/// Item that should be presented in the main bar of the drop down view.
@property (readonly, nonatomic) id<CUIMenuItemViewModel> mainBarItem;

/// \c Class of the view that should present \c mainBarItem.
@property (readonly, nonatomic) Class mainBarItemViewClass;

/// \c Class of the view that should present the subitems of \c mainBarItem.
@property (readonly, nonatomic) Class submenuItemsViewClass;

@end

NS_ASSUME_NONNULL_END
