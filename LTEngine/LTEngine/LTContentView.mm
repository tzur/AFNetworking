// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentView.h"

#import "LTContentInteractionManager.h"
#import "LTContentNavigationDelegate.h"
#import "LTContentTouchEventDelegate.h"
#import "LTNavigationView.h"
#import "LTPresentationView.h"
#import "LTTexture+Factory.h"
#import "LTTouchEventDelegate.h"
#import "LTTouchEventSequenceSplitter.h"
#import "LTTouchEventSequenceValidator.h"
#import "LTTouchEventView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTContentView () <LTContentNavigationDelegate, LTNavigationViewDelegate,
    LTTouchEventDelegate>

/// View used to receive touch events.
@property (readonly, nonatomic) LTTouchEventView *touchEventView;

/// Object used to split touch event sequences.
@property (readonly, nonatomic) LTTouchEventSequenceSplitter *touchEventSequenceSplitter;

/// Object used to validate touch event sequences and forward them to a filter ensuring that the
/// timestamps of the touch events are monotonically increasing.
@property (readonly, nonatomic) LTTouchEventSequenceValidator *touchEventSequenceValidator;

/// Object responsible for managing which gestures should be allowed to modify the location of the
/// content rectangle. In addition, handles the forwarding of touch events occurring on this view
/// and allows attaching/detaching custom gesture recognizers to this view.
@property (readonly, nonatomic) LTContentInteractionManager *interactionManager;

/// View responsible for managing the navigation of the content rectangle (both programmatically and
/// via gestures) and providing information about its current location.
@property (readonly, nonatomic) LTNavigationView *navigationView;

/// Object used to convert between content coordinates and presentation coordinates.
@property (readonly, nonatomic) id<LTContentCoordinateConverter> converter;

/// View used for presenting the image content.
@property (readonly, nonatomic) LTPresentationView *presentationView;

@end

@implementation LTContentView

@synthesize navigationDelegate = _navigationDelegate;

// LTContentCoordinateConverter protocol.
@dynamic contentToPresentationCoordinateTransform;
@dynamic presentationToContentCoordinateTransform;
@dynamic contentToPixelPresentationCoordinateTransform;
@dynamic pixelPresentationToContentCoordinateTransform;

// LTContentInteractionManager protocol.
@dynamic customGestureRecognizers;
@dynamic contentTouchEventDelegate;
@dynamic interactionMode;

// LTContentNavigationManager protocol.
@dynamic bounceToAspectFit;
@dynamic navigationState;
@dynamic minZoomScaleFactor;

// LTContentLocationProvider protocol.
@dynamic contentInset;
@dynamic contentScaleFactor;
@dynamic contentSize;
@dynamic minZoomScale;
@dynamic maxZoomScale;
@dynamic zoomScale;

// LTContentDisplayManager protocol.
@dynamic visibleContentRect;
@dynamic drawDelegate;
@dynamic framebufferDelegate;
@dynamic framebufferSize;
@dynamic contentTextureSize;
@dynamic contentTransparency;
@dynamic checkerboardPattern;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithContext:(LTGLContext *)context {
  return [self initWithContext:context contentTexture:nil navigationState:nil];
}

- (instancetype)initWithContext:(LTGLContext *)context
                 contentTexture:(nullable LTTexture *)contentTexture
                navigationState:(nullable LTContentNavigationState *)navigationState {
  return [self initWithFrame:CGRectZero contentScaleFactor:[UIScreen mainScreen].nativeScale
                     context:context contentTexture:contentTexture navigationState:navigationState];
}

- (instancetype)initWithFrame:(CGRect)frame
           contentScaleFactor:(CGFloat)contentScaleFactor
                      context:(LTGLContext *)context
               contentTexture:(nullable LTTexture *)contentTexture
              navigationState:(nullable LTContentNavigationState *)navigationState {
  LTParameterAssert(contentScaleFactor > 0, @"Given content scale factor (%g) must be positive",
                    contentScaleFactor);

  if (!contentTexture) {
    contentTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    [contentTexture clearColor:LTVector4::zeros()];
  }

  if (self = [super initWithFrame:frame]) {
    [super setContentScaleFactor:contentScaleFactor];
    [self createNavigationViewWithFrame:self.bounds contentSize:contentTexture.size
                     contentScaleFactor:contentScaleFactor navigationState:navigationState];
    [self createPresentationViewWithFrame:self.bounds context:context
                           contentTexture:contentTexture];
    [self createTouchEventSequenceSplitter];
    [self createTouchEventValidatorAndFilter];
    [self createTouchEventViewWithFrame:self.bounds];
    [self createInteractionManager];
    [self createConverter];
    [self bindNavigationViewComponents];
    [self updateDefaultGestureRecognizers];
  }
  return self;
}

