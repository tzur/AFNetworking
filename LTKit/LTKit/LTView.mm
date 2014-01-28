// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTView.h"

#import "LTAnimation.h"
#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTImage.h"
#import "LTProgram.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTexture+Factory.h"
#import "LTViewNavigationView.h"
#import "LTViewPixelGrid.h"
#import "UIColor+Vector.h"

@interface LTView () <GLKViewDelegate, LTViewNavigationViewDelegate>

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

/// Texture used for visualizing the transparent content pixels.
@property (strong, nonatomic) LTTexture *checkerboardTexture;

/// Texture used for displaying the content of the LTView.
@property (strong, nonatomic) LTTexture *contentTexture;

/// Fbo used for updating the LTView's content texture.
@property (strong, nonatomic) LTFbo *contentFbo;

/// RectDrawer used for drawing the content texture on the GLKView.
@property (strong, nonatomic) LTRectDrawer *rectDrawer;

/// RectDrawer used for drawing the checkerboard background.
@property (strong, nonatomic) LTRectDrawer *checkerboardDrawer;

/// Manages the pixel grid drawn on the LTView on certain zoom levels.
@property (strong, nonatomic) LTViewPixelGrid *pixelGrid;

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

- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setDefaults];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self setDefaults];
  }
  return self;
}

- (void)setDefaults {
  self.maxZoomScale = kDefaultMaxZoomScale;
  self.doubleTapLevels = kDefaultDoubleTapLevels;
  self.doubleTapZoomFactor = kDefaultDoubleTapZoomFactor;
  self.pixelsPerCheckerboardSquare = kDefaultPixelsPerCheckerboardSquare * self.contentScaleFactor;
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
  [self createCheckerboard];
  [self createPixelGrid];
  [self registerNotifications];
  [self setNeedsDisplay];
}

- (void)createGlkView {
  LTAssert(self.context, @"Could not set up GLKView when LTGLContext is nil");
  
  // Remove previous subview, if allocated, and gesture recognizers assigned to it.
  [self.glkView removeFromSuperview];
  self.glkView.gestureRecognizers = @[];
  
  // Allocate the glkView and set it up.
  self.glkView = [[GLKView alloc] initWithFrame:self.bounds];
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
  [self.navigationView removeFromSuperview];
  self.navigationView = [[LTViewNavigationView alloc] initWithFrame:self.bounds
                                                        contentSize:self.contentTexture.size
                                                              state:state];
  self.navigationView.delegate = self;
  self.navigationView.contentInset = self.contentInset;
  self.navigationView.maxZoomScale = self.maxZoomScale;
  self.navigationView.doubleTapLevels = self.doubleTapLevels;
  self.navigationView.doubleTapZoomFactor = self.doubleTapZoomFactor;
  
  self.navigationView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  [self insertSubview:self.navigationView belowSubview:self.glkView];
  for (UIGestureRecognizer *recognizer in self.navigationView.navigationGestureRecognizers) {
    [self.glkView addGestureRecognizer:recognizer];
  }
}

- (void)createContentFbo {
  self.contentFbo = [[LTFbo alloc] initWithTexture:self.contentTexture];
}

- (void)createRectDrawer {
  self.rectDrawer = [[LTRectDrawer alloc] initWithSourceTexture:self.contentTexture];
}

