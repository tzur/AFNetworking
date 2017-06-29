// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTNavigationView.h"

#import <LTKit/LTAnimation.h>
#import <LTKit/NSObject+AddToContainer.h>

#import "LTContentInteraction.h"
#import "LTContentNavigationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTNavigationViewState
#pragma mark -

@interface LTNavigationViewState ()
@property (nonatomic) CGRect visibleContentRectInPoints;
@property (nonatomic) CGPoint scrollViewContentOffset;
@property (nonatomic) UIEdgeInsets scrollViewContentInset;
@property (nonatomic) UIEdgeInsets navigationViewContentInset;
@property (nonatomic) CGFloat zoomScale;
@property (nonatomic) BOOL animationActive;
@end

@implementation LTNavigationViewState

- (BOOL)isEqual:(LTNavigationViewState *)object {
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return self.visibleContentRectInPoints == object.visibleContentRectInPoints &&
         self.scrollViewContentOffset == object.scrollViewContentOffset &&
         self.scrollViewContentInset == object.scrollViewContentInset &&
         self.navigationViewContentInset == object.navigationViewContentInset &&
         self.zoomScale == object.zoomScale &&
         self.animationActive == object.animationActive;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, visibleContentRectInPoints: %@, "
          "scrollViewContentOffset: %@, scrollViewContentInset: %@, "
          "navigationViewContentInset: %@, zoomScale: %g, animationActive: %d>",
          [self class], self,
          NSStringFromCGRect(self.visibleContentRectInPoints),
          NSStringFromCGPoint(self.scrollViewContentOffset),
          NSStringFromUIEdgeInsets(self.scrollViewContentInset),
          NSStringFromUIEdgeInsets(self.navigationViewContentInset),
          self.zoomScale, self.animationActive];
}

@end

#pragma mark -
#pragma mark LTNavigationView
#pragma mark -

@interface LTNavigationView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

/// Underlying scroll view used to generate native-feel bouncing feedback when scrolling
/// out of bounds.
@property (strong, nonatomic) UIScrollView *scrollView;

/// Internal subview containing the content of this view.
@property (strong, nonatomic) UIImageView *contentView;

/// The underlying gesture recognizer for pinch gestures.
@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

/// The underlying gesture recognizer for pinch gestures. Will return \c nil when zooming is
/// disabled.
@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;

/// Underlying gesture recognizer for double tap gestures.
@property (strong, nonatomic) UITapGestureRecognizer *doubleTapGestureRecognizer;

/// Gesture recognizers provided by (but not added to) this view.
@property (strong, nonatomic) NSArray<UIGestureRecognizer *> *navigationGestureRecognizers;

/// Animation for updating the content rectangle according to the scrollView's state.
@property (strong, nonatomic) LTAnimation *animation;

/// State if underlying scrollview dragging.
@property (nonatomic) BOOL scrollViewDragging;

/// State if underlying scrollview zooming.
@property (nonatomic) BOOL scrollViewZooming;

/// State if underlying scrollview deceleration.
@property (nonatomic) BOOL scrollViewDecelerating;

// Number of different levels of zoom that the double tap switches between. Default is \c 3.
@property (readonly, nonatomic) NSUInteger doubleTapLevels;

/// Rectangular subregion of the content rectangle, in point units of the content coordinate
/// system, intersecting with the view enclosing the content rectangle.
@property (nonatomic) CGRect visibleContentRectInPoints;

/// The distance between the content and the enclosing view.
@property (nonatomic) UIEdgeInsets contentInset;

// Zoom factor of the double tap gesture between the different levels. Double tapping will zoom to a
// scale of this factor multiplied by the previous zoom scale (except when in the maximal level
/// which will zoom out to the minimal zoom scale). Default is \c 3.
@property (readonly, nonatomic) CGFloat doubleTapZoomFactor;

/// Number of floating-point pixel units of the screen coordinate system per pixel unit of the
/// content coordinate system, at the maximum zoom level.
@property (readwrite, nonatomic) CGFloat maxZoomScale;

