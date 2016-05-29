// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTView.h"

#import <LTKit/LTAnimation.h>

#import "LTEAGLView.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTProgram.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTexture+Factory.h"
#import "LTViewNavigationView.h"
#import "LTViewPixelGrid.h"
#import "UIColor+Vector.h"

@implementation LTViewRenderingModel

- (instancetype)initWithContext:(LTGLContext *)context contentTexture:(LTTexture *)contentTexture {
  LTParameterAssert(context);
  LTParameterAssert(contentTexture);

  if (self = [super init]) {
    _context = context;
    _contentTexture = contentTexture;
  }
  return self;
}

+ (instancetype)modelWithContext:(LTGLContext *)context contentTexture:(LTTexture *)contentTexture {
  return [[LTViewRenderingModel alloc] initWithContext:context contentTexture:contentTexture];
}

@end

@interface LTView () <LTEAGLViewDelegate>

/// Manager of the location of the content rectangle.
@property (strong, nonatomic) id<LTContentLocationManager> contentLocationManager;

/// Default content scale factor to be used by this view.
@property (nonatomic, readonly) CGFloat defaultContentScaleFactor;

/// OpenGL context to use while drawing on the view.
@property (strong, nonatomic) LTGLContext *context;

/// Target rendering view. The \c LTView's content will be drawn on this view.
@property (strong, nonatomic) LTEAGLView *eaglView;

/// Holds the rectangle that needs to be updated in the next draw.
@property (nonatomic) CGRect contentRectToUpdate;

/// Dimensions of the squares in the checkerboard used to visualize transparency.
@property (nonatomic) NSUInteger pixelsPerCheckerboardSquare;

/// Texture used for visualizing the transparent pixels when \c checkerboardPattern is \c YES.
@property (strong, nonatomic) LTTexture *checkerboardTexture;

/// Texture used for visualizing the transparent pixels when checkerboardPattern is \c NO.
@property (strong, nonatomic) LTTexture *backgroundTexture;

/// Texture used for displaying the content of the LTView.
@property (strong, nonatomic) LTTexture *contentTexture;

/// Fbo used for updating the LTView's content texture.
@property (strong, nonatomic) LTFbo *contentFbo;

/// Rect drawer used for drawing the content texture on the \c LTEAGLView.
@property (strong, nonatomic) LTRectDrawer *rectDrawer;

/// Rect drawer used for drawing the checkerboard background.
@property (strong, nonatomic) LTRectDrawer *backgroundDrawer;

/// Manages the pixel grid drawn on the LTView on certain zoom levels.
@property (strong, nonatomic) LTViewPixelGrid *pixelGrid;

/// Size of the \c LTView's framebuffer, in pixels, before the next redrawing of the underlying
/// \c LTEAGLView.
@property (nonatomic) CGSize previousFramebufferSize;

/// When set to \c YES, the \c LTView will forward touch events to its delegate.
@property (nonatomic) BOOL forwardCallsToTouchDelegate;

/// While set to \c YES, the \c navigationMode property will not be updated.
@property (nonatomic) BOOL isNavigationModeLocked;

/// While set to \c YES, the \c forwardTouchesToDelegate property will not be updated.
@property (nonatomic) BOOL isForwardTouchesToDelegateLocked;

/// \c CGRect used upon the most recent initialization of the internal \c eaglView. Is stored in
/// order to refrain from unnecessarily recreating the \c eaglView upon calls to \c layoutSubviews.
@property (nonatomic) CGRect mostRecentlyUsedEaglViewFrame;

@end

@implementation LTView

/// Name of the notification indicating a setNeedsDisplay is needed.
static NSString * const kSetNeedsDisplayNotification = @"LTViewSetNeedsDisplay";

// The minimal zoom scale that will start using nearest neighbor interpolation for displaying the
// content on the LTView.
static const CGFloat kMinimalZoomScaleForNNInterpolation = 3;

/// Number of pixels per checkerboard square, must be a power of two.
static const NSUInteger kDefaultPixelsPerCheckerboardSquare = 8;

- (instancetype)initWithFrame:(CGRect)frame
       contentLocationManager:(id<LTContentLocationManager>)contentLocationManager
               renderingModel:(LTViewRenderingModel *)renderingModel {
  LTParameterAssert(renderingModel.contentTexture.size == contentLocationManager.contentSize,
                    @"Size of content texture must match content size provided by content location "
                    "manager");

  if (self = [super initWithFrame:frame]) {
    _defaultContentScaleFactor = contentLocationManager.contentScaleFactor;
    [super setContentScaleFactor:self.defaultContentScaleFactor];
    self.pixelsPerCheckerboardSquare = kDefaultPixelsPerCheckerboardSquare * 2;
    [self setupWithContext:renderingModel.context
            contentTexture:renderingModel.contentTexture
    contentLocationManager:contentLocationManager];
  }
  return self;
}

