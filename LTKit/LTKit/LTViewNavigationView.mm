// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewNavigationView.h"

#import "LTAnimation.h"
#import "LTCGExtensions.h"
#import "LTDevice.h"
#import "NSObject+AddToContainer.h"

#pragma mark -
#pragma mark LTViewNavigationViewState
#pragma mark -

@interface LTViewNavigationState ()
@property (nonatomic) CGRect visibleContentRect;
@property (nonatomic) CGPoint scrollViewContentOffset;
@property (nonatomic) UIEdgeInsets scrollViewContentInset;
@property (nonatomic) UIEdgeInsets navigationViewContentInset;
@property (nonatomic) CGFloat zoomScale;
@property (nonatomic) BOOL animationActive;
@end

@implementation LTViewNavigationState

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  
  return self.visibleContentRect == [object visibleContentRect] &&
         self.scrollViewContentOffset == [object scrollViewContentOffset] &&
         self.scrollViewContentInset == [object scrollViewContentInset] &&
         self.navigationViewContentInset == [object navigationViewContentInset] &&
         self.zoomScale == [object zoomScale] &&
         self.animationActive == [object animationActive];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, visibleContentRect: %@, "
          "scrollViewContentOffset: %@, scrollViewContentInset: %@, "
          "navigationViewContentInset: %@, zoomScale: %g, animationActive: %d>",
          [self class], self,
          NSStringFromCGRect(self.visibleContentRect),
          NSStringFromCGPoint(self.scrollViewContentOffset),
          NSStringFromUIEdgeInsets(self.scrollViewContentInset),
          NSStringFromUIEdgeInsets(self.navigationViewContentInset),
          self.zoomScale, self.animationActive];
}

@end

#pragma mark -
#pragma mark LTViewNavigationView
#pragma mark -

@interface LTViewNavigationView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *contentView;
@property (strong, nonatomic) UITapGestureRecognizer *doubleTapRecognizer;

@property (strong, nonatomic) LTAnimation *animation;

@property (nonatomic) BOOL scrollViewDragging;
@property (nonatomic) BOOL scrollViewZooming;
@property (nonatomic) BOOL scrollViewDecelerating;

@property (nonatomic) BOOL duringRotation;
@property (nonatomic) CGPoint centerDuringRotation;
@property (nonatomic) CGFloat zoomScaleDuringRotation;

@end

@implementation LTViewNavigationView

/// Name of the notification indicating an update during the scroll view animation.
static NSString * const kScrollAnimationNotification = @"LTViewNavigationViewAnimation";

@synthesize visibleContentRect = _visibleContentRect;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)initWithFrame:(CGRect)frame contentSize:(CGSize)contentSize {
  return [self initWithFrame:frame contentSize:contentSize state:nil];
}

- (id)initWithFrame:(CGRect)frame contentSize:(CGSize)contentSize
              state:(LTViewNavigationState *)state{
  if (self = [super initWithFrame:frame]) {
    self.contentSize = contentSize;
    [self setDefaults];
    [self createScrollView];
    [self createContentView];
    [self createDoubleTapRecognizer];
    [self registerAnimationNotification];
    if (state) {
      [self navigateToState:state];
    } else {
      [self navigateToDefaultState];
    }
  }
  return self;
}

- (void)setDefaults {
  self.mode = LTViewNavigationFull;
  self.maxZoomScale = CGFLOAT_MAX;
  self.contentScaleFactor = [LTDevice currentDevice].glkContentScaleFactor;
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
  
  // Add the scrollview to the current view.
  [self addSubview:self.scrollView];
}