@end

@implementation LTNavigationView

/// Name of the notification indicating an update during the scroll view animation.
static NSString * const kScrollAnimationNotification = @"LTNavigationViewAnimation";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame contentSize:(CGSize)contentSize
           contentScaleFactor:(CGFloat)contentScaleFactor
              navigationState:(nullable LTNavigationViewState *)initialNavigationState {
  LTParameterAssert(contentScaleFactor > 0, @"Given content scale factor (%g) must be positive",
                    contentScaleFactor);

  if (self = [super initWithFrame:frame]) {
    self.contentSize = contentSize;
    [super setContentScaleFactor:contentScaleFactor];
    self.hidden = YES;
    [self setDefaults];
    [self createScrollView];
    [self createContentView];
    [self createDoubleTapRecognizer];
    [self updateNavigationGestureRecognizers];
    [self registerAnimationNotification];
    if (initialNavigationState) {
      [self navigateToState:initialNavigationState];
    } else {
      [self navigateToDefaultState];
    }
  }
  return self;
}

/// Default minimum zoom scale factor.
static const CGFloat kDefaultMinZoomScaleFactor = 1;

/// Default maximal zoom scale.
static const CGFloat kDefaultMaxZoomScale = 16;

/// Default zoom factor for the double tap gesture.
static const CGFloat kDefaultDoubleTapZoomFactor = 3;

/// Default number of levels that the double tap gesture iterates between.
static const NSUInteger kDefaultDoubleTapLevels = 3;

- (void)setDefaults {
  self.minZoomScaleFactor = kDefaultMinZoomScaleFactor;
  self.maxZoomScale = kDefaultMaxZoomScale;
  _doubleTapLevels = kDefaultDoubleTapLevels;
  _doubleTapZoomFactor = kDefaultDoubleTapZoomFactor;
  self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)createScrollView {
  LTAssert(!self.scrollView, @"ScrollView must be set only once");
  self.scrollView = [[UIScrollView alloc]
                     initWithFrame:UIEdgeInsetsInsetRect(self.bounds, self.contentInset)];
  self.scrollView.contentScaleFactor = self.contentScaleFactor;
  self.scrollView.contentSize = self.contentSize / self.contentScaleFactor;
  self.scrollView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  // Make the scrollview bounce even if the image fits the screen.
  self.scrollView.alwaysBounceHorizontal = YES;
  self.scrollView.alwaysBounceVertical = YES;

  // Configure the zoom limits, and set oursevels as the scrollview delegate.
  [self configureScrollViewZoomLimits];
  self.scrollView.delegate = self;

  // Hide the scroll indicators and set the background color to be transparent.
  self.scrollView.backgroundColor = [UIColor clearColor];
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.showsVerticalScrollIndicator = NO;

  self.scrollView.gestureRecognizers = @[];

  // Add the scrollview to the current view.
  [self addSubview:self.scrollView];
}

- (void)createContentView {
  LTAssert(self.scrollView, @"Content view must be set after the scrollview is set.");
  CGRect contentBounds = CGRectFromSize(self.scrollView.contentSize);
  self.contentView = [[UIImageView alloc] initWithFrame:contentBounds];
  self.contentView.contentScaleFactor = self.contentScaleFactor;
  [self.scrollView addSubview:self.self.contentView];
}

- (void)registerAnimationNotification {
  [self unregisterAnimationNotification];
  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(updateVisibleContentRectDuringAnimation)
             name:kScrollAnimationNotification object:self];
}

- (void)unregisterAnimationNotification {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kScrollAnimationNotification
                                                object:self];
}

- (void)navigateToState:(LTNavigationViewState *)state {
  LTParameterAssert(state);
  LTParameterAssert([state isMemberOfClass:[LTNavigationViewState class]]);

  self.scrollView.zoomScale = state.zoomScale;
  self.contentInset = state.navigationViewContentInset;
  // Setting the contentOffset will round to the nearest integer.
  self.scrollView.bounds = CGRectFromOriginAndSize(state.scrollViewContentOffset,
                                                   self.scrollView.bounds.size);
  self.scrollView.contentInset = state.scrollViewContentInset;
  self.visibleContentRectInPoints = state.visibleContentRectInPoints;
  if (state.animationActive) {
    [self startAnimationIfNotRunning];
  }
}

