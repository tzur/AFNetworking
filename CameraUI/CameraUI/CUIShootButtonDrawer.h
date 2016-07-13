// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for shoot button traits needed by \c CUIShootButtonDrawer objects in order to draw
/// inside shoot buttons.
@protocol CUIShootButtonTraits <NSObject>

/// Bounds of the shoot button.
@property (readonly, nonatomic) CGRect bounds;

/// \c YES if the shoot button is enabled.
@property (readonly, nonatomic, getter=isEnabled) BOOL enabled;

/// \c YES if the shoot button is highlighted.
@property (readonly, nonatomic, getter=isHighlighted) BOOL highlighted;

/// Progress of the shooting (e.g. progress of the timer before next frame capture). The values
/// must be in the range [0, 1].
@property (readonly, nonatomic) CGFloat progress;

@end

/// Protocol for objects that draw inside a shoot button (e.g. draw oval, ring etc.).
@protocol CUIShootButtonDrawer <NSObject>

/// Draws inside a shoot button according to the given \c buttonTraits object. This method is
/// expected to be called from within \c drawRect:, and it draws to the current \c CGContext (it
/// doesn't create/change the \c CGContext).
- (void)drawToButton:(id<CUIShootButtonTraits>)buttonTraits;

@end

/// \c CUIShootButtonDrawer that draws a filled oval shape centered at the center of the given
/// button's bounds.
@interface CUIOvalDrawer : NSObject <CUIShootButtonDrawer>

/// Size of the bounding box of the oval.
@property (nonatomic) CGSize size;

/// Color that fills the oval when the button is not highlighted. \c nil value is the same as
/// \c clearColor.
@property (strong, nonatomic, nullable) UIColor *color;

/// Color that fills the oval when the button is highlighted. \c nil value is the same as
/// \c clearColor.
@property (strong, nonatomic, nullable) UIColor *highlightColor;

@end

/// \c CUIShootButtonDrawer that draws a filled rect shape centered at the center of the given
/// button's bounds.
@interface CUIRectDrawer : NSObject <CUIShootButtonDrawer>

/// Size of the rect.
@property (nonatomic) CGSize size;

/// Corner radius of the rectangle. A value of 0 results in a rectangle without rounded corners.
/// Values larger than half the rectangle’s width or height are clamped appropriately to half the
/// width or height.
@property (nonatomic) CGFloat cornerRadius;

/// Color that fills the rect when the button is not highlighted. \c nil value is the same as
/// \c clearColor.
@property (strong, nonatomic, nullable) UIColor *color;

/// Color that fills the rect when the button is highlighted. \c nil value is the same as
/// \c clearColor.
@property (strong, nonatomic, nullable) UIColor *highlightColor;

@end

/// \c CUIShootButtonDrawer that draws an arc shape centered at the center of the given button's
/// bounds.
@interface CUIArcDrawer : NSObject <CUIShootButtonDrawer>

/// Radius of the arc. Measured at the center of the arc's width.
@property (nonatomic) CGFloat radius;

/// Width of the arc.
@property (nonatomic) CGFloat width;

/// Color used for the arc. \c nil value is the same as \c clearColor.
@property (strong, nonatomic, nullable) UIColor *color;

/// Starting angle of the arc (measured in radians). \0 is at the right.
@property (nonatomic) CGFloat startAngle;

/// End angle of the arc (measured in radians). \0 is at the right.
@property (nonatomic) CGFloat endAngle;

/// Direction in which to draw the arc. \c YES for clockwise direction.
@property (nonatomic) BOOL clockwise;

@end

/// \c CUIShootButtonDrawer that draws an arc shape centered at the center of the given button's
/// bounds. The length of the arc is determined according to the \c progress property of the given
/// \c CUIShootButtonTraits object. For \c progress with value of 1 it draws a circle, and for
/// value 0 it draws nothing.
@interface CUIProgressRingDrawer : NSObject <CUIShootButtonDrawer>

/// Radius of the ring. Measured at the center of the ring's width.
@property (nonatomic) CGFloat radius;

/// Width of the ring.
@property (nonatomic) CGFloat width;

/// Color used for the ring. \c nil value is the same as \c clearColor.
@property (strong, nonatomic, nullable) UIColor *color;

/// Starting angle of the ring (measured in radians). \0 is at the right.
@property (nonatomic) CGFloat startAngle;

/// Direction in which to draw the ring. \c YES for clockwise direction.
@property (nonatomic) BOOL clockwise;

@end

NS_ASSUME_NONNULL_END