- (void)createContentView {
  LTAssert(self.scrollView, @"Content view must be set after the scrollview is set.");
  CGRect contentBounds = CGRectFromOriginAndSize(CGPointZero, self.scrollView.contentSize);
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

- (void)navigateToState:(LTViewNavigationState *)state {
  LTParameterAssert(state);
  UIEdgeInsets contentInset = state.scrollViewContentInset;
  LTParameterAssert(rint(contentInset.top) == contentInset.top &&
                    rint(contentInset.left) == contentInset.left &&
                    rint(contentInset.bottom) == contentInset.bottom &&
                    rint(contentInset.right) == contentInset.right,
                    @"non-integral content insets are not yet supported");

  self.scrollView.zoomScale = state.zoomScale;
  self.contentInset = state.navigationViewContentInset;
  // Setting the contentOffset will round to the nearest integer.
  self.scrollView.bounds = CGRectFromOriginAndSize(state.scrollViewContentOffset,
                                                   self.scrollView.bounds.size);
  self.scrollView.contentInset = state.scrollViewContentInset;
  self.visibleContentRect = state.visibleContentRect;
  if (state.animationActive) {
    [self startAnimationIfNotRunning];
  }
}

- (void)navigateToDefaultState {
  self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
  [self centerContentViewInScrollView];
  self.visibleContentRect = [self visibleContentRectFromScrollView];
}

/// Creates the double tap gesture recognizer for easy zoom in/out.
- (void)createDoubleTapRecognizer {
  self.doubleTapRecognizer = [[UITapGestureRecognizer alloc]
                              initWithTarget:self
                              action:@selector(handleDoubleTapGesture:)];
  self.doubleTapRecognizer.numberOfTapsRequired = 2;
  self.doubleTapRecognizer.delaysTouchesBegan = NO;
  self.doubleTapRecognizer.delaysTouchesEnded = NO;
  self.doubleTapRecognizer.cancelsTouchesInView = YES;
  self.doubleTapRecognizer.delegate = self;
}

- (void)dealloc {
  [self unregisterAnimationNotification];
  [self.scrollView removeFromSuperview];
  [self.contentView removeFromSuperview];
}

#pragma mark -
#pragma mark ScrollView
#pragma mark -

/// Congifures the scrollview's minimal and maximal zoom scale according to the bounds and content
/// size.
- (void)configureScrollViewZoomLimits {
  // Set minimal zoom scale by finding the dimension that can be minimally scaled.
  CGSize scrollViewSize = UIEdgeInsetsInsetRect(self.bounds, self.contentInset).size;
  CGSize scrollViewContentSize = self.contentSize / self.contentScaleFactor;
  CGFloat minimumZoomScale = std::min(scrollViewSize / scrollViewContentSize);

  // Apply the minimal zoom scale factor, if valid.
  if (self.minZoomScaleFactor > 0) {
    minimumZoomScale *= self.minZoomScaleFactor;
  }
  
  // End case - if the minimal zoom scale is going to be larger than the maximal zoom scale, set the
  // maximal zoom scale to be the minimal one. This is relevant to small images and will prevent
  // any zooming of the image.
  CGFloat maximumZoomScale = MAX(self.maxZoomScale, minimumZoomScale);
  
  // Set the minimal zoom scale, and update the current scale to be in the new range.
  self.scrollView.minimumZoomScale = minimumZoomScale;
  self.scrollView.maximumZoomScale = maximumZoomScale;
  self.scrollView.zoomScale =
      MIN(MAX(self.scrollView.zoomScale, minimumZoomScale), maximumZoomScale);
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

#pragma mark -
#pragma mark Animations
#pragma mark -

- (void)updateVisibleContentRectDuringAnimation {
  self.visibleContentRect = [self visibleContentRectFromLayers];
}

- (void)startAnimationIfNotRunning {
  // If an animation is already running, no need to do anything.
  if (self.animation.isAnimating) {
    return;
  }
  
  // Otherwise, create an animation for updating the LTView according to the scrollView's state.
  @weakify(self);
  self.animation = [LTAnimation animationWithBlock:^BOOL(CFTimeInterval, CFTimeInterval) {
    // If the LTView was deallocated, the animation shouldn't continue.
    @strongify(self)
    if (!self) {
      return NO;
    }
    
    // Update the current visible content rectangle.
    [self centerContentViewInScrollView];
    CGRect newVisibleContentRect = [self visibleContentRectFromLayers];
    BOOL updated = !CGRectEqualToRect(newVisibleContentRect, self.visibleContentRect);
    
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
    
    // Final precaution, in case the visible content rect was changed, give us at least one more
    // loop call before stopping the animation.
    if (updated) {
      return YES;
    }
    
    // The animation can stop now.
    return NO;
  }];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate
#pragma mark -

- (BOOL)gestureRecognizer:(UIGestureRecognizer __unused *)gestureRecognizer
       shouldReceiveTouch:(UITouch __unused *)touch {
  return gestureRecognizer == self.doubleTapRecognizer;
}

#pragma mark -
#pragma mark UIScrollViewDelegate
#pragma mark -

- (UIView *)viewForZoomingInScrollView:(UIScrollView __unused *)scrollView {
  return self.contentView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView __unused *)scrollView
                          withView:(UIView __unused *)view {
  self.scrollViewZooming = YES;
  [self startAnimationIfNotRunning];
}

- (void)scrollViewDidEndZooming:(UIScrollView __unused *)scrollView withView:(UIView __unused *)view
                        atScale:(CGFloat __unused)scale {
  self.scrollViewZooming = NO;
  [self bounceToMinimalZoomIfNecessary];
}

- (void)scrollViewWillBeginDragging:(UIScrollView __unused *)scrollView {
  self.scrollViewDragging = YES;
  [self startAnimationIfNotRunning];
}

- (void)scrollViewDidEndDragging:(UIScrollView __unused *)scrollView
                  willDecelerate:(BOOL __unused)decelerate {
  self.scrollViewDragging = NO;
  [self bounceToMinimalZoomIfNecessary];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView __unused *)scrollView {
  self.scrollViewDecelerating = YES;
  [self startAnimationIfNotRunning];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView __unused *)scrollView {
  self.scrollViewDecelerating = NO;
  [self bounceToMinimalZoomIfNecessary];
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
  CGRect rect = [self zoomRectForScale:[self zoomScaleForLevel:level] withCenter:tap];
  [self.scrollView zoomToRect:rect animated:YES];
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
#pragma mark Navigation
#pragma mark -

/// Bounces to the minimal zoom scale if the LTViewNavigationBounceToMinimalScale mode, and the
/// scrollView is not in the minimal zoom scale.
- (void)bounceToMinimalZoomIfNecessary {
  if (self.mode == LTViewNavigationBounceToMinimalScale &&
      !self.scrollViewZooming && !self.scrollViewDragging &&
      self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
    [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
  }
}

- (void)configureNavigationGesturesForCurrentMode {
  switch (self.mode) {
    case LTViewNavigationFull:
    case LTViewNavigationZoomAndScroll:
    case LTViewNavigationBounceToMinimalScale:
      self.scrollView.panGestureRecognizer.minimumNumberOfTouches = 1;
      self.scrollView.panGestureRecognizer.maximumNumberOfTouches = 2;
      break;
    case LTViewNavigationTwoFingers:
      self.scrollView.panGestureRecognizer.minimumNumberOfTouches = 2;
      self.scrollView.panGestureRecognizer.maximumNumberOfTouches = 2;
      break;
    default:
      break;
  }
  
  self.doubleTapRecognizer.enabled = (self.mode == LTViewNavigationFull);
  self.scrollView.delaysContentTouches = (self.mode != LTViewNavigationNone);
  self.scrollView.canCancelContentTouches = (self.mode != LTViewNavigationNone);
  self.scrollView.panGestureRecognizer.enabled = (self.mode != LTViewNavigationNone);
  self.scrollView.pinchGestureRecognizer.enabled = (self.mode != LTViewNavigationNone);
}

- (void)setMode:(LTViewNavigationMode)mode {
  _mode = mode;
  [self configureNavigationGesturesForCurrentMode];
  [self bounceToMinimalZoomIfNecessary];
}

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated {
  rect.origin = rect.origin / self.contentScaleFactor;
  rect.size = rect.size / self.contentScaleFactor;
  [self.scrollView zoomToRect:rect animated:animated];
  if (!animated) {
    [self centerContentViewInScrollView];
    self.visibleContentRect = [self visibleContentRectFromScrollView];
  }
}

#pragma mark -
#pragma mark Rotation
#pragma mark -

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation __unused)orientation {
  // Save the current center of the visible rect (since we want to rotate around it), and the
  // current zoom scale (since we want to try and preserve it, if possible).
  self.centerDuringRotation = CGRectCenter(self.visibleContentRect);
  self.zoomScaleDuringRotation = self.zoomScale;
  self.duringRotation = YES;
  
  // Disable the navigation gestures, to cancel any active scrolling/zooming when the rotation
  // begins.
  self.scrollView.pinchGestureRecognizer.enabled = NO;
  self.scrollView.panGestureRecognizer.enabled = NO;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation __unused)orientation {
  self.centerDuringRotation = CGPointZero;
  self.duringRotation = NO;
  self.visibleContentRect = [self visibleContentRectFromScrollView];
  [self configureNavigationGesturesForCurrentMode];
}

#pragma mark -
#pragma mark ContentView
#pragma mark -

- (void)centerContentViewInScrollView {
  UIOffset inset = UIOffsetZero;
  
  // Center horizontally.
  if (self.contentView.frame.size.width < self.scrollView.bounds.size.width) {
    inset.horizontal = (self.scrollView.bounds.size.width - self.contentView.frame.size.width) / 2;
  }
  
  // Center vertically.
  if (self.contentView.frame.size.height < self.scrollView.bounds.size.height) {
    inset.vertical = (self.scrollView.bounds.size.height - self.contentView.frame.size.height) / 2;
  }
  
  self.scrollView.contentInset = UIEdgeInsetsMake(inset.vertical, inset.horizontal,
                                                  inset.vertical, inset.horizontal);
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

- (void)setVisibleContentRect:(CGRect)visibleContentRect {
  _visibleContentRect = visibleContentRect;
  [self.delegate didNavigateToRect:visibleContentRect];
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
  self.visibleContentRect = [self visibleContentRectFromScrollView];
}

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  
  BOOL atMinimalScale = (self.scrollView.zoomScale == self.scrollView.minimumZoomScale);
  [self configureScrollViewZoomLimits];
  if (atMinimalScale) {
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
  }
  
  [self centerContentViewInScrollView];
  if (self.duringRotation) {
    [self updatedFrameDuringRotation];
  } else {
    self.visibleContentRect = [self visibleContentRectFromScrollView];
  }
}

- (void)updatedFrameDuringRotation {
  CGSize targetSize = self.scrollView.bounds.size / self.zoomScaleDuringRotation;
  CGRect targetRect = CGRectCenteredAt(self.centerDuringRotation, targetSize);
  [self.scrollView zoomToRect:targetRect animated:NO];
  [self centerContentViewInScrollView];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSArray *)navigationGestureRecognizers {
  // Safely add the recognizers, as some of the gesture recognizers might not exist (for example,
  // the pinchGestureRecognizer might be nil if the image is too small as the minimalZoom and
  // maximalZoom will be equal, invalidating the zoom functionality).
  NSMutableArray *recognizers = [NSMutableArray array];
  [self.scrollView.panGestureRecognizer addToArray:recognizers];
  [self.scrollView.pinchGestureRecognizer addToArray:recognizers];
  [self.doubleTapRecognizer addToArray:recognizers];
  return recognizers;
}

- (LTViewNavigationState *)state {
  LTViewNavigationState *state = [[LTViewNavigationState alloc] init];
  state.visibleContentRect = self.visibleContentRect;
  state.zoomScale = self.scrollView.zoomScale;
  state.scrollViewContentOffset = self.scrollView.contentOffset;
  state.scrollViewContentInset = self.scrollView.contentInset;
  state.navigationViewContentInset = self.contentInset;
  state.animationActive = (self.animation) ? (self.animation.isAnimating) : NO;
  return state;
}

- (UIView *)viewForContentCoordinates {
  return self.contentView;
}

- (void)setContentSize:(CGSize)contentSize {
  if (_contentSize == contentSize) {
    return;
  }
  
  _contentSize = contentSize;
  CGFloat previousMinimumZoomscale = self.scrollView.minimumZoomScale;
  self.scrollView.minimumZoomScale = 1;
  self.scrollView.zoomScale = 1;
  self.scrollView.contentSize = contentSize / self.contentScaleFactor;
  self.contentView.frame = CGRectFromOriginAndSize(CGPointZero, self.scrollView.contentSize);
  self.scrollView.minimumZoomScale = previousMinimumZoomscale;
  [self configureScrollViewZoomLimits];
  [self navigateToDefaultState];
}

- (CGFloat)zoomScale {
  return std::min(self.bounds.size / self.visibleContentRect.size);
}

- (void)setMinZoomScaleFactor:(CGFloat)minZoomScaleFactor {
  _minZoomScaleFactor = MAX(0, minZoomScaleFactor);
  BOOL atMinimalScale = (self.scrollView.zoomScale == self.scrollView.minimumZoomScale);
  [self configureScrollViewZoomLimits];
  if (atMinimalScale) {
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    [self centerContentViewInScrollView];
  }
  self.visibleContentRect = [self visibleContentRectFromScrollView];
}

- (void)setMaxZoomScale:(CGFloat)maxZoomScale {
  _maxZoomScale = MAX(0, maxZoomScale);
  CGFloat oldScale = self.scrollView.zoomScale;
  [self configureScrollViewZoomLimits];
  if (self.scrollView.zoomScale != oldScale) {
    [self centerContentViewInScrollView];
  }
  self.visibleContentRect = [self visibleContentRectFromScrollView];
}

- (void)setDoubleTapZoomFactor:(CGFloat)doubleTapZoomFactor {
  _doubleTapZoomFactor = MAX(0, doubleTapZoomFactor);
}

@end