- (void)navigateToDefaultState {
  self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
  [self centerContentViewInScrollView];
  self.visibleContentRectInPoints = [self visibleContentRectFromScrollView];
}

/// Creates the double tap gesture recognizer for easy zoom in/out.
- (void)createDoubleTapRecognizer {
  self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                     initWithTarget:self
                                     action:@selector(handleDoubleTapGesture:)];
  self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
  self.doubleTapGestureRecognizer.delaysTouchesBegan = NO;
  self.doubleTapGestureRecognizer.delaysTouchesEnded = NO;
  self.doubleTapGestureRecognizer.cancelsTouchesInView = YES;
  self.doubleTapGestureRecognizer.delegate = self;
}

- (void)updateNavigationGestureRecognizers {
  // Safely add the recognizers, as some of the gesture recognizers might not exist (for example,
  // the pinchGestureRecognizer might be nil if the image is too small as the minimalZoom and
  // maximalZoom will be equal, invalidating the zoom functionality).
  NSMutableArray *oldRecognizers = [NSMutableArray array];
  [self.panGestureRecognizer addToArray:oldRecognizers];
  [self.pinchGestureRecognizer addToArray:oldRecognizers];
  [self.doubleTapGestureRecognizer addToArray:oldRecognizers];

  // Update the recognizers that might have changed.
  self.panGestureRecognizer = self.scrollView.panGestureRecognizer;
  self.pinchGestureRecognizer = self.scrollView.pinchGestureRecognizer;

  // Remove any gesture recognizer from the scroll view since they should be attached to another
  // view, if required.
  self.scrollView.gestureRecognizers = @[];

  NSMutableArray *newRecognizers = [NSMutableArray array];
  [self.panGestureRecognizer addToArray:newRecognizers];
  [self.pinchGestureRecognizer addToArray:newRecognizers];
  [self.doubleTapGestureRecognizer addToArray:newRecognizers];

  if (![newRecognizers isEqual:oldRecognizers] ||
      ![self.gestureRecognizers isEqual:newRecognizers]) {
    self.navigationGestureRecognizers = [newRecognizers copy];
    [self.delegate navigationViewReplacedGestureRecognizers:self];
  }
}

- (void)dealloc {
  // Setting the delegate to nil is necessary to avoid crashing in case the view is deallocated
  // while the user is in a state that will cause a zoom bounce.
  self.scrollView.delegate = nil;

  [self unregisterAnimationNotification];
  [self.scrollView removeFromSuperview];
  [self.contentView removeFromSuperview];
}

#pragma mark -
#pragma mark UIView
#pragma mark -

- (CGFloat)contentScaleFactor {
  // Explicitely proxy the \c contentScaleFactor of \c contentScaleFactor in order to avoid Xcode
  // warnings of unsynthesized protocol property.
  return super.contentScaleFactor;
}

- (void)setContentScaleFactor:(__unused CGFloat)contentScaleFactor {
  // Disallow updates of the content scale factor.
}

#pragma mark -
#pragma mark ScrollView
#pragma mark -

