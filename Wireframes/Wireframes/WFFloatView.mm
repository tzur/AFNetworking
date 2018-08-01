// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WFFloatView.h"

#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

/// Configuration parameters for \c WFFloatView.
typedef struct {
  /// Effective mass of the floating view. Used for the spring animation of the floating view. This
  /// value must be greater than \c 0.
  CGFloat mass;

  /// Damping force to apply to the spring animation of the floating view.
  CGFloat damping;

  /// Spring stiffness coefficient for the spring animation of the floating view to a non dock
  /// anchor.
  CGFloat nonDockStiffness;

  /// Spring stiffness coefficient for the spring animation of the floating view to a dock anchor.
  CGFloat dockStiffness;

  /// Initial velocity of the floating view animation is derived from the pan gesture end velocity.
  /// This property is appended to each component (\c x and \c y) of the calculated initial velocity
  /// value.
  CGFloat initialVelocityAddition;

  /// The magnitude of the initial velocity in case of location based snapping, not including the
  /// \c initialVelocityAddition. When a location based snapping is about to strat, the initial
  /// velocity vector is calculated as follows: its direction is the direction of the line from the
  /// current location to the closest non dock anchor, its magnitude is the value of
  /// \c locationBasedSnappingVelocity. After it is calculated, \c initialVelocityAddition is added
  /// to each of its components and the result is the input initial velocity for the animation.
  CGFloat locationBasedSnappingVelocity;

  /// Minimal velocity magnitude in x axis direction required for docking.
  CGFloat minXDockingVelocity;

  /// Minimal ratio between content width to float view width that allows snapping to center anchors
  /// instead of corner anchors.
  CGFloat minWidthRatioForCenterAnchors;

  /// The fraction of the content that should be horizontally hidden in order for visual effect to
  /// be shown when dragging the content. The alpha value of the visual effect is \c 0  when
  /// \c hiddenContentFractionForVisualEffectVisibility of the content is horizontally hidden, and
  /// grows linrearly to \c 1 when dragged to the x position of the docks. Value must be between
  /// \c 0 and \c 1. If value is \c 0 then the visual effect will start to apprear when one of the
  /// horizontal content edges is on the horizontal edge of the float view.
  CGFloat hiddenContentFractionForVisualEffectVisibility;
} WFFloatViewConfig;

