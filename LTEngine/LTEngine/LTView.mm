// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTView.h"

#import <LTKit/LTAnimation.h>

#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTGLView.h"
#import "LTImage.h"
#import "LTProgram.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTexture+Factory.h"
#import "LTViewNavigationView.h"
#import "LTViewPixelGrid.h"
#import "UIColor+Vector.h"

@interface LTView () <GLKViewDelegate, LTViewNavigationViewDelegate>

/// Screen to get native scale from.
@property (strong, nonatomic) UIScreen *screen;

/// OpenGL context to use while drawing on the view.
@property (strong, nonatomic) LTGLContext *context;

/// Manages the navigation behavior of the view.
@property (strong, nonatomic) LTViewNavigationView *navigationView;

/// Target rendering view. The \c LTView's content will be drawn on this view.
@property (strong, nonatomic) GLKView *glkView;

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

/// RectDrawer used for drawing the content texture on the GLKView.
@property (strong, nonatomic) LTRectDrawer *rectDrawer;

/// RectDrawer used for drawing the checkerboard background.
@property (strong, nonatomic) LTRectDrawer *backgroundDrawer;

/// Manages the pixel grid drawn on the LTView on certain zoom levels.
@property (strong, nonatomic) LTViewPixelGrid *pixelGrid;

/// Size of the \c LTView's framebuffer, in pixels, before the next redrawing of the underlying
/// \c GLKView.
@property (nonatomic) CGSize previousFramebufferSize;

/// When set to \c YES, the \c LTView will forward touch events to its delegate.
@property (nonatomic) BOOL forwardCallsToTouchDelegate;

/// While set to \c YES, the \c navigationMode property will not be updated.
@property (nonatomic) BOOL isNavigationModeLocked;

/// While set to \c YES, the \c forwardTouchesToDelegate property will not be updated.
@property (nonatomic) BOOL isForwardTouchesToDelegateLocked;

/// The underlying gesture recognizer for pinch gestures. KVO compliant.
@property (strong, readwrite, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

/// The underlying gesture recognizer for pinch gestures. Will return \c nil when zooming is
/// disabled. KVO compliant.
@property (strong, readwrite, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;

/// The underlying gesture recognizer for double tap gestures. KVO compliant.
@property (strong, readwrite, nonatomic) UITapGestureRecognizer *doubleTapGestureRecognizer;

@end

@implementation LTView

/// Name of the notification indicating a setNeedsDisplay is needed.
static NSString * const kSetNeedsDisplayNotification = @"LTViewSetNeedsDisplay";

// The minimal zoom scale that will start using nearest neighbor interpolation for displaying the
// content on the LTView.
static const CGFloat kMinimalZoomScaleForNNInterpolation = 3;

/// Default maximal zoom scale.
static const CGFloat kDefaultMaxZoomScale = 16;

/// Default zoom factor for the double tap gesture.
static const CGFloat kDefaultDoubleTapZoomFactor = 3;

/// Default number of levels that the double tap gesture iterates between.
static const NSUInteger kDefaultDoubleTapLevels = 3;

/// Number of pixels per checkerboard square, must be a power of two.
static const NSUInteger kDefaultPixelsPerCheckerboardSquare = 8;

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [[JSObjection defaultInjector] injectDependencies:self];
    [self setDefaults];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [[JSObjection defaultInjector] injectDependencies:self];
    [self setDefaults];
  }
  return self;
}

- (void)setDefaults {
  self.maxZoomScale = kDefaultMaxZoomScale;
  self.doubleTapLevels = kDefaultDoubleTapLevels;
  self.doubleTapZoomFactor = kDefaultDoubleTapZoomFactor;
  self.pixelsPerCheckerboardSquare = kDefaultPixelsPerCheckerboardSquare * 2;
}

- (void)setupWithContext:(LTGLContext *)context contentTexture:(LTTexture *)texture
                   state:(LTViewNavigationState *)state {
  LTParameterAssert(context);
  LTParameterAssert(texture);
  if (self.context) {
    return;
  }
  self.context = context;
  self.contentTexture = texture;
  self.contentRectToUpdate = CGRectNull;
  [self createGlkView];
  [self createNavigationViewWithState:state];
  [self createContentFbo];
  [self createRectDrawer];
  [self createBackgroundDrawer];
  [self createPixelGrid];
  [self registerNotifications];
  [self setNeedsDisplay];
}