/// Configures the scrollview's minimum and maximum zoom scale according to the bounds and content
/// size.
- (void)configureScrollViewZoomLimits {
  // Set minimal zoom scale by finding the dimension that can be minimally scaled.
  CGSize scrollViewSize = UIEdgeInsetsInsetRect(self.bounds, self.contentInset).size;
  CGSize scrollViewContentSize = self.contentSize / self.contentScaleFactor;
  CGFloat minimumZoomScale = std::min(scrollViewSize / scrollViewContentSize);

  // End case - if the minimal zoom scale is going to be larger than the maximal zoom scale, set the
  // maximal zoom scale to be the minimal one. This is relevant to small images and will prevent
  // any zooming of the image.
  CGFloat maximumZoomScale = MAX(self.maxZoomScale, minimumZoomScale);

  if (minimumZoomScale * self.minZoomScaleFactor < maximumZoomScale) {
    minimumZoomScale *= self.minZoomScaleFactor;
  }

  // Set the minimal zoom scale, and update the current scale to be in the new range.
  self.scrollView.minimumZoomScale = minimumZoomScale;
  self.scrollView.maximumZoomScale = maximumZoomScale;
  self.scrollView.zoomScale =
      MIN(MAX(self.scrollView.zoomScale, minimumZoomScale), maximumZoomScale);

  // Changing the zoom limits might cause the gesture recognizers to be updated in case zooming
  // becomes enabled or disabled.
  [self updateNavigationGestureRecognizers];
}

/// Borrowed from Apple's ScrollViewSuite:
/// http://developer.apple.com/library/ios/#samplecode/ScrollViewSuite/Introduction/Intro.html
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
  CGRect zoomRect;

  // The zoom rect is in the content view's coordinates. At a zoom scale of 1.0, it would be the
  // size of the bounds. As the zoom scale decreases, so more content is visible, the size of the
  // rect grows.
  zoomRect.size.height = self.scrollView.frame.size.height / scale;
  zoomRect.size.width = self.scrollView.frame.size.width / scale;

  // Choose an origin so as to get the right center.
  zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0);
  zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);

  return zoomRect;
}

/// For some reason, whenever the view is moved to a new window an internal method of UIScrollView
/// is called the and its gesture recognizers become enabled. Enforce that they'll stay in the state
/// corresponding with the current mode.
- (void)didMoveToWindow {
  [super didMoveToWindow];
  [self configureNavigationGesturesForCurrentMode];
}

- (void)scrollViewUserPanned:(UIPanGestureRecognizer *)panGesture {
  if (panGesture.state == UIGestureRecognizerStateEnded &&
      [self.navigationDelegate
       respondsToSelector:@selector(navigationManagerDidHandlePanGesture:)]) {
    [self.navigationDelegate navigationManagerDidHandlePanGesture:self];
  }
}

- (void)scrollViewUserPinched:(UIPinchGestureRecognizer *)pinchGesture {
  if (pinchGesture.state == UIGestureRecognizerStateEnded &&
      [self.navigationDelegate
       respondsToSelector:@selector(navigationManagerDidHandlePinchGesture:)]) {
    [self.navigationDelegate navigationManagerDidHandlePinchGesture:self];
  }
}

#pragma mark -
#pragma mark Animations
#pragma mark -

- (void)updateVisibleContentRectDuringAnimation {
  self.visibleContentRectInPoints = [self visibleContentRectFromLayers];
}