- (void)setupWithContext:(LTGLContext *)context contentTexture:(LTTexture *)texture
  contentLocationManager:(id<LTContentLocationManager>)contentLocationManager {
  LTParameterAssert(context);
  LTParameterAssert(texture);

  self.context = context;
  self.contentTexture = texture;
  self.contentRectToUpdate = CGRectNull;
  self.contentLocationManager = contentLocationManager;
  [self createEaglView];
  [self createContentFbo];
  [self createRectDrawer];
  [self createBackgroundDrawer];
  [self createPixelGrid];
  [self registerNotifications];
  [self setNeedsDisplay];
}

- (void)createEaglView {
  LTAssert(self.context, @"Could not set up LTEAGLView when LTGLContext is nil");

  self.eaglView = [[LTEAGLView alloc] initWithFrame:self.bounds context:self.context
                                 contentScaleFactor:self.contentScaleFactor];
  self.eaglView.delegate = self;
  self.eaglView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.eaglView.multipleTouchEnabled = YES;

  [self addSubview:self.eaglView];

  self.mostRecentlyUsedEaglViewFrame = self.bounds;
}

- (void)createContentFbo {
  self.contentFbo = [[LTFboPool currentPool] fboWithTexture:self.contentTexture];
}

- (void)createRectDrawer {
  self.rectDrawer = [[LTRectDrawer alloc] initWithSourceTexture:self.contentTexture];
}

- (void)createBackgroundDrawer {
  [self createBackgroundTextures];
  self.backgroundDrawer = [[LTRectDrawer alloc] initWithSourceTexture:self.textureForBackground];
}

- (void)createBackgroundTextures {
  unsigned int pixels = (unsigned int)self.pixelsPerCheckerboardSquare;
  cv::Mat4b checkerboardMat = LTWhiteGrayCheckerboardPattern(CGSizeMakeUniform(2 * pixels), pixels);
  self.checkerboardTexture = [LTTexture textureWithImage:checkerboardMat];
  self.backgroundTexture =
      [LTTexture textureWithImage:cv::Mat4b(1, 1, self.backgroundColor.lt_cvVector)];

  for (LTTexture *texture in @[self.backgroundTexture, self.checkerboardTexture]) {
    texture.minFilterInterpolation = LTTextureInterpolationNearest;
    texture.magFilterInterpolation = LTTextureInterpolationNearest;
    texture.wrap = LTTextureWrapRepeat;
  }
}

- (void)createPixelGrid {
  self.pixelGrid = [[LTViewPixelGrid alloc] initWithContentSize:self.contentSize];
  self.pixelGrid.maxZoomScale = self.contentLocationManager.maxZoomScale;
}

- (void)registerNotifications {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSetNeedsDisplayNotification
                                                object:self];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(eaglSetNeedsDisplayNotification:)
                                               name:kSetNeedsDisplayNotification object:self];
}

- (void)teardown {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSetNeedsDisplayNotification
                                                object:self];
  self.pixelGrid = nil;
  self.backgroundDrawer = nil;
  self.checkerboardTexture = nil;
  self.rectDrawer = nil;
  self.contentFbo = nil;
  self.contentTexture = nil;
  self.eaglView = nil;
  self.context = nil;
}

- (void)dealloc {
  [self teardown];
}

#pragma mark -
#pragma mark UIView
#pragma mark -

- (void)layoutSubviews {
  [super layoutSubviews];

  if (!self.context || (self.mostRecentlyUsedEaglViewFrame == self.bounds)) {
    return;
  }

  if ([self.touchDelegate respondsToSelector:@selector(ltViewStopTouchHandling:)]) {
    [self.touchDelegate ltViewStopTouchHandling:self];
  }

  // Due to an obscure bug occurring on the iPad Pro leading to freezing of the application upon
  // device rotations, the internally used \c LTEAGLView must be recreated upon layout change
  // requests.
  NSArray<UIGestureRecognizer *> *recognizers = self.eaglView.gestureRecognizers;
  self.eaglView.gestureRecognizers = @[];
  [self createEaglView];
  self.eaglView.gestureRecognizers = recognizers;
}