/// Locations in the float view the content can be snapped to.
LTEnumImplement(NSUInteger, WFFloatViewAnchor,
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

@implementation WFFloatViewAnchor (Properties)

- (BOOL)isDock {
  switch (self.value) {
    case WFFloatViewAnchorTopLeftDock:
    case WFFloatViewAnchorTopRightDock:
    case WFFloatViewAnchorBottomLeftDock:
    case WFFloatViewAnchorBottomRightDock:
      return YES;
    default:
      return NO;
  }
}

@end

/// Category for a \c WFFloatViewAnchor enum value providing information about the value that is
/// usefull for \c WFFloatView internal implementation.
@interface WFFloatViewAnchor (WFFloatView)

/// \c YES if the \c WFFloatViewAnchor is a non dock corner anchor.
@property (readonly, nonatomic) BOOL isCorner;

/// \c YES if the \c WFFloatViewAnchor is a center anchor.
@property (readonly, nonatomic) BOOL isCenter;

/// The dock that is located at the same edges as the receiver. \c nil if the receiver is not a
/// corner.
@property (readonly, nonatomic, nullable) WFFloatViewAnchor *dockOfCorner;

/// The center anchor that is located at the same horizontal edge as the receiver. \c nil if the
/// receiver is not a corner.
@property (readonly, nonatomic, nullable) WFFloatViewAnchor *centerAnchorOfCorner;

@end

@implementation WFFloatViewAnchor (WFFloatView)

- (BOOL)isCorner {
  switch (self.value) {
    case WFFloatViewAnchorTopLeft:
    case WFFloatViewAnchorTopRight:
    case WFFloatViewAnchorBottomLeft:
    case WFFloatViewAnchorBottomRight:
      return YES;
    default:
      return NO;
  }
}

- (BOOL)isCenter {
  switch (self.value) {
    case WFFloatViewAnchorTopCenter:
    case WFFloatViewAnchorBottomCenter:
      return YES;
    default:
      return NO;
  }
}

- (nullable WFFloatViewAnchor *)dockOfCorner {
  switch (self.value) {
    case WFFloatViewAnchorTopLeft:
      return $(WFFloatViewAnchorTopLeftDock);
    case WFFloatViewAnchorTopRight:
      return $(WFFloatViewAnchorTopRightDock);
    case WFFloatViewAnchorBottomLeft:
      return $(WFFloatViewAnchorBottomLeftDock);
    case WFFloatViewAnchorBottomRight:
      return $(WFFloatViewAnchorBottomRightDock);
    default:
      return nil;
  }
}

- (nullable WFFloatViewAnchor *)centerAnchorOfCorner {
  switch (self.value) {
    case WFFloatViewAnchorTopLeft:
    case WFFloatViewAnchorTopRight:
      return $(WFFloatViewAnchorTopCenter);
    case WFFloatViewAnchorBottomLeft:
    case WFFloatViewAnchorBottomRight:
      return $(WFFloatViewAnchorBottomCenter);
    default:
      return nil;
  }
}

@end

@interface WFFloatView ()

/// Floating view containing the view from the user and the visual effect view above it.
@property (readonly, nonatomic) UIView *floatingView;

/// For animating the floating view.
@property (strong, nonatomic, nullable) UIViewPropertyAnimator *animator;

/// For reacting to dragging the floating view.
@property (strong, nonatomic, nullable) UIPanGestureRecognizer *floatingViewPanGestureRecognizer;

/// The anchor the floating view is currently snapped to or animating towards. If the user starts
/// dragging the floating view, the value does not change. It changes when a new snapping animation
/// is about to start. Defaults to \c WFFloatViewAnchorTopLeft.
@property (nonatomic) WFFloatViewAnchor *currentAnchor;

/// Desired content center coordinates after the next layout cycle. \c CGPointNull if there is no
/// need to change the content center coordinates after the next layout cycle. Defaults to
/// \c CGPointNull.
@property (nonatomic) CGPoint contentCenterNewLocation;

/// \c YES if the next snapping can be to a dock anchor.
@property (nonatomic) BOOL dockingAllowed;

/// For visual effect above the floating view. Containing accessory views on its sides. The
/// accessory views are exposed to the application in the external API, and the application can add
/// subviews to them.
@property (readonly, nonatomic) UIVisualEffectView *visualEffectView;

/// Configuration parameters.
@property (readonly, nonatomic) WFFloatViewConfig config;

@end

@implementation WFFloatView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.contentCenterNewLocation = CGPointNull;
    self.snapInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    self.currentAnchor = $(WFFloatViewAnchorTopLeft);
    self.dockingAllowed = YES;
    _config = [self defaultConfig];
    [self setupFloatingView];
    [self setupVisualEffectView];
    [self setupLeftAccessoryView];
    [self setupRightAccessoryView];
  }
  return self;
}

- (WFFloatViewConfig)defaultConfig {
  return {
    .mass = 0.025,
    .damping = 8,
    .dockStiffness = 8,
    .nonDockStiffness = 5,
    .initialVelocityAddition = 10,
    .locationBasedSnappingVelocity = 650,
    .minXDockingVelocity = 2800,
    .minWidthRatioForCenterAnchors = 0.75,
    .hiddenContentFractionForVisualEffectVisibility = 0.4
  };
}

- (void)setupFloatingView {
  _floatingView = [[UIView alloc] initWithFrame:CGRectZero];
  self.floatingViewPanGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                           initWithTarget:self action:@selector(floatingViewPan:)];
  [self.floatingView addGestureRecognizer:self.floatingViewPanGestureRecognizer];
  [self addSubview:self.floatingView];
}