- (void)startAnimationIfNotRunning {
  // If an animation is already running, no need to do anything.
  if (self.animation.isAnimating) {
    return;
  }

  __block NSUInteger animationFrames = 0;
  __block BOOL addedZoomBounceCenteringAnimation = NO;

  // Otherwise, create an animation for updating the content rectangle according to the state of the
  /// \c scrollView.
  @weakify(self);
  self.animation = [LTAnimation animationWithBlock:^BOOL(CFTimeInterval, CFTimeInterval) {
    // If this instance was deallocated, the animation should not continue.
    @strongify(self)
    if (!self) {
      return NO;
    }

    ++animationFrames;

    // Update the current visible content rectangle, animating the centering of the conetnt in case
    // we're during a zoom bounce animation.
    if (self.scrollView.isZoomBouncing && !addedZoomBounceCenteringAnimation) {
      addedZoomBounceCenteringAnimation = YES;

      // Returns 0 in case the layer does not exist or if it has no animation, and in this case the
      // call below equals to a call to centerContentViewInScrollView.
      NSTimeInterval remainingDuration =
          [self remainingDurationForAnimationsOfLayer:self.contentView.layer];
      [self centerContentViewInScrollViewWithAnimationDuration:remainingDuration];
    } else {
      [self centerContentViewInScrollView];
    }
    CGRect newVisibleContentRect = [self visibleContentRectFromLayers];
    BOOL updated = !CGRectEqualToRect(newVisibleContentRect, self.visibleContentRectInPoints);

    // Instead of updating the content rect here (which will lead to a setNeedsDisplay and in some
    // scenarios hogs the display link, causing the scrollview to get stuck), post a notification on
    // the update. This will cause the setNeedsDisplay to happen elsewhere, and won't block the
    // display link loop. While this is somewhat a hack that can't guarantee the scroll view won't
    // get stuck, it appears that this greatly reduces the chances of this happenning.
    if (updated) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kScrollAnimationNotification
                                                          object:self];
    }

    // If the scroll view is still dragging / zooming / decelerating / animating, the animation
    // should continue.
    if (self.scrollViewDragging || self.scrollViewZooming || self.scrollViewDecelerating) {
      return YES;
    }

    // Safety precautions, to make sure we don't stop while the scrollview is in motion.
    if (self.scrollView.dragging || self.scrollView.zooming || self.scrollView.decelerating) {
      return YES;
    }

    // Final precaution, in case the visible content rect was changed or if it the first frame of
    // the animation, give us at least one more loop call before stopping the animation.
    if (updated || animationFrames <= 1) {
      return YES;
    }

    // The animation can stop now.
    return NO;
  }];
}

- (NSTimeInterval)remainingDurationForAnimationsOfLayer:(nullable CALayer *)layer {
  NSTimeInterval remainingDuration = 0;
  for (NSString *key in layer.animationKeys) {
    CAAnimation *animation = [layer animationForKey:key];
    remainingDuration = std::max(remainingDuration, [self remainingDurationForAnimation:animation]);
  }

  return remainingDuration;
}

- (NSTimeInterval)remainingDurationForAnimation:(nullable CAAnimation *)animation {
  return std::max(0.0, animation.duration - (CACurrentMediaTime() - animation.beginTime));
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate
#pragma mark -

- (BOOL)gestureRecognizer:(UIGestureRecognizer __unused *)gestureRecognizer
       shouldReceiveTouch:(UITouch __unused *)touch {
  return gestureRecognizer == self.doubleTapGestureRecognizer;
}

#pragma mark -
#pragma mark UIScrollViewDelegate
#pragma mark -

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView __unused *)scrollView {
  return self.contentView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView __unused *)scrollView
                          withView:(nullable UIView __unused *)view {
  self.scrollViewZooming = YES;
  [self startAnimationIfNotRunning];
}

- (void)scrollViewDidEndZooming:(UIScrollView __unused *)scrollView
                       withView:(nullable UIView __unused *)view atScale:(CGFloat __unused)scale {
  self.scrollViewZooming = NO;
  [self bounceToAspectFitIfNecessary];
}

- (void)scrollViewWillBeginDragging:(UIScrollView __unused *)scrollView {
  self.scrollViewDragging = YES;
  [self startAnimationIfNotRunning];
}

- (void)scrollViewDidEndDragging:(UIScrollView __unused *)scrollView
                  willDecelerate:(BOOL __unused)decelerate {
  self.scrollViewDragging = NO;
  [self bounceToAspectFitIfNecessary];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView __unused *)scrollView {
  self.scrollViewDecelerating = YES;
  [self startAnimationIfNotRunning];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView __unused *)scrollView {
  self.scrollViewDecelerating = NO;
  [self bounceToAspectFitIfNecessary];
}

#pragma mark -
#pragma mark Double Tap
#pragma mark -

