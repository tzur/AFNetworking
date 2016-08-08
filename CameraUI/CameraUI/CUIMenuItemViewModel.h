// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a view-model of menu item which is part of a hierarchical menu. The menu item may
/// contain sub-items, and it is up to the view how to display this item and its sub-items.
@protocol CUIMenuItemViewModel <NSObject>

/// Should be called after the view was tapped.
- (void)didTap;

/// Title of the item, \c nil value means this item has no title.
@property (readonly, nonatomic, nullable) NSString *title;

/// Icon URL for the item, \c nil value means this item has no icon.
@property (readonly, nonatomic, nullable) NSURL *iconURL;

/// \c YES if the item is selected.
@property (readonly, nonatomic) BOOL selected;

/// \c YES if the view should be hidden.
@property (readonly, nonatomic) BOOL hidden;

/// Signal of \c BOOL values that signals whether the view should be enabled.
@property (strong, nonatomic) RACSignal *enabledSignal;

/// Last value that was sent over \c enabledSignal.
@property (readonly, nonatomic) BOOL enabled;

/// List of subitems of this item. \c nil value means the item has no subitems.
@property (readonly, nonatomic, nullable) NSArray<id<CUIMenuItemViewModel>> *subitems;

@end

NS_ASSUME_NONNULL_END