- (void)setupVisualEffectView {
  _visualEffectView = [[UIVisualEffectView alloc] initWithEffect:nil];
  [self.floatingView addSubview:self.visualEffectView];
}

- (void)setupLeftAccessoryView {
  _leftAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
  [self.visualEffectView.contentView addSubview:self.leftAccessoryView];
}

- (void)setupRightAccessoryView {
  _rightAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
  [self.visualEffectView.contentView addSubview:self.rightAccessoryView];
}

- (void)layoutSubviews {
  [super layoutSubviews];

  auto contentOrigin = self.floatingView.frame.origin;
  auto contentSize = self.contentView.frame.size;

  self.floatingView.frame = CGRectFromOriginAndSize(contentOrigin, contentSize);

  if (!CGPointIsNull(self.contentCenterNewLocation)) {
    self.floatingView.center = self.contentCenterNewLocation;
    self.contentCenterNewLocation = CGPointNull;
  }

  self.contentView.frame = CGRectFromOriginAndSize(CGPointZero, contentSize);
  self.visualEffectView.frame = CGRectFromOriginAndSize(CGPointZero, contentSize);

  auto leftAccessoryViewSize = CGSizeMake(self.leftAccessoryViewWidth, contentSize.height);
  self.leftAccessoryView.frame = CGRectFromOriginAndSize(CGPointZero, leftAccessoryViewSize);

  auto rightAccessoryViewSize = CGSizeMake(self.rightAccessoryViewWidth, contentSize.height);
  auto rightAccessoryViewOrigin = CGPointMake(contentSize.width - rightAccessoryViewSize.width, 0);
  self.rightAccessoryView.frame = CGRectFromOriginAndSize(rightAccessoryViewOrigin,
                                                          rightAccessoryViewSize);

  [self stopAnimation];
  [self animateTo:self.currentAnchor];
}

// Allow interaction with the floating view and its subviews while animating.
- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event {
  if (![self pointInside:point withEvent:event]) {
    return nil;
  }
  if (self.animator && self.animator.state == UIViewAnimatingStateActive) {
    // Check if hit test point is in the animating floating view presentation layer.
    if ([self.floatingView.layer.presentationLayer hitTest:point]) {
      // Get coordinates of the point in the animating floating view presentation layer coordinate
      // system. They are equal to the coordinates of the point we want to interact with in the
      // floating view coordinates system.
      point = [self.floatingView.layer.presentationLayer convertPoint:point fromLayer:self.layer];
      // After point converted, hit test the floating view.
      return [self.floatingView hitTest:point withEvent:event];
    }
    // Point is out of the presentation layer of the floating view, and there are no other subviews
    // so self is returned.
    return self;
  }
  return [super hitTest:point withEvent:event];
}

- (void)setContentView:(UIView * _Nullable)contentView initialPosition:(CGPoint)initialPosition
          snapToAnchor:(WFFloatViewAnchor *)anchor {
  [self.contentView removeFromSuperview];
  _contentView = contentView;
  self.contentCenterNewLocation = initialPosition;
  if (!self.contentView) {
    return;
  }

  [self.floatingView insertSubview:self.contentView belowSubview:self.visualEffectView];

  self.currentAnchor = anchor;
  [self setNeedsLayout];
}

- (void)setSnapInsets:(UIEdgeInsets)snapInsets {
  _snapInsets = snapInsets;
  [self setNeedsLayout];
}

- (nullable UIVisualEffect *)visualEffect {
  return self.visualEffectView.effect;
}

- (void)setVisualEffect:(nullable UIVisualEffect *)visualEffect {
  self.visualEffectView.effect = visualEffect;
}

- (void)setLeftAccessoryViewWidth:(CGFloat)leftAccessoryViewWidth {
  _leftAccessoryViewWidth = leftAccessoryViewWidth;
  [self setNeedsLayout];
}