/// Handle double tap gesture: cycle between different zoom levels controlled by the doubleTapLevels
/// and doubleTapZoomFactor properties.
- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)gestureRecognizer {
  // Zoom to a rect centered at the tap location, with the zoom scale according to the level.
  NSUInteger level = [self nextDoubleTapLevel];
  CGPoint tap = [gestureRecognizer locationInView:self.contentView];
  CGRect rectInPointUnits = [self zoomRectForScale:[self zoomScaleForLevel:level] withCenter:tap];
  CGRect rectInPixelUnits = [self rectInPixelUnitsFromRectInPointUnits:rectInPointUnits];

  [self zoomToRect:rectInPixelUnits animated:YES];
  if ([self.navigationDelegate
       respondsToSelector:@selector(navigationManagerDidHandleDoubleTapGesture:)]) {
    [self.navigationDelegate navigationManagerDidHandleDoubleTapGesture:self];
  }
}

/// Returns the next double tap zoom level if the current zoom scale is already one of the levels,
/// or 0 otherwise.
- (NSUInteger)nextDoubleTapLevel {
  const CGFloat kInsignificantZoomDiff = 1e-4;
  for (NSUInteger i = 0; i < self.doubleTapLevels; i++) {
    if (std::abs(self.scrollView.zoomScale - [self zoomScaleForLevel:i]) < kInsignificantZoomDiff) {
      return (i + 1) % self.doubleTapLevels;
    }
  }
  return 0;
}

// Return the zoom scale for the given double tap level. The zoom scale in each level is the scale
// at the previous level multiplied by the doubleTapZoomFactor property. This feels more natural as
// every level the size of pixels you see is multiplied by the factor, as opposed to using the
// formula (minimumZoomScale * doubleTapZoomFactor * level) where the difference in the first tap
// seems much greater than the difference in the second one.
- (CGFloat)zoomScaleForLevel:(NSUInteger)level {
  return self.scrollView.minimumZoomScale * pow(self.doubleTapZoomFactor, level);
}

#pragma mark -
#pragma mark Conversion
#pragma mark -

- (CGRect)rectInPixelUnitsFromRectInPointUnits:(CGRect)rectInPointUnits {
  return CGRectFromOriginAndSize(rectInPointUnits.origin * self.contentScaleFactor,
                                 rectInPointUnits.size * self.contentScaleFactor);
}

- (CGRect)rectInPointUnitsFromRectInPixelUnits:(CGRect)rectInPixelUnits {
  return CGRectFromOriginAndSize(rectInPixelUnits.origin / self.contentScaleFactor,
                                 rectInPixelUnits.size / self.contentScaleFactor);
}

#pragma mark -
#pragma mark Navigation
#pragma mark -