#pragma mark -
#pragma mark Views
#pragma mark -

- (void)setEaglView:(LTEAGLView *)eaglView {
  [_eaglView removeFromSuperview];
  _eaglView = eaglView;
}

#pragma mark -
#pragma mark Content Texture
#pragma mark -

- (void)replaceContentWith:(LTTexture *)texture {
  LTParameterAssert(texture);
  self.contentTexture = texture;
  [self createContentFbo];
  [self createRectDrawer];
  [self createPixelGrid];

  if (self.contentLocationManager.contentSize != self.contentTexture.size) {
    self.contentLocationManager.contentSize = self.contentTexture.size;
  }
}

- (void)detachFbo {
  self.contentFbo = nil;
}

- (void)reattachFbo {
  if (self.contentTexture) {
    [self createContentFbo];
  }
}

#pragma mark -
#pragma mark LTViewNavigationViewDelegate
#pragma mark -

- (void)didNavigateToRect:(CGRect)visibleRect {
  if ([self.navigationDelegate respondsToSelector:@selector(ltViewDidNavigateToRect:)]) {
    [self.navigationDelegate ltViewDidNavigateToRect:visibleRect];
  }
  [self setNeedsDisplay];
}

- (void)userPanned {
  if ([self.navigationDelegate respondsToSelector:@selector(ltViewUserPanned)]) {
    [self.navigationDelegate ltViewUserPanned];
  }
}

- (void)userPinched {
  if ([self.navigationDelegate respondsToSelector:@selector(ltViewUserPinched)]) {
    [self.navigationDelegate ltViewUserPinched];
  }
}

- (void)userDoubleTapped {
  if ([self.navigationDelegate respondsToSelector:@selector(ltViewUserDoubleTapped)]) {
    [self.navigationDelegate ltViewUserDoubleTapped];
  }
}

#pragma mark -
#pragma mark LTEAGLViewDelegate
#pragma mark -

- (void)eaglView:(LTEAGLView __unused *)eaglView drawInRect:(__unused CGRect)rect {
  [self informAboutFramebufferChangesIfRequired];

  [self.context executeAndPreserveState:^(LTGLContext *context) {
    context.renderingToScreen = YES;
    [self drawToBoundFramebuffer];
  }];
  
  // We don't need the \c LTEAGLView buffers for the next draw, so hint that they can be discarded.
  // (Since we clear the buffers at the beginning of each draw cycle).
  const std::array<GLenum, 2> discards{{GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT}};
  [self.context executeForOpenGLES2:^{
    glDiscardFramebufferEXT(GL_FRAMEBUFFER, discards.size(), discards.data());
  } openGLES3:^{
    glInvalidateFramebuffer(GL_FRAMEBUFFER, discards.size(), discards.data());
  }];
}

- (void)informAboutFramebufferChangesIfRequired {
  CGSize currentFramebufferSize = self.framebufferSize;
  if (currentFramebufferSize != self.previousFramebufferSize) {
    self.previousFramebufferSize = currentFramebufferSize;
    if ([self.framebufferDelegate respondsToSelector:@selector(ltView:framebufferChangedToSize:)]) {
      [self.framebufferDelegate ltView:self framebufferChangedToSize:currentFramebufferSize];
    }
  }
}

#pragma mark -
#pragma mark Touch events
#pragma mark -

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  // Workaround for the iPhone 6 Plus bogus detection of pan gesture.
  [self.contentLocationManager cancelBogusScrollviewPanGesture];

  [super touchesBegan:touches withEvent:event];
  if (self.forwardCallsToTouchDelegate) {
    if ([self.touchDelegate respondsToSelector:@selector(ltView:touchesBegan:withEvent:)]) {
      [self.touchDelegate ltView:self touchesBegan:touches withEvent:event];
    }
  }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  if (self.forwardCallsToTouchDelegate) {
    if ([self.touchDelegate respondsToSelector:@selector(ltView:touchesMoved:withEvent:)]) {
      [self.touchDelegate ltView:self touchesMoved:touches withEvent:event];
    }
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  if (self.forwardCallsToTouchDelegate) {
    if ([self.touchDelegate respondsToSelector:@selector(ltView:touchesEnded:withEvent:)]) {
      [self.touchDelegate ltView:self touchesEnded:touches withEvent:event];
    }
  }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesCancelled:touches withEvent:event];
  if (self.forwardCallsToTouchDelegate) {
    if ([self.touchDelegate respondsToSelector:@selector(ltView:touchesCancelled:withEvent:)]) {
      [self.touchDelegate ltView:self touchesCancelled:touches withEvent:event];
    }
  }
}