- (void)createGlkView {
  LTAssert(self.context, @"Could not set up GLKView when LTGLContext is nil");
  
  // Allocate the glkView and set it up.
  self.glkView = [[LTGLView alloc] initWithFrame:self.bounds];
  self.glkView.contentScaleFactor = self.contentScaleFactor;
  self.glkView.context = self.context.context;
  self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
  self.glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
  self.glkView.drawableMultisample = GLKViewDrawableMultisampleNone;
  self.glkView.drawableStencilFormat = GLKViewDrawableStencilFormatNone;
  self.glkView.enableSetNeedsDisplay = YES;
  self.glkView.delegate = self;
  self.glkView.opaque = YES;
  
  self.glkView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.glkView.multipleTouchEnabled = YES;
  [self addSubview:self.glkView];
}

- (void)createNavigationViewWithState:(LTViewNavigationState *)state {
  self.navigationView = [[LTViewNavigationView alloc] initWithFrame:self.bounds
                                                        contentSize:self.contentTexture.size
                                                              state:state];
  self.navigationView.delegate = self;
  self.navigationView.mode = self.navigationMode;
  self.navigationView.contentInset = self.contentInset;
  self.navigationView.maxZoomScale = self.maxZoomScale;
  self.navigationView.doubleTapLevels = self.doubleTapLevels;
  self.navigationView.doubleTapZoomFactor = self.doubleTapZoomFactor;
  
  self.navigationView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  [self insertSubview:self.navigationView belowSubview:self.glkView];
  [self updateNavigationGestureRecognizers];
}

- (void)updateNavigationGestureRecognizers {
  self.panGestureRecognizer = self.navigationView.panGestureRecognizer;
  self.pinchGestureRecognizer = self.navigationView.pinchGestureRecognizer;
  self.doubleTapGestureRecognizer = self.navigationView.doubleTapGestureRecognizer;
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
  cv::Vec4b white(255, 255, 255, 255);
  cv::Vec4b gray(193, 193, 193, 255);
  unsigned int pixels = (unsigned int)self.pixelsPerCheckerboardSquare;
  cv::Mat4b checkerboardMat(pixels * 2, pixels * 2);
  checkerboardMat = white;
  checkerboardMat(cv::Rect(0, 0, pixels, pixels)) = gray;
  checkerboardMat(cv::Rect(pixels, pixels, pixels, pixels)) = gray;
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
  self.pixelGrid.maxZoomScale = self.maxZoomScale;
}

- (void)registerNotifications {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kSetNeedsDisplayNotification
                                                object:self];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(glkSetNeedsDisplayNotification:)
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
  self.navigationView = nil;
  self.glkView = nil;
  self.context = nil;
}

- (void)dealloc {
  [self teardown];
}

#pragma mark -
#pragma mark Views
#pragma mark -

- (void)setGlkView:(GLKView *)glkView {
  [_glkView removeFromSuperview];
  _glkView = glkView;
}

