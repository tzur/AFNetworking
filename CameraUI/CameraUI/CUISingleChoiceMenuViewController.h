// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUISingleChoiceMenuViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Presents a left-to-right scrollable menu. The menu is comprised of menu item cells, only one
/// menu item can be selected at any given time. This menu does not support submenus, model submenus
/// are ignored.
@interface CUISingleChoiceMenuViewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithNibName:(nullable NSString *)nibName
                         bundle:(nullable NSBundle *)bundle NS_UNAVAILABLE;

/// Initializes this menu with a view model and <tt>cellClass. cellClass</tt> is used as the menu
/// cells. \c cellClass must inherit from \c UICollectionViewCell and conform to the
/// \c CUIMutableMenuItemView protocol.
- (instancetype)initWithMenuViewModel:(CUISingleChoiceMenuViewModel *)menuViewModel
                            cellClass:(Class)cellClass NS_DESIGNATED_INITIALIZER;

/// Number of menu items per row. This number must be strictly positive but can have a fraction
/// part, meaning the last item will only be partially visible. Default value is 5.5.
@property (nonatomic) CGFloat itemsPerRow;

@end

NS_ASSUME_NONNULL_END