- (void)createNavigationViewWithFrame:(CGRect)frame
                          contentSize:(CGSize)contentSize
                   contentScaleFactor:(CGFloat)contentScaleFactor
                      navigationState:(nullable LTContentNavigationState *)navigationState {
  LTParameterAssert(!navigationState ||
                    [navigationState isKindOfClass:[LTNavigationViewState class]],
                    @"Provided navigation state (%@) of invalid class", navigationState);

  _navigationView =
      [[LTNavigationView alloc] initWithFrame:frame contentSize:contentSize
                           contentScaleFactor:contentScaleFactor
                              navigationState:(LTNavigationViewState *)navigationState];
  self.navigationView.hidden = YES;
  [self addSubview:self.navigationView];
}

- (void)createPresentationViewWithFrame:(CGRect)frame context:(LTGLContext *)context
                         contentTexture:(LTTexture *)contentTexture {
  LTAssert(self.navigationView);

  _presentationView = [[LTPresentationView alloc] initWithFrame:frame context:context
                                                 contentTexture:contentTexture
                                        contentLocationProvider:self.navigationView];
  [self addSubview:self.presentationView];
}

- (void)createTouchEventSequenceSplitter {
  _touchEventSequenceSplitter =
      [[LTTouchEventSequenceSplitter alloc] initWithTouchEventDelegate:self];
}

- (void)createTouchEventValidatorAndFilter {
  LTAssert(self.touchEventSequenceSplitter);
  _touchEventSequenceValidator =
      [[LTTouchEventSequenceValidator alloc] initWithDelegate:self.touchEventSequenceSplitter
                                                 heldStrongly:NO];
}

- (void)createTouchEventViewWithFrame:(CGRect)frame {
  LTAssert(self.presentationView);
  LTAssert(self.touchEventSequenceValidator);

  _touchEventView = [[LTTouchEventView alloc] initWithFrame:frame
                                                   delegate:self.touchEventSequenceValidator];
  [self addSubview:self.touchEventView];
}

- (void)createInteractionManager {
  LTAssert(self.touchEventView);

  _interactionManager = [[LTContentInteractionManager alloc] initWithView:self.touchEventView];
}

- (void)createConverter {
  LTAssert(self.navigationView);

  _converter =
      [[LTContentCoordinateConverter alloc] initWithLocationProvider:self.navigationView];
}

- (void)bindNavigationViewComponents {
  LTAssert(self.navigationView);
  LTAssert(self.interactionManager);
  LTAssert(self.presentationView);

  self.navigationView.interactionModeProvider = self.interactionManager;
  self.navigationView.contentSize = self.presentationView.contentTextureSize;
  self.navigationView.navigationDelegate = self;
  self.navigationView.delegate = self;
}

- (void)updateDefaultGestureRecognizers {
  LTAssert(self.navigationView);

  self.interactionManager.defaultGestureRecognizers =
      [[LTInteractionGestureRecognizers alloc]
       initWithTapRecognizer:self.navigationView.doubleTapGestureRecognizer
       panRecognizer:self.navigationView.panGestureRecognizer
       pinchRecognizer:self.navigationView.pinchGestureRecognizer];
}

#pragma mark -
#pragma mark UIView
#pragma mark -

- (void)layoutSubviews {
  [super layoutSubviews];

  self.presentationView.frame = self.bounds;
  self.navigationView.frame = self.bounds;
  self.touchEventView.frame = self.bounds;
}

- (void)setContentScaleFactor:(__unused CGFloat)contentScaleFactor {
  // Disallow updates of the content scale factor.
}

#pragma mark -
#pragma mark LTTouchEventDelegate
#pragma mark -