- (void)setNavigationView:(LTViewNavigationView *)navigationView {
  [_navigationView removeFromSuperview];
  _navigationView = navigationView;
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
  self.navigationView.contentSize = self.contentTexture.size;
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

- (void)navigationGestureRecognizersDidChangeFrom:(NSArray __unused *)oldRecognizers
                                               to:(NSArray __unused *)newRecognizers {
  [self updateNavigationGestureRecognizers];
}

#pragma mark -
#pragma mark GLKViewDelegate
#pragma mark -

- (void)glkView:(GLKView __unused *)view drawInRect:(CGRect __unused)rect {
  [self informAboutFramebufferChangesIfRequired];

  [LTGLContext setCurrentContext:self.context];
  [self.context executeAndPreserveState:^(LTGLContext *context) {
    context.renderingToScreen = YES;
    [self drawToBoundFramebuffer];
  }];
  
  // We don't need the GLKView buffers for the next draw, so hint that they can be discarded.
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
  [self.navigationView cancelBogusScrollviewPanGesture];

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

- (void)setNavigationMode:(LTViewNavigationMode)navigationMode {
  if (self.isNavigationModeLocked) {
    return;
  }

  self.isNavigationModeLocked = YES;
  _navigationMode = navigationMode;
  self.navigationView.mode = navigationMode;
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

- (void)forceGLKViewFramebufferAllocation {
  // TODO:(amit) see if this is necessary after switching to Xcode 6.
  [self.glkView bindDrawable];
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawToBoundFramebuffer {
  [self updateContent];
  
  [self.context clearWithColor:self.backgroundColor.lt_ltVector];
  [self drawBackground];
  
  // Get the visible content rectangle, in pixels.
  CGRect visibleContentRect = self.navigationView.visibleContentRect;
  visibleContentRect.origin = visibleContentRect.origin * self.contentScaleFactor;
  visibleContentRect.size = visibleContentRect.size * self.contentScaleFactor;
  
  // Draw the shadows surrounding the visible content rect.
  [self drawShadows];
  
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

- (void)drawBackground {
  // TODO:(amit) implement once the background mechanism is determined.
}

- (void)drawShadows {
  // TODO:(amit) implement once the shadows mechanism is determined.
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
      [self textureInterpolationForZoomScale:self.navigationView.zoomScale];
  [textureToDraw executeAndPreserveParameters:^{
    textureToDraw.magFilterInterpolation =
        [self textureInterpolationForZoomScale:self.navigationView.zoomScale];
    
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
  
  UIEdgeInsets insets = self.navigationView.contentInset * self.contentScaleFactor;
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
  return CGSizeMake(self.glkView.drawableWidth, self.glkView.drawableHeight);
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
#pragma mark Rotation
#pragma mark -

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
  [self.navigationView willRotateToInterfaceOrientation:orientation];
  
  if (!self.contentTexture) {
    return;
  }
  
  // TODO:(amit)implement when the appearance is defined.
  [self bringSubviewToFront:self.navigationView];
  self.glkView.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation {
  [self.navigationView didRotateFromInterfaceOrientation:orientation];
  
  self.glkView.hidden = NO;
  self.navigationView.hidden = YES;
  [self sendSubviewToBack:self.navigationView];
}

#pragma mark -
#pragma mark Display updates for the GLKView and the content
#pragma mark -

- (void)setNeedsDisplayContentInRect:(CGRect)rect {
  // Clip the rectangle with the content bounds.
  rect = CGRectIntersection(rect, self.contentBounds);
  self.contentRectToUpdate = CGRectUnion(self.contentRectToUpdate, rect);
  [self glkSetNeedsDisplay];
}

- (void)setNeedsDisplayContent {
  self.contentRectToUpdate = self.contentBounds;
  [self glkSetNeedsDisplay];
}

- (void)setNeedsDisplayInRect:(CGRect __unused)rect {
  [self glkSetNeedsDisplay];
}

- (void)setNeedsDisplay {
  [self glkSetNeedsDisplay];
}

- (void)glkSetNeedsDisplay {
  // In case any display link based animation is active, calling the glkView's setNeedsDisplay
  // method might cause lags. Calling it from a different runloop using a notification, appears to
  // to solve the issue.
  if ([LTAnimation isAnyAnimationRunning]) {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:kSetNeedsDisplayNotification object:self];
  } else {
    [self.glkView setNeedsDisplay];
  }
}

- (void)glkSetNeedsDisplayNotification:(NSNotification __unused *)notification {
  [self.glkView setNeedsDisplay];
}

#pragma mark -
#pragma mark Snapshots
#pragma mark -

- (LTImage *)snapshotView {
  // TODO: (yaron) this can be optimized by creating an LTMMTexture which is backed by a cv::Mat,
  // so there will be no need to create two duplicate images in memory (one of a texture and one of
  // LTImage).
  LTTexture *texture = [LTTexture byteRGBATextureWithSize:self.framebufferSize];
  LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:texture];
  [fbo bindAndDraw:^{
    [self drawToBoundFramebuffer];
  }];
  return [[LTImage alloc] initWithMat:[texture image] copy:NO];
}

#pragma mark -
#pragma mark Navigation Gesture Recognizers
#pragma mark -

- (void)setPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
  if (panGestureRecognizer == _panGestureRecognizer) {
    return;
  }

  if (_panGestureRecognizer) {
    [self.glkView removeGestureRecognizer:_panGestureRecognizer];
  }
  _panGestureRecognizer = panGestureRecognizer;
  if (_panGestureRecognizer) {
    [self.glkView addGestureRecognizer:_panGestureRecognizer];
  }
}

- (void)setPinchGestureRecognizer:(UIPinchGestureRecognizer *)pinchGestureRecognizer {
  if (pinchGestureRecognizer == _pinchGestureRecognizer) {
    return;
  }

  if (_pinchGestureRecognizer) {
    [self.glkView removeGestureRecognizer:_pinchGestureRecognizer];
  }
  _pinchGestureRecognizer = pinchGestureRecognizer;
  if (_pinchGestureRecognizer) {
    [self.glkView addGestureRecognizer:_pinchGestureRecognizer];
  }
}

- (void)setDoubleTapGestureRecognizer:(UITapGestureRecognizer *)doubleTapGestureRecognizer {
  if (doubleTapGestureRecognizer == _doubleTapGestureRecognizer) {
    return;
  }

  if (_doubleTapGestureRecognizer) {
    [self.glkView removeGestureRecognizer:_doubleTapGestureRecognizer];
  }
  _doubleTapGestureRecognizer = doubleTapGestureRecognizer;
  if (_doubleTapGestureRecognizer) {
    [self.glkView addGestureRecognizer:_doubleTapGestureRecognizer];
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGFloat)contentScaleFactor {
  return [UIScreen mainScreen].nativeScale;
}

- (void)setContentScaleFactor:(CGFloat __unused)contentScaleFactor {
  [super setContentScaleFactor:[UIScreen mainScreen].nativeScale];
}

- (void)setMaxZoomScale:(CGFloat)maxZoomScale {
  _maxZoomScale = MAX(0, maxZoomScale);
  self.pixelGrid.maxZoomScale = maxZoomScale;
  self.navigationView.maxZoomScale = maxZoomScale;
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

#pragma mark -
#pragma mark NavigationView Passthrough Properties
#pragma mark -

- (void)setContentInset:(UIEdgeInsets)contentInset {
  _contentInset = contentInset;
  self.navigationView.contentInset = contentInset;
}

- (void)setMinZoomScaleFactor:(CGFloat)minZoomScaleFactor {
  _minZoomScaleFactor = minZoomScaleFactor;
  self.navigationView.minZoomScaleFactor = minZoomScaleFactor;
}

- (void)setDoubleTapLevels:(NSUInteger)doubleTapLevels {
  _doubleTapLevels = doubleTapLevels;
  self.navigationView.doubleTapLevels = doubleTapLevels;
}

- (void)setDoubleTapZoomFactor:(CGFloat)doubleTapZoomFactor {
  _doubleTapZoomFactor = doubleTapZoomFactor;
  self.navigationView.doubleTapZoomFactor = doubleTapZoomFactor;
}

- (LTViewNavigationState *)navigationState {
  return self.navigationView.state;
}

- (void)navigateToStateOfView:(LTView *)view {
  if (view.bounds.size == self.bounds.size && view.contentSize == self.contentSize) {
    [self.navigationView navigateToState:view.navigationState];
  }
}

- (CGRect)visibleContentRect {
  CGRect visibleContentRect = self.navigationView.visibleContentRect;
  visibleContentRect.origin = visibleContentRect.origin * self.contentScaleFactor;
  visibleContentRect.size = visibleContentRect.size * self.contentScaleFactor;
  return visibleContentRect;
}

- (CGFloat)zoomScale {
  return self.navigationView.zoomScale;
}

- (UIView *)viewForContentCoordinates {
  return self.navigationView.viewForContentCoordinates;
}

@end