/// Bounces such that the content rectangle is aspect fit, if necessary.
- (void)bounceToAspectFitIfNecessary {
  if (self.bounceToAspectFit && !self.scrollViewZooming && !self.scrollViewDragging &&
      self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
    [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
  }
}

- (void)configureNavigationGesturesForCurrentMode {
  LTInteractionMode interactionMode = self.interactionModeProvider.interactionMode;

  self.doubleTapGestureRecognizer.enabled = (interactionMode & LTInteractionModeTap);
  self.scrollView.delaysContentTouches = (interactionMode != LTInteractionModeNone);
  self.scrollView.canCancelContentTouches = (interactionMode != LTInteractionModeNone);
  self.scrollView.panGestureRecognizer.enabled =
      (interactionMode & LTInteractionModePanOneTouch) |
      (interactionMode & LTInteractionModePanTwoTouches);
  self.scrollView.pinchGestureRecognizer.enabled = (interactionMode & LTInteractionModePinch);
}

- (void)interactionModeUpdated {
  [self configureNavigationGesturesForCurrentMode];
}

/// There is no way to control the animation length of \c UIScrollView's \c zoomToRect: method, so
/// the only solution was to test the actual duration of its animation and use this value.
static const NSTimeInterval kZoomToRectAnimationDuration = 0.4;

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated {
  if (animated) {
    [UIView animateWithDuration:kZoomToRectAnimationDuration animations:^{
      self.scrollView.contentInset = UIEdgeInsetsZero;
    }];
  } else {
    self.scrollView.contentInset = UIEdgeInsetsZero;
  }

  [self.scrollView zoomToRect:[self rectInPointUnitsFromRectInPixelUnits:rect] animated:animated];

  if (animated) {
    [self centerContentViewInScrollViewWithAnimationDuration:kZoomToRectAnimationDuration];
  } else {
    [self centerContentViewInScrollView];
    self.visibleContentRectInPoints = [self visibleContentRectFromScrollView];
  }

  [self startAnimationIfNotRunning];
}

#pragma mark -
#pragma mark ContentView
#pragma mark -

- (void)centerContentViewInScrollView {
  [self centerContentViewInScrollViewWithAnimationDuration:0];
}

- (void)centerContentViewInScrollViewWithAnimationDuration:(NSTimeInterval)duration {
  UIOffset inset = UIOffsetZero;

  // Center horizontally.
  if (self.contentView.frame.size.width < self.scrollView.bounds.size.width) {
    inset.horizontal = (self.scrollView.bounds.size.width - self.contentView.frame.size.width) / 2;
  }

  // Center vertically.
  if (self.contentView.frame.size.height < self.scrollView.bounds.size.height) {
    inset.vertical = (self.scrollView.bounds.size.height - self.contentView.frame.size.height) / 2;
  }

  UIEdgeInsets insets = UIEdgeInsetsMake(inset.vertical, inset.horizontal,
                                         inset.vertical, inset.horizontal);
  if (duration > 0) {
    [UIView animateWithDuration:duration animations:^{
      self.scrollView.contentInset = insets;
    }];
  } else {
    self.scrollView.contentInset = insets;
  }
}

#pragma mark -
#pragma mark Visible Content Rect
#pragma mark -

- (CGRect)visibleContentRectFromScrollView {
  return [self convertRect:self.bounds toView:self.contentView];
}

- (CGRect)visibleContentRectFromLayers {
  CALayer *contentLayer = [self.contentView.layer presentationLayer];
  CALayer *scrollLayer = [self.layer presentationLayer];

  // Make sure the layers exist, otherwise, fall back to using the scroll view. (This might happen
  // during initialization).
  if (contentLayer && scrollLayer) {
    return [scrollLayer convertRect:scrollLayer.bounds toLayer:contentLayer];
  } else {
    return [self visibleContentRectFromScrollView];
  }
}

- (void)setVisibleContentRectInPoints:(CGRect)visibleContentRectInPoints {
  _visibleContentRectInPoints = visibleContentRectInPoints;
  if ([self.navigationDelegate
       respondsToSelector:@selector(navigationManager:didNavigateToVisibleRect:)]) {
    [self.navigationDelegate navigationManager:self
                      didNavigateToVisibleRect:self.visibleContentRect];
  }
}

- (CGRect)visibleContentRect {
  return [self rectInPixelUnitsFromRectInPointUnits:self.visibleContentRectInPoints];
}

#pragma mark -
#pragma mark Padding
#pragma mark -

- (void)setContentInset:(UIEdgeInsets)contentInset {
  if (contentInset == _contentInset) {
    return;
  }

  // In case we were at the minimal zoom level, we'll have to update the zoom to reflect the
  // updated padding.
  BOOL shouldUpdateZoom = (self.scrollView.zoomScale == self.scrollView.minimumZoomScale);

  // Update the padding, the scrollview's frame, and recalculate the zoom limits.
  _contentInset = contentInset;
  self.scrollView.frame = UIEdgeInsetsInsetRect(self.bounds, _contentInset);
  [self configureScrollViewZoomLimits];

  // Update the zoom scale if necessary.
  if (shouldUpdateZoom) {
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
  }

  // Re-center the content view, and update the visible content rect.
  [self centerContentViewInScrollView];
  self.visibleContentRectInPoints = [self visibleContentRectFromScrollView];
}

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];

  BOOL atMinimalScale = (self.scrollView.zoomScale == self.scrollView.minimumZoomScale);
  [self configureScrollViewZoomLimits];
  if (atMinimalScale) {
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
  }

  [self centerContentViewInScrollView];
  self.visibleContentRectInPoints = [self visibleContentRectFromScrollView];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

