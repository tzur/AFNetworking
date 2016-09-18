// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

@class CUIDropDownEntryViewModel;

/// Horizontal drop down bar view with horizontal drop down submenus.
///
/// This drop-down arranges the main bar entry views horizontally, distributes them with equal
/// spacing around the center of this view, and redistributes them whenever the \c hidden property
/// of one of them changes. The \c height of the entry views are set according to the
/// height of this view, while the \c width is equal or greater than the \c height of this view.
///
/// The drop-down submenus are displayed horizontly with the same \c width and \c height as the
/// main bar. The submenu items are displayed relatively to the main bar items, and the same sizing
/// and distribution rules apply to them.
///
/// This view contains views with the accessibility identifiers "MainBarStackView",
/// "SubmenuView#%d" where \c %d is the ordinal of its main bar item. Each submenu view has view
/// with the accessibility identifiers "SubmenuStackView".
@interface CUIDropDownHorizontalView : UIView

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Hides the shown drop down views till next tap on their \c mainBarItemView parent view.
- (void)hideDropDownViews;

/// Array of \c CUIDropDownEntryViewModel objects that this view shows. Defaults to an empty array,
/// meaning no items are displayed in the bar.
///
/// The \c mainBarItemView views are presented from left to right according to the order here, and
/// submenu items are also presented from left to right according to their order in \c subitems.
///
/// @note view of main bar item that has subitems must be a class or subclass of \c UIControl.
@property (copy, nonatomic) NSArray<CUIDropDownEntryViewModel *> *entries;

/// Maximum distance between the left edge of the first entry to the right edge of the last entry.
/// Default value is \c 450.
@property (nonatomic) CGFloat maxMainBarWidth;

/// Minimum lateral margins between the lateral edges of this view to the leftmost and rightmost
/// main bar items.
@property (nonatomic) CGFloat lateralMargins;

/// Lateral margins of the submenus relative to the leftmost and rightmost main bar items.
@property (nonatomic) CGFloat submenuLateralMargins;

/// Background color of the submenus. Default color is <tt>[UIColor clearColor]</tt>
@property (strong, nonatomic) UIColor *submenuBackgroundColor;

@end

NS_ASSUME_NONNULL_END