- (void)setRightAccessoryViewWidth:(CGFloat)rightAccessoryViewWidth {
  _rightAccessoryViewWidth = rightAccessoryViewWidth;
  [self setNeedsLayout];
}

- (void)snapToClosestNonDockAnchor {
  [self stopAnimation];
  [self animateTo:[self locationBasedAnchor]];
}

- (void)floatingViewPan:(UIPanGestureRecognizer *)panGestureRecognizer {
  if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
    [self stopAnimation];
    if ([self.delegate respondsToSelector:@selector(floatViewWillBeginDragging:)]) {
      [self.delegate floatViewWillBeginDragging:self];
    }
  }

  auto translation = [panGestureRecognizer translationInView:self];
  self.floatingView.center = self.floatingView.center + translation;
  self.visualEffectView.alpha = [self visualEffectAlphaForPoint:self.floatingView.center];
  [panGestureRecognizer setTranslation:CGPointZero inView:self];

  if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
    [self animateWithVelocity:[panGestureRecognizer velocityInView:self]];
  }
}

- (void)stopAnimation {
  if (self.animator && self.animator.state == UIViewAnimatingStateActive) {
    [self.animator stopAnimation:NO];
    [self.animator finishAnimationAtPosition:UIViewAnimatingPositionCurrent];
  }
}

- (void)animateWithVelocity:(CGPoint)velocity {
  WFFloatViewAnchor *anchor;

  auto velocityMagnitude = std::hypot(velocity.x, velocity.y);
  if (velocityMagnitude < self.config.locationBasedSnappingVelocity) {
    anchor = [self locationBasedAnchor];
  } else {
    anchor = [self velocityBasedCorner:velocity];
    if ([self shouldDock:velocity]) {
      anchor = nn(anchor.dockOfCorner);
    }
  }

  if (anchor.isCorner && ![self cornerAllowed]) {
    anchor = nn(anchor.centerAnchorOfCorner);
  }

  [self animateTo:anchor velocity:velocity];
}

- (BOOL)shouldDock:(CGPoint)velocity {
  return fabs(velocity.x) > fabs(velocity.y) && self.dockingAllowed &&
      ((fabs(velocity.x) > self.config.minXDockingVelocity) ||
       (self.floatingView.center.x <= [self leftX] && velocity.x < 0) ||
       (self.floatingView.center.x >= [self rightX] && velocity.x > 0));
}

- (WFFloatViewAnchor *)locationBasedAnchor {
  auto closestCorner = [[[WFFloatViewAnchor fields]
      lt_filter:^(WFFloatViewAnchor *anchor) {
        return anchor.isCorner;
      }] lt_min:^BOOL(WFFloatViewAnchor *anchorA, WFFloatViewAnchor *anchorB) {
        return [self distanceToAnchor:anchorA] < [self distanceToAnchor:anchorB];
      }];

  return [self cornerAllowed] ? closestCorner : nn(closestCorner.centerAnchorOfCorner);
}

- (CGFloat)distanceToAnchor:(WFFloatViewAnchor *)anchor {
  auto anchorPoint = [self coordinatesOfAnchor:anchor];
  return std::hypot(anchorPoint.x - self.floatingView.center.x,
                    anchorPoint.y - self.floatingView.center.y);
}

- (BOOL)cornerAllowed {
  return CGRectGetWidth(self.floatingView.frame) <
      self.config.minWidthRatioForCenterAnchors * CGRectGetWidth(self.bounds);
}

