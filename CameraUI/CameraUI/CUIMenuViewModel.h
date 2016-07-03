// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for menu view models.
@protocol CUIMenuViewModel <NSObject>

/// Inform the menu that the item at \c itemIndex was tapped.
- (void)didTapItemAtIndex:(NSUInteger)itemIndex;

/// Items view models, each view model controls an item in the menu.
@property (readonly, nonatomic) NSArray<id<CUIMenuItemViewModel>> *itemViewModels;

@end

NS_ASSUME_NONNULL_END
