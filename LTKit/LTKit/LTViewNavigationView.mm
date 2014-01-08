// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewNavigationView.h"

#import "LTAnimation.h"
#import "LTCGExtensions.h"
#import "NSObject+AddToContainer.h"

#pragma mark -
#pragma mark LTViewNavigationViewState
#pragma mark -

@interface LTViewNavigationState ()
@property (nonatomic) CGRect visibleContentRect;
@property (nonatomic) CGPoint contentOffset;
@property (nonatomic) UIEdgeInsets contentInset;
@property (nonatomic) CGFloat zoomScale;
@property (nonatomic) BOOL animationActive;
@end

@implementation LTViewNavigationState
@end

#pragma mark -
#pragma mark LTViewNavigationView
#pragma mark -

@interface LTViewNavigationView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

/// Scroll view for scroll events and gestures.
@property (strong, nonatomic) UIScrollView *scrollView;

/// A content view that lies inside the scroll view, representing the content.
@property (strong, nonatomic) UIImageView *contentView;

/// Gesture recognizer responsible on the double tap zoom in/out gesture.
@property (strong, nonatomic) UITapGestureRecognizer *doubleTapRecognizer;

/// Indicates whether the scrollview is currently dragging.
@property (nonatomic) BOOL scrollViewDragging;

/// Indicates whether the scrollview is currently zooming.
@property (nonatomic) BOOL scrollViewZooming;

/// Indicates whether the scrollview is currently decelerating.
@property (nonatomic) BOOL scrollViewDecelerating;

/// Animation for handling scrollview actions.
@property (strong, nonatomic) LTAnimation *animation;

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
    [self createDoubleTapRecognizer];
    [self navigateToState:state];
  }
  return self;
}

- (void)setDefaults {
  self.mode = LTViewNavigationFull;
  self.maxZoomScale = CGFLOAT_MAX;
  self.contentScaleFactor = [UIScreen mainScreen].scale;
}

- (void)createScrollView {
  LTAssert(!self.scrollView, @"ScrollView must be set only once");
  self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectInset(self.bounds,
                                                                    self.padding, self.padding)];
  self.scrollView.contentScaleFactor = self.contentScaleFactor;
  self.scrollView.contentSize = self.contentSize / self.contentScaleFactor;
  // TODO:(amit) replace with autolayout.
  self.scrollView.autoresizingMask =
      UIViewAutoresizingFlexibleBottomMargin  | UIViewAutoresizingFlexibleTopMargin   |
      UIViewAutoresizingFlexibleLeftMargin    | UIViewAutoresizingFlexibleRightMargin |
      UIViewAutoresizingFlexibleWidth         | UIViewAutoresizingFlexibleHeight;
  
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
  
  // Create a dummy view to be inside the scroll view. this is necessary for the zoom to work (this
  // view will be returned by the viewForZoomingInScrollView delegate method). This view will be
  // used to represent the content currently visible.
  CGRect contentBounds = CGRectFromOriginAndSize(CGPointZero, self.scrollView.contentSize);
  self.contentView = [[UIImageView alloc] initWithFrame:contentBounds];
  self.contentView.contentScaleFactor = self.contentScaleFactor;
  [self.scrollView addSubview:self.self.contentView];
  
  // Register the animation notification.
  [[NSNotificationCenter defaultCenter]
      addObserver:self selector:@selector(updateVisibleContentRectDuringAnimation)
             name:kScrollAnimationNotification object:self];
}

- (void)navigateToState:(LTViewNavigationState *)state {
  // If we have a state that should override the default state, use it.
  if (state) {
    self.scrollView.zoomScale = state.zoomScale;
    self.scrollView.contentOffset = state.contentOffset;
    self.scrollView.contentInset = state.contentInset;
    self.visibleContentRect = state.visibleContentRect;
    if (state.animationActive) {
      [self startAnimationIfNotRunning];
    }
  } else {
    // Otherwise, set the current zoom scale to the minimum possible.
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    [self centerContentView];
    self.visibleContentRect = [self visibleContentRectFromScrollView];
  }
  
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
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kScrollAnimationNotification
                                                object:self];
  
  [self.scrollView removeFromSuperview];
  [self.contentView removeFromSuperview];
}