- (void)receivedTouchEvents:(LTTouchEvents *)touchEvents
            predictedEvents:(LTTouchEvents *)predictedTouchEvents
    touchEventSequenceState:(LTTouchEventSequenceState)state {
  [self.interactionManager
   receivedContentTouchEvents:[self contentTouchEventsForTouchEvents:touchEvents]
   predictedEvents:[self contentTouchEventsForTouchEvents:predictedTouchEvents]
   touchEventSequenceState:state];
}

- (void)receivedUpdatesOfTouchEvents:(LTTouchEvents *)touchEvents {
  [self.interactionManager
   receivedUpdatesOfContentTouchEvents:[self contentTouchEventsForTouchEvents:touchEvents]];
}

- (void)touchEventSequencesWithIDs:(NSSet<NSNumber *> *)sequenceIDs
               terminatedWithState:(LTTouchEventSequenceState)state {
  [self.interactionManager contentTouchEventSequencesWithIDs:sequenceIDs terminatedWithState:state];
}

#pragma mark -
#pragma mark Conversion of touch events
#pragma mark -

- (LTContentTouchEvents *)contentTouchEventsForTouchEvents:(LTTouchEvents *)touchEvents {
  if (!touchEvents.count) {
    return @[];
  }

  NSMutableArray<id<LTContentTouchEvent>> *contentTouchEvents =
      [NSMutableArray arrayWithCapacity:touchEvents.count];

  for (id<LTTouchEvent> touchEvent in touchEvents) {
    [contentTouchEvents addObject:[self contentTouchEventFromTouchEvent:touchEvent]];
  }

  return [contentTouchEvents copy];
}

- (id<LTContentTouchEvent>)contentTouchEventFromTouchEvent:(id<LTTouchEvent>)touchEvent {
  return [[LTContentTouchEvent alloc]
          initWithTouchEvent:touchEvent
          contentSize:self.navigationView.contentSize
          contentZoomScale:self.navigationView.zoomScale
          transform:self.presentationToContentCoordinateTransform];
}

#pragma mark -
#pragma mark Proxying
#pragma mark -

- (BOOL)conformsToProtocol:(Protocol *)protocol {
  return [self.interactionManager conformsToProtocol:protocol] ||
      [self.navigationView conformsToProtocol:protocol] ||
      [self.presentationView conformsToProtocol:protocol] ||
      [self.converter conformsToProtocol:protocol] ||
      [super conformsToProtocol:protocol];
}

- (BOOL)respondsToSelector:(SEL)selector {
  return [self.interactionManager respondsToSelector:selector] ||
      [self.navigationView respondsToSelector:selector] ||
      [self.presentationView respondsToSelector:selector] ||
      [self.converter respondsToSelector:selector] ||
      [super respondsToSelector:selector];
}

- (id)forwardingTargetForSelector:(SEL)selector {
  if ([self.interactionManager respondsToSelector:selector]) {
    return self.interactionManager;
  }
  else if ([self.navigationView respondsToSelector:selector]) {
    return self.navigationView;
  }
  else if ([self.presentationView respondsToSelector:selector]) {
    return self.presentationView;
  }
  else if ([self.converter respondsToSelector:selector]) {
    return self.converter;
  }
  return [super forwardingTargetForSelector:selector];
}

#pragma mark -
#pragma mark LTContentInteractionManager
#pragma mark -

- (void)setInteractionMode:(LTInteractionMode)interactionMode {
  self.interactionManager.interactionMode = interactionMode;
  [self.navigationView interactionModeUpdated];
}

