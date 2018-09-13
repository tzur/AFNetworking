// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WFTransparentView.h"

NS_ASSUME_NONNULL_BEGIN

@class WFFloatView;

/// Locations in the float view the content can be snapped to.
LTEnumDeclare(NSUInteger, WFFloatViewAnchor,
  WFFloatViewAnchorTopCenter,
  WFFloatViewAnchorBottomCenter,
  WFFloatViewAnchorTopLeft,
  WFFloatViewAnchorTopLeftDock,
  WFFloatViewAnchorTopRight,
  WFFloatViewAnchorTopRightDock,
  WFFloatViewAnchorBottomLeft,
  WFFloatViewAnchorBottomLeftDock,
  WFFloatViewAnchorBottomRight,
  WFFloatViewAnchorBottomRightDock
);

/// Category providing properties for a \c WFFloatViewAnchor enum value.
@interface WFFloatViewAnchor (Properties)

/// \c YES if the \c WFFloatViewAnchor is a dock anchor.
@property (readonly, nonatomic) BOOL isDock;

@end

/// Protocol for handling state changes of the float view. At any time after loading the view and
/// setting its \c contentView, it can be in one of three states:
///
/// - Content is dragged by the user using pan gesture.
///
/// - Content is animating towards a specific anchor.
///
/// - Content is snapped to a specific anchor.
///
/// This protocol contains a method for handling the start of each of these states.
@protocol WFFloatViewDelegate <NSObject>

@optional

/// Called when the \c floatView is about to start dragging its content. Dragging starts when a pan
/// gesture on the content begins.
- (void)floatViewWillBeginDragging:(WFFloatView *)floatView;

/// Called when the content of the \c floatView is about to start animating towards \c anchor. It is
/// not guaranteed the content will be snapped to \c anchor because the animation might be
/// interrupted by user dragging of the content.
- (void)floatView:(WFFloatView *)floatView willBeginAnimatingTo:(WFFloatViewAnchor *)anchor;

/// Called after the content of the \c floatView is snapped to \c anchor. When this method is
/// called the animation towards the \c anchor has finished and the content rests in the \c anchor.
- (void)floatView:(WFFloatView *)floatView didSnapTo:(WFFloatViewAnchor *)anchor;

@end

/// View with a floating content. The content can be dragged in the bounds of the float view by pan
/// gesture, and when gesture ends it is animated to one of the anchors of the float view. After the
/// animation is finished the content rests in the anchor it was animated to, or in other words, it
/// is snapped. A dock is a special type of anchor. When the content is snapped to a dock, part of
/// the content can be outside the float view boundaries and thus this part is invisible. The
/// snapping logic to a dock is different (see below).
///
/// The application should not add subviews to the float view. It can supply the floating content by
/// setting the \c contentView, but not add subviews directly to the float view. If content is
/// needed below the float view it should be added to the super view of the float view. The float
/// view, apart from the \c contentView itself, is transparent in color, and also transparent to
/// touches, and thus does not effect the content below it.
///
/// The non dock corner anchors are not active when the content width is large, and the only active
/// non dock anchors in this case are the center anchors. When the content width is small, the
/// center anchors are not active, and the only non dock anchors in this case are the corner
/// anchors.
///
/// The snapping can be either a location based snapping or a velocity based snapping depending on
/// the magnitude of the velocity at the end of the gesture. A location based snapping occurs when
/// the magnitude is low. Such snapping is to the closest non dock anchor at the end of the pan
/// gesture. A velocity based snapping of the content can be to any anchor of the float view,
/// depending on the velocity at the end of the pan gesture. In addition, velocity based snapping
/// from a dock anchor is never to a dock anchor.
///
/// The floating content contains a content view provided by the application, and above it a visual
/// effect view. The \c UIVisualEffect of this view is the \c visualEffect property of the float
/// view that can be set by the user. The alpha value of the visual effect view is dependent on the
/// position of the content. It is transparent in a non dock anchor, and opaque in a dock. Accessory
/// views are located at the left and right edges of the visual effect view. When docked, the
/// visible width of the content is the accessory view width and the rest of the content is located
/// outside the boundaries of the float view.
@interface WFFloatView : WFTransparentView

/// Sets the center of the given \c contentView and animate its movement from the given
/// \c initialPosition (in the receiver's coordinate system) to the given \c anchor. If
/// \c contentView is \c nil, the content will have zero size and thus will not be visible. If
/// \c initialPosition is \c CGPointNull, the position of the previous content will be used as
/// initial position.
- (void)setContentView:(UIView * _Nullable)contentView initialPosition:(CGPoint)initialPosition
          snapToAnchor:(WFFloatViewAnchor *)anchor;

/// Initiate a location based snapping. Can be used in order to undock the content. The snapping is
/// initiated even if the content is currently dragged by the user. If another snapping is currently
/// taking place it is stopped and the new snapping starts from the location the old snapping was
/// stopped at.
- (void)snapToClosestNonDockAnchor;

/// Content that floats inside the boundaries of the float view. Defaults to \c nil. Can be set by
/// <tt> -[WFFloatView setContentView:initialPosition:snapToAnchor:] </tt>.
@property (readonly, nonatomic, nullable) UIView *contentView;

/// Visual effect for the content view. Its alpha is \c 0 when the content view is snapped to a non
/// dock anchor, and \c 1 when it is docked. For no visual effect set \c nil, which is also the
/// default value.
@property (strong, nonatomic, nullable) UIVisualEffect *visualEffect;

/// Accessory view on the left side of the visual effect view. Its left edge is the left edge of the
/// content. Its width is \c leftAccessoryViewWidth. Its height is the content height, and its top
/// edge is on the content top edge. If \c leftAccessoryViewWidth is positive, only the left
/// accessory view is visible when the content is docked to a right dock and the rest of the content
/// is located outside the boundaries of the float view. If \c leftAccessoryViewWidth is not
/// positive, the whole content is visible when docked to a right dock.
@property (readonly, nonatomic) UIView *leftAccessoryView;

/// Width of the left accessory view. Defaults to \c 0.
@property (nonatomic) CGFloat leftAccessoryViewWidth;

/// Accessory view on the right side of the visual effect view. Its right edge is the right edge of
/// the content. Its width is \c rightAccessoryViewWidth. Its height is the content height, and its
/// top edge is on the content top edge. If \c rightAccessoryViewWidth is positive, only the right
/// accessory view is visible when the content is docked to a left dock and the rest of the content
/// is located outside the boundaries of the float view. If \c rightAccessoryViewWidth is not
/// positive, the whole content is visible when docked to a left dock.
@property (readonly, nonatomic) UIView *rightAccessoryView;

/// Width of the right accessory view. Defaults to \c 0.
@property (nonatomic) CGFloat rightAccessoryViewWidth;

/// Anchors are located in positions that will create insets between the edges of the float view and
/// edges of the snapped content. Each inset length is the corresponding value of \c snapInsets.
/// When docked, the inset for the content edge that is out of the float view bounds is ignored.
/// Default value is \c 8 for each inset.
@property (nonatomic) UIEdgeInsets snapInsets;

/// Delegate for tracking the state of the float view.
@property (weak, nonatomic, nullable) id<WFFloatViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