#pragma mark -
#pragma mark ScrollView
#pragma mark -

/// Congifures the scrollview's minimal and maximal zoom scale according to the bounds and content
/// size.
- (void)configureScrollViewZoomLimits {
  CGFloat zoomScale = self.scrollView.zoomScale;
  self.scrollView.zoomScale = 1;
  self.scrollView.maximumZoomScale = self.maxZoomScale;

  // Set minimal zoom scale by finding the dimension that can be minimally scaled.
  CGSize ratio = self.scrollView.bounds.size / self.scrollView.contentSize;
  CGFloat minimumZoomScale = fmin(ratio.width, ratio.height);
  
  // End case - if the minimal zoom scale is going to be larger than the maximal zoom scale, set the
  // maximal zoom scale to be the minimal one. This is relevant to small images and will prevent
  // any zooming of the image.
  if (minimumZoomScale > self.scrollView.maximumZoomScale) {
    self.scrollView.maximumZoomScale = minimumZoomScale;
  }
  
  // Set the minimal zoom scale, and restore the previous zoom scale.
  self.scrollView.minimumZoomScale = minimumZoomScale;
  self.scrollView.zoomScale = zoomScale;
}

/// Borrowed from Apple's ScrollViewSuite:
/// http://developer.apple.com/library/ios/#samplecode/ScrollViewSuite/Introduction/Intro.html
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
  CGRect zoomRect;
  
  // The zoom rect is in the content view's coordinates.
  // At a zoom scale of 1.0, it would be the size of the bounds.
  // As the zoom scale decreases, so more content is visible, the size
  // of the rect grows.
  zoomRect.size.height = self.scrollView.frame.size.height / scale;
  zoomRect.size.width = self.scrollView.frame.size.width / scale;
  
  // Choose an origin so as to get the right center.
  zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0);
  zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
  
  return zoomRect;
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
  __weak LTViewNavigationView *weakSelf = self;
  self.animation = [LTAnimation animationWithBlock:
                    ^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                          CFTimeInterval __unused totalAnimationTime) {
    // If the LTView was deallocated, the animation shouldn't continue.
    __strong LTViewNavigationView *strongSelf = weakSelf;
    if (!strongSelf) {
      return NO;
    }
    
    // Update the current visible content rectangle.
    [strongSelf centerContentView];
    CGRect newVisibleContentRect = [strongSelf visibleContentRectFromLayers];
    BOOL updated = !CGRectEqualToRect(newVisibleContentRect, strongSelf.visibleContentRect);
    
    // Instead of updating the content rect here (which will lead to a setNeedsDisplay and in some
    // scenarios hogs the display link, causing the scrollview to get stuck), post a notification on
    // the update. This will cause the setNeedsDisplay to happen elsewhere, and won't block the
    // display link loop. While this is somewhat a hack that can't guarantee the scroll view won't
    // get stuck, it appears that this greatly reduces the chances of this happenning.
    if (updated) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kScrollAnimationNotification
                                                          object:strongSelf];
    }
    
    // If the scroll view is still dragging / zooming / decelerating / animating, the animation
    // should continue.
    if (strongSelf.scrollViewDragging || strongSelf.scrollViewZooming ||
        strongSelf.scrollViewDecelerating) {
      return YES;
    }
    
    // Safety precautions, to make sure we don't stop while something is happening.
    if (strongSelf.scrollView.decelerating || strongSelf.scrollView.dragging ||
        strongSelf.scrollView.zooming) {
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
  return (gestureRecognizer == self.doubleTapRecognizer);
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

// Handle double tap gesture: cycle between different zoom levels controlled by the doubleTapLevels
// and doubleTapZoomFactor properties.
- (void)handleDoubleTapGesture:(UITapGestureRecognizer *)gestureRecognizer {
  // Check if the current zoom scale is at one of the double tap zoom levels.
  // If we're at one of the double tap zoom levels, increase the level (cyclicly). Otherwise, level
  // will be set to 0.
  NSUInteger level = 0;
  for (NSUInteger i = 0; i < self.doubleTapLevels; i++) {
    if (ABS(self.scrollView.zoomScale - [self zoomScaleForLevel:i]) < 1e-4) {
      level = (i + 1) % self.doubleTapLevels;
    }
  }
  
  // Zoom to a rect centered at the tap locaiton, with the zoom scale according to the level.
  CGPoint tap = [gestureRecognizer locationInView:self.contentView];
  CGRect rect = [self zoomRectForScale:[self zoomScaleForLevel:level] withCenter:tap];
  [self.scrollView zoomToRect:rect animated:YES];
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

- (void)setMode:(LTViewNavigationMode)mode {
  _mode = mode;
  switch (mode) {
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
  }
  
  self.doubleTapRecognizer.enabled = (mode == LTViewNavigationFull);
  self.scrollView.delaysContentTouches = (mode != LTViewNavigationNone);
  self.scrollView.canCancelContentTouches = (mode != LTViewNavigationNone);
  self.scrollView.panGestureRecognizer.enabled = (mode != LTViewNavigationNone);
  self.scrollView.pinchGestureRecognizer.enabled = (mode != LTViewNavigationNone);
  
  [self bounceToMinimalZoomIfNecessary];
}

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated {
  [self.scrollView zoomToRect:rect animated:animated];
  if (!animated) {
    self.visibleContentRect = [self visibleContentRectFromScrollView];
  }
}

#pragma mark -
#pragma mark ContentView
#pragma mark -

// Change the contentView's frame so it will appear in the center of the scrollview.
- (void)centerContentView {
  CGPoint inset = CGPointZero;
  
  // Center horizontally.
  if (self.contentView.frame.size.width < self.scrollView.bounds.size.width) {
    inset.x = (self.scrollView.bounds.size.width - self.contentView.frame.size.width) / 2;
  }
  
  // Center vertically.
  if (self.contentView.frame.size.height < self.scrollView.bounds.size.height) {
    inset.y = (self.scrollView.bounds.size.height - self.contentView.frame.size.height) / 2;
  }
  
  self.scrollView.contentInset = UIEdgeInsetsMake(inset.y, inset.x, inset.y, inset.x);
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

- (void)setPadding:(CGFloat)padding {
  if (padding != _padding) {
    // In case we were at the minimal zoom level, we'll have to update the zoom to reflect the
    // updated padding.
    BOOL shouldUpdateZoom = (self.scrollView.zoomScale == self.scrollView.minimumZoomScale);

    // Update the padding, the scrollview's frame, and recalculate the zoom limits.
    _padding = padding;
    self.scrollView.frame = CGRectInset(self.bounds, _padding, _padding);
   [self configureScrollViewZoomLimits];
    
    // Update the zoom scale if necessary.
    if (shouldUpdateZoom) {
      self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    }
    
    // Re-center the content view, and update the visible content rect.
    [self centerContentView];
    self.visibleContentRect = [self visibleContentRectFromScrollView];
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSArray *)navigationGestureRecognizers {
  // Safely add the recognizers, as some of the gesture recognizers might not exist (for example,
  // the pinchGesture might be nil if the image is too small as the minimalZoom and maximalZoom will
  // be equal, invalidating the zoom functionality).
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
  state.contentOffset = self.scrollView.contentOffset;
  state.contentInset = self.scrollView.contentInset;
  state.animationActive = (self.animation) ? (self.animation.isAnimating) : NO;
  return state;
}

- (void)setContentSize:(CGSize)contentSize {
  if (_contentSize == contentSize) {
    return;
  }
  
  _contentSize = contentSize;
  self.scrollView.zoomScale = 1;
  self.scrollView.contentSize = contentSize / self.contentScaleFactor;
  self.contentView.frame = CGRectFromOriginAndSize(CGPointZero, self.scrollView.contentSize);
  [self configureScrollViewZoomLimits];
  [self navigateToState:nil];
}

- (CGFloat)zoomScale {
  return self.scrollView.zoomScale;
}

- (void)setMaxZoomScale:(CGFloat)maxZoomScale {
  _maxZoomScale = MAX(maxZoomScale, 0);
  [self configureScrollViewZoomLimits];
}

- (void)setDoubleTapZoomFactor:(CGFloat)doubleTapZoomFactor {
  _doubleTapZoomFactor = MAX(0, doubleTapZoomFactor);
}

@end
