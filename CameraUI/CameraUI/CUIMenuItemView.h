// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

@protocol CUIMenuItemViewModel;

/// Protocol for a \c UIView that shows a menu item in a menu view.
@protocol CUIMenuItemView <NSObject>

/// Initializes this object with the given \c model as a view-model for this view.
- (instancetype)initWithModel:(id<CUIMenuItemViewModel>)model;

/// The view-model of this view (i.e. the \c model that was given in \c initWithModel).
@property (readonly, nonatomic) id<CUIMenuItemViewModel> model;

@end

NS_ASSUME_NONNULL_END