// Manually override getter in order to correctly support KVO compliance.
- (nullable NSArray<UIGestureRecognizer *> *)customGestureRecognizers {
  return self.interactionManager.customGestureRecognizers;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCustomGestureRecognizers {
  return [NSSet setWithObject:@instanceKeypath(LTContentView,
                                               interactionManager.customGestureRecognizers)];
}

- (BOOL)isCurrentlyReceivingContentTouchEvents {
  return self.interactionManager.isCurrentlyReceivingContentTouchEvents;
}

- (BOOL)forwardStationaryContentTouchEvents {
  return self.interactionManager.forwardStationaryContentTouchEvents;
}

- (void)setForwardStationaryContentTouchEvents:(BOOL)forwardStationaryContentTouchEvents {
  self.interactionManager.forwardStationaryContentTouchEvents = forwardStationaryContentTouchEvents;
}

#pragma mark -
#pragma mark LTContentCoordinateConverter
#pragma mark -

- (CGPoint)convertPointFromContentToPresentationCoordinates:(CGPoint)point {
  return [self.converter convertPointFromContentToPresentationCoordinates:point];
}

- (CGPoint)convertPointFromContentToPixelPresentationCoordinates:(CGPoint)point {
  return [self.converter convertPointFromContentToPixelPresentationCoordinates:point];
}

- (CGPoint)convertPointFromPresentationToContentCoordinates:(CGPoint)point {
  return [self.converter convertPointFromPresentationToContentCoordinates:point];
}

- (CGPoint)convertPointFromPixelPresentationToContentCoordinates:(CGPoint)point {
  return [self.converter convertPointFromPixelPresentationToContentCoordinates:point];
}

#pragma mark -
#pragma mark LTContentNavigationManager
#pragma mark -

- (void)navigateToState:(LTContentNavigationState *)state {
  [self.navigationView navigateToState:state];
}

#pragma mark -
#pragma mark LTContentRefreshing
#pragma mark -

- (void)setNeedsDisplay {
  [self.presentationView setNeedsDisplay];
}

- (void)setNeedsDisplayContentInRect:(CGRect)rect {
  [self.presentationView setNeedsDisplayContentInRect:rect];
}

- (void)setNeedsDisplayContent {
  [self.presentationView setNeedsDisplayContent];
}

#pragma mark -
#pragma mark LTContentDisplayManager
#pragma mark -

- (void)replaceContentWith:(LTTexture *)texture {
  self.navigationView.contentSize = texture.size;
  [self.presentationView replaceContentWith:texture];
}

- (LTImage *)snapshotView {
  return [self.presentationView snapshotView];
}

- (nullable UIColor *)backgroundColor {
  return self.presentationView.backgroundColor;
}

- (void)setBackgroundColor:(nullable UIColor *)backgroundColor {
  self.presentationView.backgroundColor = backgroundColor;
}

#pragma mark -
#pragma mark LTContentNavigationDelegate
#pragma mark -

- (void)navigationManager:(id<LTContentNavigationManager>)manager
 didNavigateToVisibleRect:(CGRect)visibleRect {
  LTParameterAssert(manager == self.navigationView, @"Invalid manager (%@) provided", manager);

  if ([self.navigationDelegate
       respondsToSelector:@selector(navigationManager:didNavigateToVisibleRect:)]) {
    [self.navigationDelegate navigationManager:self didNavigateToVisibleRect:visibleRect];
  }
  [self.presentationView setNeedsDisplay];
}

- (void)navigationManagerDidHandlePanGesture:(id<LTContentNavigationManager>)manager {
  LTParameterAssert(manager == self.navigationView, @"Invalid manager (%@) provided", manager);

  if ([self.navigationDelegate
       respondsToSelector:@selector(navigationManagerDidHandlePanGesture:)]) {
    [self.navigationDelegate navigationManagerDidHandlePanGesture:self];
  }
}

- (void)navigationManagerDidHandlePinchGesture:(id<LTContentNavigationManager>)manager {
  LTParameterAssert(manager == self.navigationView, @"Invalid manager (%@) provided", manager);

  if ([self.navigationDelegate
       respondsToSelector:@selector(navigationManagerDidHandlePinchGesture:)]) {
    [self.navigationDelegate navigationManagerDidHandlePinchGesture:self];
  }
}

- (void)navigationManagerDidHandleDoubleTapGesture:(id<LTContentNavigationManager>)manager {
  LTParameterAssert(manager == self.navigationView, @"Invalid manager (%@) provided", manager);

  if ([self.navigationDelegate
       respondsToSelector:@selector(navigationManagerDidHandleDoubleTapGesture:)]) {
    [self.navigationDelegate navigationManagerDidHandleDoubleTapGesture:self];
  }
}

#pragma mark -
#pragma mark LTNavigationViewDelegate
#pragma mark -

- (void)navigationViewReplacedGestureRecognizers:(LTNavigationView *)navigationView {
  LTAssert(navigationView == self.navigationView, @"Received invalid navigation view (%@)",
           navigationView);
  [self updateDefaultGestureRecognizers];
}

#pragma mark -
#pragma mark For testing
#pragma mark -

- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated {
  [self.navigationView zoomToRect:rect animated:animated];
}

@end

NS_ASSUME_NONNULL_END