- (void)setTouchDelegate:(id<LTViewTouchDelegate>)touchDelegate {
  if (touchDelegate == _touchDelegate) {
    return;
  }

  if (self.forwardCallsToTouchDelegate) {
    [_touchDelegate ltViewDetachedFromDelegate:self];
  }
  _touchDelegate = touchDelegate;
  if (self.forwardCallsToTouchDelegate) {
    [_touchDelegate ltViewAttachedToDelegate:self];
  }
}

- (void)setForwardTouchesToDelegate:(BOOL)forwardTouchesToDelegate {
  if (self.isForwardTouchesToDelegateLocked) {
    return;
  }

  self.isForwardTouchesToDelegateLocked = YES;
  _forwardTouchesToDelegate = forwardTouchesToDelegate;
  self.forwardCallsToTouchDelegate = [self shouldForwardTouchEvents];
  self.isForwardTouchesToDelegateLocked = NO;
}

- (LTViewNavigationMode)navigationMode {
  return self.contentLocationManager.navigationMode;
}

- (void)setNavigationMode:(LTViewNavigationMode)navigationMode {
  if (self.isNavigationModeLocked) {
    return;
  }

  self.isNavigationModeLocked = YES;
  self.contentLocationManager.navigationMode = navigationMode;
  self.forwardCallsToTouchDelegate = [self shouldForwardTouchEvents];
  self.isNavigationModeLocked = NO;
}

- (BOOL)shouldForwardTouchEvents {
  return self.forwardTouchesToDelegate && self.shouldForwardTouchEventsOnCurrentNavigationMode;
}

- (BOOL)shouldForwardTouchEventsOnCurrentNavigationMode {
  return self.navigationMode == LTViewNavigationNone ||
         self.navigationMode == LTViewNavigationTwoFingers;
}

- (void)setForwardCallsToTouchDelegate:(BOOL)forwardCallsToTouchDelegate {
  if (forwardCallsToTouchDelegate == _forwardCallsToTouchDelegate) {
    return;
  }

  _forwardCallsToTouchDelegate = forwardCallsToTouchDelegate;
  if (forwardCallsToTouchDelegate) {
    [self.touchDelegate ltViewAttachedToDelegate:self];
  } else {
    [self.touchDelegate ltViewDetachedFromDelegate:self];
  }
}

#pragma mark -
#pragma mark For Testing
#pragma mark -

