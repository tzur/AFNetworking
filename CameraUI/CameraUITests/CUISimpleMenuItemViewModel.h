// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Object that implements the \c CUIMenuItemViewModel by re-defining the protocol's properties as
/// \c readwrite, and counts the number of times \c didTap was called.
@interface CUISimpleMenuItemViewModel : NSObject <CUIMenuItemViewModel>

/// Title of the item, \c nil value means this item has no title.
@property (strong, readwrite, nonatomic, nullable) NSString *title;

/// Icon URL for the item, \c nil value means this item has no icon.
@property (strong, readwrite, nonatomic, nullable) NSURL *iconURL;

/// \c YES if the item is selected.
@property (readwrite, nonatomic) BOOL selected;

/// \c YES if the view should be hidden.
@property (readwrite, nonatomic) BOOL hidden;

/// List of subitems of this item. \c nil value means the item has no subitems.
@property (strong, readwrite, nonatomic, nullable) NSArray<id<CUIMenuItemViewModel>> *subitems;

/// Number of times \c didTap was called.
@property (readonly, nonatomic) NSUInteger didTapCounter;

@end

NS_ASSUME_NONNULL_END
