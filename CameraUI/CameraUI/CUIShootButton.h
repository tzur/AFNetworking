// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIShootButtonDrawer.h"

NS_ASSUME_NONNULL_BEGIN

/// \c UIControl that conforms to the \c CUIShootButtonTraits protocol and serves as a shoot button.
/// The look of this view is determined according to a given list of \c CUIShootButtonDrawer objects
/// that draw inside this view.
@interface CUIShootButton : UIControl <CUIShootButtonTraits>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Initializes this object with the given \c drawers. The order of drawing of the given
/// \c CUIShootButtonDrawer objects is the same as their order in the given \c NSArray.
- (instancetype)initWithDrawers:(NSArray<id<CUIShootButtonDrawer>> *)drawers;

/// Progress of the shooting (e.g. progress of the timer before next frame capture). The values
/// must be in the range [0, 1].
@property (nonatomic) CGFloat progress;

@end

NS_ASSUME_NONNULL_END