- (void)simulateTouchesOfPhase:(UITouchPhase)phase {
  switch (phase) {
  case UITouchPhaseBegan:
      [self touchesBegan:[NSSet set] withEvent:nil];
    break;
  case UITouchPhaseMoved:
      [self touchesMoved:[NSSet set] withEvent:nil];
    break;
  case UITouchPhaseEnded:
      [self touchesEnded:[NSSet set] withEvent:nil];
    break;
  case UITouchPhaseCancelled:
      [self touchesCancelled:[NSSet set] withEvent:nil];
    break;
  default:
    break;
  }
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawToBoundFramebuffer {
  [self updateContent];
  
  [self.context clearWithColor:self.backgroundColor.lt_ltVector];
  
  // Get the visible content rectangle, in floating-point pixel units of the content coordinate
  // system.
  CGRect visibleContentRect = self.visibleContentRect;
  
  [self.context executeAndPreserveState:^(LTGLContext *context) {
    // Set the scissor box to draw only inside the visible content rect.
    context.scissorTestEnabled = YES;
    context.scissorBox = [self scissorBoxForVisibleContentRect:visibleContentRect];
    
    // Draw the content.
    [self drawContentForVisibleContentRect:visibleContentRect];
    
    // Draw the checkerboard background to visualize transparent content pixels.
    [self drawTransparencyBackground];

    // Draw the overlays.
    [self drawOverlayForVisibleContentRect:visibleContentRect];
  }];
}

- (void)drawToFbo:(LTFbo *)fbo {
  [fbo bindAndDrawOnScreen:^{
    [self drawToBoundFramebuffer];
  }];
}

- (void)updateContent {
  // If the rect to update is not null or empty, we'll have to update the content texture.
  if (!CGRectIsNull(self.contentRectToUpdate) && !CGRectIsEmpty(self.contentRectToUpdate)) {
    // Bind to offscreen framebuffer, and call the delegate to draw the content on it.
    [self.contentFbo bindAndExecute:^{
      if ([self.drawDelegate respondsToSelector:@selector(ltView:updateContentInRect:)]) {
        [self.drawDelegate ltView:self updateContentInRect:self.contentRectToUpdate];
      }
    }];
    
    // Reset the rectToDraw.
    self.contentRectToUpdate = CGRectNull;
  }
}

- (void)drawTransparencyBackground {
  if (!self.contentTransparency) {
    return;
  }

  /// Blend function used for drawing the checkerboard visualizing the transparent content pixels.
  /// This uses the destination (the content that was already drawn) alpha for the blending factor,
  /// and the source alpha (expected to be 1) for the alpha result.
  static const LTGLContextBlendFuncArgs kLTGLContextBlendFuncChecker = {
    .sourceRGB = LTGLContextBlendFuncOneMinusDstAlpha,
    .destinationRGB = LTGLContextBlendFuncOne,
    .sourceAlpha = LTGLContextBlendFuncOne,
    .destinationAlpha = LTGLContextBlendFuncZero
  };
  
  [self.context executeAndPreserveState:^(LTGLContext *context) {
    context.blendEnabled = YES;
    context.blendFunc = kLTGLContextBlendFuncChecker;
    context.blendEquation = kLTGLContextBlendEquationDefault;
    
    [self.backgroundDrawer drawRect:self.framebufferBounds
              inFramebufferWithSize:self.framebufferSize fromRect:self.framebufferBounds];
  }];
}

- (void)drawContentForVisibleContentRect:(CGRect)visibleContentRect {
  // If the draw delegate supports the content texture override mechanism, get it.
  LTTexture *textureToDraw = self.contentTexture;
  if ([self.drawDelegate respondsToSelector:@selector(alternativeContentTexture)]) {
    textureToDraw = [self.drawDelegate alternativeContentTexture] ?: textureToDraw;
  }

  // Set the magnifying filter interpolation according to the current zoom scale.
  // Note that this won't cause a glTexParameteri call in case the interpolation is already set to
  // the correct value. The interpolation method of the content texture is set anyway, and there is
  // no need to restore it, this avoids unnecessary updates to this texture.
  self.contentTexture.magFilterInterpolation =
      [self textureInterpolationForZoomScale:self.zoomScale];
  [textureToDraw executeAndPreserveParameters:^{
    textureToDraw.magFilterInterpolation = [self textureInterpolationForZoomScale:self.zoomScale];
    
    [self.context executeAndPreserveState:^(LTGLContext *) {
      // If the draw delegate supports the drawProcessedContent mechanism, use it to draw.
      BOOL didDrawProcessedContent = NO;
      if ([self.drawDelegate respondsToSelector:@selector(ltView:drawProcessedContent:
                                                          withVisibleContentRect:)]) {
        didDrawProcessedContent = [self.drawDelegate ltView:self drawProcessedContent:textureToDraw
                                     withVisibleContentRect:visibleContentRect];
      }
      
      // Otherwise, use the default rectDrawer to draw the content.
      if (!didDrawProcessedContent && textureToDraw) {
        [self.rectDrawer setSourceTexture:textureToDraw];
        [self.rectDrawer drawRect:self.framebufferBounds inFramebufferWithSize:self.framebufferSize
                         fromRect:visibleContentRect];
      }
    }];
  }];
}

- (void)drawOverlayForVisibleContentRect:(CGRect)visibleContentRect {
  [self.pixelGrid drawContentRegion:visibleContentRect toFramebufferWithSize:self.framebufferSize];
  
  if ([self.drawDelegate
          respondsToSelector:@selector(ltView:drawOverlayAboveContentWithTransform:)]) {
    CGAffineTransform transform = [self transformForVisibleContentRect:visibleContentRect];
    [self.drawDelegate ltView:self drawOverlayAboveContentWithTransform:transform];
  }
}

#pragma mark -
#pragma mark Visible Content Rect Utilities
#pragma mark -

- (CGAffineTransform)transformForVisibleContentRect:(CGRect)rect {
  CGSize scaleRatios = self.framebufferSize / rect.size;
  CGAffineTransform translation = CGAffineTransformMakeTranslation(-rect.origin.x, -rect.origin.y);
  CGAffineTransform scale = CGAffineTransformMakeScale(scaleRatios.width, scaleRatios.height);
  return CGAffineTransformConcat(translation, scale);
}

- (CGRect)scissorBoxForVisibleContentRect:(CGRect)rect {
  // Transform the visible content rect from content coordinates into the LTView's coordaintes.
  CGRect visibleBox = CGRectApplyAffineTransform(self.contentBounds,
                                                 [self transformForVisibleContentRect:rect]);
  
  UIEdgeInsets insets = self.contentLocationManager.contentInset * self.contentScaleFactor;
  CGRect paddingBox = UIEdgeInsetsInsetRect(self.framebufferBounds, insets);
  CGRect box = CGRectIntersection(visibleBox, paddingBox);
  
  // Flip vertically, since the scissor box is defined in openGL coordinates ((0,0) on bottom left).
  box = CGRectFromEdges(CGRectGetMinX(box), self.framebufferSize.height - CGRectGetMaxY(box),
                        CGRectGetMaxX(box), self.framebufferSize.height - CGRectGetMinY(box));
  return box;
}

- (LTTextureInterpolation)textureInterpolationForZoomScale:(CGFloat)zoomScale {
  return (zoomScale > kMinimalZoomScaleForNNInterpolation) ?
      LTTextureInterpolationNearest : LTTextureInterpolationLinear;
}

#pragma mark -
#pragma mark Size and Bounds
#pragma mark -

- (CGSize)framebufferSize {
  return self.eaglView.drawableSize;
}

- (CGRect)framebufferBounds {
  return CGRectFromOriginAndSize(CGPointZero, self.framebufferSize);
}

- (CGSize)contentSize {
  return self.contentTexture.size;
}

- (CGRect)contentBounds {
  return CGRectFromOriginAndSize(CGPointZero, self.contentSize);
}

#pragma mark -
#pragma mark Display updates for the LTEAGLView and the content
#pragma mark -

- (void)setNeedsDisplayContentInRect:(CGRect)rect {
  // Clip the rectangle with the content bounds.
  rect = CGRectIntersection(rect, self.contentBounds);
  self.contentRectToUpdate = CGRectUnion(self.contentRectToUpdate, rect);
  [self eaglSetNeedsDisplay];
}

- (void)setNeedsDisplayContent {
  self.contentRectToUpdate = self.contentBounds;
  [self eaglSetNeedsDisplay];
}

- (void)setNeedsDisplayInRect:(CGRect __unused)rect {
  [self eaglSetNeedsDisplay];
}

- (void)setNeedsDisplay {
  [self eaglSetNeedsDisplay];
}

- (void)eaglSetNeedsDisplay {
  // In case any display link based animation is active, calling the LTEAGLView's setNeedsDisplay
  // method might cause lags. Calling it from a different runloop using a notification, appears to
  // to solve the issue.
  if ([LTAnimation isAnyAnimationRunning]) {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kSetNeedsDisplayNotification object:self];
  } else {
    [self.eaglView setNeedsDisplay];
  }
}