- (void)createCheckerboard {
  cv::Vec4b white(255, 255, 255, 255);
  cv::Vec4b gray(193, 193, 193, 255);
  unsigned int pixels = (unsigned int)self.pixelsPerCheckerboardSquare;
  cv::Mat4b checkerboardMat(pixels * 2, pixels * 2);
  checkerboardMat = white;
  checkerboardMat(cv::Rect(0, 0, pixels, pixels)) = gray;
  checkerboardMat(cv::Rect(pixels, pixels, pixels, pixels)) = gray;

  self.checkerboardTexture = [LTTexture textureWithImage:checkerboardMat];
  self.checkerboardTexture.minFilterInterpolation = LTTextureInterpolationNearest;
  self.checkerboardTexture.magFilterInterpolation = LTTextureInterpolationNearest;
  self.checkerboardTexture.wrap = LTTextureWrapRepeat;
  self.checkerboardDrawer = [[LTRectDrawer alloc] initWithSourceTexture:self.checkerboardTexture];
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
  self.checkerboardDrawer = nil;
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
#pragma mark Content Texture
#pragma mark -

- (void)replaceContentWith:(LTTexture *)texture {
  LTParameterAssert(texture);
  self.contentTexture = texture;
  [self createContentFbo];
  [self createRectDrawer];
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

- (void)didNavigateToRect:(CGRect __unused)visibleRect {
  [self setNeedsDisplay];
}

#pragma mark -
#pragma mark GLKViewDelegate
#pragma mark -

- (void)glkView:(GLKView __unused *)view drawInRect:(CGRect __unused)rect {
  [LTGLContext setCurrentContext:self.context];
  
  [self updateContent];

  [self.context clearWithColor:self.backgroundColor.glkVector];
  [self drawBackground];
  
  // Get the visible content rectangle, in pixels.
  CGRect visibleContentRect = self.navigationView.visibleContentRect;
  visibleContentRect.origin = visibleContentRect.origin * self.contentScaleFactor;
  visibleContentRect.size = visibleContentRect.size * self.contentScaleFactor;

  // Draw the shadows surrounding the visible content rect.
  [self drawShadows];
  
  [self.context executeAndPreserveState:^{
    // Set the scissor box to draw only inside the visible content rect.
    self.context.scissorTestEnabled = YES;
    self.context.scissorBox = [self scissorBoxForVisibleContentRect:visibleContentRect];;

    // Draw the content.
    [self drawContentForVisibleContentRect:visibleContentRect];
    
    // Draw the overlays.
    [self drawOverlayForVisibleContentRect:visibleContentRect];
    
    // Draw the checkerboard background to visualize transparent content pixels.
    [self drawTransparencyBackground];
  }];
  
  // We don't need the GLKView buffers for the next draw, so hint that they can be discarded.
  // (Since we clear the buffers at the beginning of each draw cycle).
  const GLenum discards[] = {GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT};
  glDiscardFramebufferEXT(GL_FRAMEBUFFER, 2, discards);
}

#pragma mark -
#pragma mark Touch events
#pragma mark -

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  [super touchesBegan:touches withEvent:event];
  if (self.forwardTouchesToDelegate && [self shouldForwardTouchEventsOnCurrentNavigationMode]) {
    if ([self.touchDelegate respondsToSelector:@selector(ltView:touchesBegan:withEvent:)]) {
      [self.touchDelegate ltView:self touchesBegan:touches withEvent:event];
    }
  }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  if (self.forwardTouchesToDelegate && [self shouldForwardTouchEventsOnCurrentNavigationMode]) {
    if ([self.touchDelegate respondsToSelector:@selector(ltView:touchesMoved:withEvent:)]) {
      [self.touchDelegate ltView:self touchesMoved:touches withEvent:event];
    }
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  if (self.forwardTouchesToDelegate && [self shouldForwardTouchEventsOnCurrentNavigationMode]) {
    if ([self.touchDelegate respondsToSelector:@selector(ltView:touchesEnded:withEvent:)]) {
      [self.touchDelegate ltView:self touchesEnded:touches withEvent:event];
    }
  }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesCancelled:touches withEvent:event];
  if (self.forwardTouchesToDelegate && [self shouldForwardTouchEventsOnCurrentNavigationMode]) {
    if ([self.touchDelegate respondsToSelector:@selector(ltView:touchesCancelled:withEvent:)]) {
      [self.touchDelegate ltView:self touchesCancelled:touches withEvent:event];
    }
  }
}

- (BOOL)shouldForwardTouchEventsOnCurrentNavigationMode {
  return self.navigationMode == LTViewNavigationNone ||
         self.navigationMode == LTViewNavigationTwoFingers;
}

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

- (void)drawToFbo:(LTFbo *)fbo {
  [fbo bindAndExecute:^{
    [self glkView:nil drawInRect:self.bounds];
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
  
  [self.context executeAndPreserveState:^{
    self.context.blendEnabled = YES;
    self.context.blendFunc = kLTGLContextBlendFuncChecker;
    self.context.blendEquation = kLTGLContextBlendEquationDefault;
    
    [self.checkerboardDrawer drawRect:self.framebufferBounds
          inScreenFramebufferWithSize:self.framebufferSize fromRect:self.framebufferBounds];
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
    
    [self.context executeAndPreserveState:^{
      // If the draw delegate supports the drawProcessedContent mechanism, use it to draw.
      BOOL didDrawProcessedContent = NO;
      if ([self.drawDelegate respondsToSelector:@selector(ltView:drawProcessedContent:
                                                          withVisibleContentRect:
                                                          onScreenFramebuffer:)]) {
        didDrawProcessedContent = [self.drawDelegate ltView:self drawProcessedContent:textureToDraw
                                     withVisibleContentRect:visibleContentRect
                                        onScreenFramebuffer:YES];
      }
      
      // Otherwise, use the default rectDrawer to draw the content.
      if (!didDrawProcessedContent && textureToDraw) {
        [self.rectDrawer setSourceTexture:textureToDraw];
        [self.rectDrawer drawRect:self.framebufferBounds
      inScreenFramebufferWithSize:self.framebufferSize
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
  return self.glkView.bounds.size * self.glkView.contentScaleFactor;
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
  LTTexture *texture = [LTTexture textureWithSize:self.framebufferSize
                                        precision:LTTexturePrecisionByte
                                         channels:LTTextureChannelsRGBA
                                   allocateMemory:YES];
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
  [self drawToFbo:fbo];
  return [[LTImage alloc] initWithMat:[texture image] copy:NO];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGFloat)contentScaleFactor {
  return [UIScreen mainScreen].scale;
}

- (void)setContentScaleFactor:(CGFloat __unused)contentScaleFactor {
  [super setContentScaleFactor:[UIScreen mainScreen].scale];
}

- (void)setMaxZoomScale:(CGFloat)maxZoomScale {
  _maxZoomScale = MAX(0, maxZoomScale);
  self.pixelGrid.maxZoomScale = maxZoomScale;
  self.navigationView.maxZoomScale = maxZoomScale;
}

#pragma mark -
#pragma mark NavigationView Passthrough Properties
#pragma mark -

- (void)setContentInset:(UIEdgeInsets)contentInset {
  _contentInset = contentInset;
  self.navigationView.contentInset = contentInset;
}

- (void)setNavigationMode:(LTViewNavigationMode)navigationMode {
  _navigationMode = navigationMode;
  self.navigationView.mode = navigationMode;
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

- (CGRect)visibleContentRect {
  CGRect visibleContentRect = self.navigationView.visibleContentRect;
  visibleContentRect.origin = visibleContentRect.origin * self.contentScaleFactor;
  visibleContentRect.size = visibleContentRect.size * self.contentScaleFactor;
  return visibleContentRect;
}

@end