@synthesize bounceToAspectFit = _bounceToAspectFit;

- (void)setBounceToAspectFit:(BOOL)bounceToAspectFit {
  _bounceToAspectFit = bounceToAspectFit;
  [self bounceToAspectFitIfNecessary];
}

@synthesize interactionModeProvider = _interactionModeProvider;
@synthesize navigationDelegate = _navigationDelegate;

- (LTNavigationViewState *)navigationState {
  LTNavigationViewState *state = [[LTNavigationViewState alloc] init];
  state.visibleContentRectInPoints = self.visibleContentRectInPoints;
  state.zoomScale = self.scrollView.zoomScale;
  state.scrollViewContentOffset = self.scrollView.contentOffset;
  state.scrollViewContentInset = self.scrollView.contentInset;
  state.navigationViewContentInset = self.contentInset;
  state.animationActive = (self.animation) ? (self.animation.isAnimating) : NO;
  return state;
}

@synthesize contentSize = _contentSize;

- (void)setContentSize:(CGSize)contentSize {
  if (_contentSize == contentSize) {
    return;
  }

  _contentSize = contentSize;
  CGFloat previousMinimumZoomscale = self.scrollView.minimumZoomScale;
  self.scrollView.minimumZoomScale = 1;
  self.scrollView.zoomScale = 1;
  self.scrollView.contentSize = contentSize / self.contentScaleFactor;
  self.contentView.frame = CGRectFromSize(self.scrollView.contentSize);
  self.scrollView.minimumZoomScale = previousMinimumZoomscale;
  [self configureScrollViewZoomLimits];
  [self navigateToDefaultState];
}

@synthesize minZoomScaleFactor = _minZoomScaleFactor;

- (void)setMinZoomScaleFactor:(CGFloat)minZoomScaleFactor {
  if (self.minZoomScaleFactor == minZoomScaleFactor) {
    return;
  }
  LTParameterAssert(minZoomScaleFactor > 0, @"Factor %g must be positive", minZoomScaleFactor);

  _minZoomScaleFactor = minZoomScaleFactor;

  CGFloat previousZoomScale = self.scrollView.zoomScale;
  [self configureScrollViewZoomLimits];
  if (self.scrollView.zoomScale != previousZoomScale) {
    [self centerContentViewInScrollView];
  }
  self.visibleContentRectInPoints = [self visibleContentRectFromScrollView];
}

- (CGFloat)minZoomScale {
  return self.scrollView.minimumZoomScale;
}

- (CGFloat)zoomScale {
  return std::min(self.bounds.size / self.visibleContentRectInPoints.size);
}

- (void)setMaxZoomScale:(CGFloat)maxZoomScale {
  _maxZoomScale = MAX(0, maxZoomScale);
  CGFloat oldScale = self.scrollView.zoomScale;
  [self configureScrollViewZoomLimits];
  if (self.scrollView.zoomScale != oldScale) {
    [self centerContentViewInScrollView];
  }
  self.visibleContentRectInPoints = [self visibleContentRectFromScrollView];
}

- (void)setPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
  if (panGestureRecognizer == _panGestureRecognizer) {
    return;
  }

  [_panGestureRecognizer removeTarget:self action:@selector(scrollViewUserPanned:)];
  _panGestureRecognizer = panGestureRecognizer;
  [_panGestureRecognizer addTarget:self action:@selector(scrollViewUserPanned:)];
}

- (void)setPinchGestureRecognizer:(UIPinchGestureRecognizer *)pinchGestureRecognizer {
  if (pinchGestureRecognizer == _pinchGestureRecognizer) {
    return;
  }

  [_pinchGestureRecognizer removeTarget:self action:@selector(scrollViewUserPinched:)];
  _pinchGestureRecognizer = pinchGestureRecognizer;
  [pinchGestureRecognizer addTarget:self action:@selector(scrollViewUserPinched:)];
}

@end

NS_ASSUME_NONNULL_END