- (WFFloatViewAnchor *)velocityBasedCorner:(CGPoint)velocity {
  // Each corner has two edges, one vertical (top or bottom) and one horizontal (left or right). If
  // the absolute value of x component of the velocity is smaller than
  // \c locationBasedSnappingVelocity choose the horizontal edge that is closer to the floating
  // view. Otherwise choose the opposite edge. Same logic is used for the y velocity component and
  // vertical edges.
  BOOL closerToTop = CGRectGetMidY(self.bounds) > self.floatingView.center.y;
  BOOL isTopCorner = closerToTop ? velocity.y < self.config.locationBasedSnappingVelocity :
      velocity.y < -self.config.locationBasedSnappingVelocity;
  BOOL closerToLeft = CGRectGetMidX(self.bounds) > self.floatingView.center.x;
  BOOL isLeftCorner = closerToLeft ? velocity.x < self.config.locationBasedSnappingVelocity :
        velocity.x < -self.config.locationBasedSnappingVelocity;

  if (isLeftCorner) {
    return isTopCorner ? $(WFFloatViewAnchorTopLeft) : $(WFFloatViewAnchorBottomLeft);
  } else {
    return isTopCorner ? $(WFFloatViewAnchorTopRight) : $(WFFloatViewAnchorBottomRight);
  }
}

- (void)animateTo:(WFFloatViewAnchor *)anchor {
  auto destination = [self coordinatesOfAnchor:anchor];
  auto velocity = [self vectorWithMagnitude:self.config.locationBasedSnappingVelocity
                       andDirectionOfVector:destination - self.floatingView.center];
  [self animateTo:anchor velocity:velocity];
}

- (CGPoint)vectorWithMagnitude:(CGFloat)magnitude andDirectionOfVector:(CGPoint)vector {
  if (!vector.x && !vector.y) {
    return CGPointZero;
  }
  auto normalizedVector = vector / std::hypot(vector.x, vector.y);
  return normalizedVector * magnitude;
}

- (void)animateTo:(WFFloatViewAnchor *)anchor velocity:(CGPoint)velocity {
  auto stiffness = anchor.isDock ? self.config.dockStiffness : self.config.nonDockStiffness;
  auto visualEffectAlpha = anchor.isDock ? 1 : 0;
  auto destination = [self coordinatesOfAnchor:anchor];
  self.animator = [self floatingViewAnimatorTo:destination velocity:velocity stiffness:stiffness];
  self.currentAnchor = anchor;
  if ([self.delegate respondsToSelector:@selector(floatView:willBeginAnimatingTo:)]) {
    [self.delegate floatView:self willBeginAnimatingTo:anchor];
  }
  @weakify(self);
  [self.animator addAnimations:^{
    @strongify(self);
    self.floatingView.center = destination;
    self.visualEffectView.alpha = visualEffectAlpha;
  }];
  [self.animator addCompletion:^(UIViewAnimatingPosition finalPosition) {
    @strongify(self);
    if (finalPosition == UIViewAnimatingPositionEnd) {
      self.dockingAllowed = !anchor.isDock;
      if ([self.delegate respondsToSelector:@selector(floatView:didSnapTo:)]) {
        [self.delegate floatView:self didSnapTo:anchor];
      }
    } else {
      self.dockingAllowed = YES;
    }
  }];
  self.animator.manualHitTestingEnabled = YES;
  [self.animator startAnimation];
}

- (UIViewPropertyAnimator *)floatingViewAnimatorTo:(CGPoint)destination velocity:(CGPoint)velocity
                                         stiffness:(CGFloat)stiffness {
  auto distance = destination - self.floatingView.center;
  auto xInitialVelocity = (distance.x ? velocity.x / distance.x : 0) +
      self.config.initialVelocityAddition;
  auto yInitialVelocity = (distance.y ? velocity.y / distance.y : 0) +
      self.config.initialVelocityAddition;
  auto initialVelocity = CGVectorMake(xInitialVelocity, yInitialVelocity);

  auto timingParameters = [[UISpringTimingParameters alloc] initWithMass:self.config.mass
                                                               stiffness:stiffness
                                                                 damping:self.config.damping
                                                         initialVelocity:initialVelocity];
  return [[UIViewPropertyAnimator alloc] initWithDuration:0 timingParameters:timingParameters];
}