- (void)eaglSetNeedsDisplayNotification:(NSNotification __unused *)notification {
  [self.eaglView setNeedsDisplay];
}

#pragma mark -
#pragma mark Snapshots
#pragma mark -

- (LTImage *)snapshotView {
  LTTexture *texture = [LTTexture byteRGBATextureWithSize:self.framebufferSize];
  LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:texture];
  [fbo bindAndDraw:^{
    [self drawToBoundFramebuffer];
  }];
  return [[LTImage alloc] initWithMat:[texture image] copy:NO];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGFloat)contentScaleFactor {
  return self.defaultContentScaleFactor;
}

- (void)setContentScaleFactor:(CGFloat __unused)contentScaleFactor {
  // Disallow updating of the content scale factor after initialization.
}

- (LTTexture *)textureForBackground {
  return self.checkerboardPattern ? self.checkerboardTexture : self.backgroundTexture;
}

- (void)setCheckerboardPattern:(BOOL)checkerboardPattern {
  _checkerboardPattern = checkerboardPattern;
  [self.backgroundDrawer setSourceTexture:self.textureForBackground];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
  [super setBackgroundColor:backgroundColor];
  [self.backgroundTexture clearWithColor:backgroundColor.lt_ltVector];
}

- (id<LTContentLocationProvider>)contentLocationProvider {
  return self.contentLocationManager;
}

- (UIView *)gestureView {
  return self.eaglView;
}

- (CGRect)visibleContentRect {
  CGRect visibleContentRect = self.contentLocationManager.visibleContentRect;
  visibleContentRect.origin = visibleContentRect.origin * self.contentScaleFactor;
  visibleContentRect.size = visibleContentRect.size * self.contentScaleFactor;
  return visibleContentRect;
}

- (CGFloat)zoomScale {
  return self.contentLocationManager.zoomScale;
}

@end