- (CGFloat)visualEffectAlphaForPoint:(CGPoint)point {
  auto x = point.x;

  auto floatingViewWidth = CGRectGetWidth(self.floatingView.frame);
  auto leftBoundForVisualEffect = CGRectGetMinX(self.bounds) +
      floatingViewWidth * (0.5 - self.config.hiddenContentFractionForVisualEffectVisibility);
  auto rightBoundForVisualEffect = CGRectGetMaxX(self.bounds) -
      floatingViewWidth * (0.5 - self.config.hiddenContentFractionForVisualEffectVisibility);

  CGFloat maxAlphaX;
  CGFloat minAlphaX;

  if (x < leftBoundForVisualEffect) {
    minAlphaX = leftBoundForVisualEffect;
    maxAlphaX = [self leftDockX];
  } else if (x > rightBoundForVisualEffect) {
    minAlphaX = rightBoundForVisualEffect;
    maxAlphaX = [self rightDockX];
  } else {
    return 0;
  }

  if (maxAlphaX == minAlphaX) {
    return 1;
  }
  return std::min(fabs((x - minAlphaX) / (maxAlphaX - minAlphaX)), CGFloat(1));
}

- (CGPoint)coordinatesOfAnchor:(WFFloatViewAnchor *)anchor {
  switch (anchor.value) {
    case WFFloatViewAnchorTopCenter:
      return CGPointMake([self centerAnchorX], [self topAnchorY]);
    case WFFloatViewAnchorBottomCenter:
      return CGPointMake([self centerAnchorX], [self bottomAnchorY]);
    case WFFloatViewAnchorTopLeft:
      return CGPointMake([self leftX], [self topAnchorY]);
    case WFFloatViewAnchorTopLeftDock:
      return CGPointMake([self leftDockX], [self topAnchorY]);
    case WFFloatViewAnchorTopRight:
      return CGPointMake([self rightX], [self topAnchorY]);
    case WFFloatViewAnchorTopRightDock:
      return CGPointMake([self rightDockX], [self topAnchorY]);
    case WFFloatViewAnchorBottomLeft:
      return CGPointMake([self leftX], [self bottomAnchorY]);
    case WFFloatViewAnchorBottomLeftDock:
      return CGPointMake([self leftDockX], [self bottomAnchorY]);
    case WFFloatViewAnchorBottomRight:
      return CGPointMake([self rightX], [self bottomAnchorY]);
    case WFFloatViewAnchorBottomRightDock:
      return CGPointMake([self rightDockX], [self bottomAnchorY]);
  }
}

- (CGFloat)centerAnchorX {
  return CGRectGetMidX(self.bounds);
}

- (CGFloat)leftX {
  return CGRectGetMinX(self.bounds) + CGRectGetWidth(self.floatingView.frame) / 2. +
      self.snapInsets.left;
}

- (CGFloat)leftDockX {
  return CGRectGetMinX(self.bounds) - CGRectGetWidth(self.floatingView.frame) / 2. +
      [self leftDockVisibleWidth];
}

- (CGFloat)leftDockVisibleWidth {
  return self.rightAccessoryViewWidth > 0 ?
      self.rightAccessoryViewWidth : self.floatingView.frame.size.width;
}

- (CGFloat)rightX {
  return CGRectGetMaxX(self.bounds) - CGRectGetWidth(self.floatingView.frame) / 2. -
      self.snapInsets.right;
}

- (CGFloat)rightDockX {
  return CGRectGetMaxX(self.bounds) + CGRectGetWidth(self.floatingView.frame) / 2. -
      [self rightDockVisibleWidth];
}

- (CGFloat)rightDockVisibleWidth {
  return self.leftAccessoryViewWidth > 0 ?
      self.leftAccessoryViewWidth : self.floatingView.frame.size.width;
}

- (CGFloat)topAnchorY {
  return CGRectGetMinY(self.bounds) + CGRectGetHeight(self.floatingView.frame) / 2. +
      self.snapInsets.top;
}

- (CGFloat)bottomAnchorY {
  return CGRectGetMaxY(self.bounds) - CGRectGetHeight(self.floatingView.frame) / 2. -
      self.snapInsets.bottom;
}

@end

NS_ASSUME_NONNULL_END
