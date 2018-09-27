// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPresentationView.h"

#import <LTKit/LTAnimation.h>

#import "LTContentLocationProvider.h"
#import "LTEAGLView.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTGridDrawingManager.h"
#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTPresentationViewDrawDelegate.h"
#import "LTPresentationViewFramebufferDelegate.h"
#import "LTProgram.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTexture+Factory.h"
#import "UIColor+Vector.h"

@interface LTPresentationView () <LTEAGLViewDelegate>

/// Provider of information about the content rectangle.
@property (strong, nonatomic) id<LTContentLocationProvider> contentLocationProvider;

/// Default content scale factor to be used by this view.
@property (nonatomic, readonly) CGFloat defaultContentScaleFactor;

/// OpenGL context to use while drawing on the view.
@property (strong, nonatomic) LTGLContext *context;

/// Internal presentation view. The content created by the internal render pipeline will be
/// presented by this view.
@property (strong, nonatomic) LTEAGLView *eaglView;

/// Holds the rectangle that needs to be updated in the next draw.
@property (nonatomic) CGRect contentRectToUpdate;

/// Dimensions of the squares in the checkerboard used to visualize transparency.
@property (nonatomic) NSUInteger pixelsPerCheckerboardSquare;

/// Texture used for visualizing the transparent pixels when \c checkerboardPattern is \c YES.
@property (strong, nonatomic) LTTexture *checkerboardTexture;

/// Texture used for visualizing the transparent pixels when checkerboardPattern is \c NO.
@property (strong, nonatomic) LTTexture *backgroundTexture;

/// Texture used for storing the content created by the internal render pipeline of this instance.
@property (strong, nonatomic) LTTexture *contentTexture;

/// Fbo to the content texture of this instance.
@property (strong, nonatomic) LTFbo *contentFbo;

/// Rect drawer used for drawing the content texture on the \c LTEAGLView.
@property (strong, nonatomic) LTRectDrawer *rectDrawer;

/// Rect drawer used for drawing the checkerboard background.
@property (strong, nonatomic) LTRectDrawer *backgroundDrawer;

/// Object managing the pixel grid drawn at certain zoom levels.
@property (strong, nonatomic) LTGridDrawingManager *pixelGrid;

/// Size of the framebuffer, in pixels, before the next redrawing of the underlying
/// \c LTEAGLView.
@property (nonatomic) CGSize previousFramebufferSize;

/// While set to \c YES, the \c navigationMode property will not be updated.
@property (nonatomic) BOOL isNavigationModeLocked;

/// While set to \c YES, the \c forwardTouchesToDelegate property will not be updated.
@property (nonatomic) BOOL isForwardTouchesToDelegateLocked;

/// \c CGRect used upon the most recent initialization of the internal \c eaglView. Is stored in
/// order to refrain from unnecessarily recreating the \c eaglView upon calls to \c layoutSubviews.
@property (nonatomic) CGRect mostRecentlyUsedEaglViewFrame;

@end

@implementation LTPresentationView

/// Name of the notification indicating a setNeedsDisplay is needed.
static NSString * const kSetNeedsDisplayNotification = @"LTViewSetNeedsDisplay";

/// Minimum zoom scale at which nearest neighbor interpolation will be used to present the output of
/// the internal render pipeline.
static const CGFloat kMinimalZoomScaleForNNInterpolation = 3;

/// Number of pixels per checkerboard square, must be a power of two.
static const NSUInteger kDefaultPixelsPerCheckerboardSquare = 8;

- (instancetype)initWithFrame:(CGRect)frame context:(LTGLContext *)context
               contentTexture:(LTTexture *)contentTexture
      contentLocationProvider:(id<LTContentLocationProvider>)contentLocationProvider {
  LTParameterAssert(contentTexture.size == contentLocationProvider.contentSize,
                    @"Size of content texture must match content size provided by content location "
                    "manager");

  if (self = [super initWithFrame:frame]) {
    _defaultContentScaleFactor = contentLocationProvider.contentScaleFactor;
    [super setContentScaleFactor:self.defaultContentScaleFactor];
    self.pixelsPerCheckerboardSquare = kDefaultPixelsPerCheckerboardSquare * 2;
    [self setupWithContext:context
            contentTexture:contentTexture
    contentLocationProvider:contentLocationProvider];
    self.backgroundColor = [self defaultBackgroundColor];
  }
  return self;
}

- (void)setupWithContext:(LTGLContext *)context contentTexture:(LTTexture *)texture
 contentLocationProvider:(id<LTContentLocationProvider>)contentLocationProvider {
  LTParameterAssert(context);
  LTParameterAssert(texture);

  self.context = context;
  self.contentTexture = texture;
  self.contentRectToUpdate = CGRectNull;
  self.contentLocationProvider = contentLocationProvider;
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
  self.pixelGrid = [[LTGridDrawingManager alloc] initWithContentSize:self.contentSize];
  self.pixelGrid.maxZoomScale = self.contentLocationProvider.maxZoomScale;
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

  // Due to an obscure bug occurring on the iPad Pro leading to freezing of the application upon
  // device rotations, the internally used \c LTEAGLView must be recreated upon layout change
  // requests.
  [self createEaglView];
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
  [self setNeedsDisplay];
}

#pragma mark -
#pragma mark LTEAGLViewDelegate
#pragma mark -

- (void)eaglView:(LTEAGLView __unused *)eaglView drawInRect:(__unused CGRect)rect {
#if defined(DEBUG) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
  // Under iOS 10, the view hierarchy debugger does not bind an OpenGL framebuffer before calling
  // the drawLayer:inContext: method of UIView (implementing the CALayerDelegate protocol). Hence,
  // subsequent OpenGL render calls lead to an OpenGL error. Therefore, no rendering is performed in
  // the following lines if no framebuffer is bound.
  GLint currentlyBoundFramebuffer = 0;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &currentlyBoundFramebuffer);
  if (!currentlyBoundFramebuffer) {
    return;
  }
#endif

  [self informAboutFramebufferChangesIfRequired];

  [self.context executeAndPreserveState:^(LTGLContext *context) {
    context.renderingToScreen = YES;
    [self drawToBoundFramebuffer];
  }];

  // We don't need the \c LTEAGLView buffers for the next draw, so hint that they can be discarded.
  // (Since we clear the buffers at the beginning of each draw cycle).
  const std::array<GLenum, 2> discards{{GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT}};
  glInvalidateFramebuffer(GL_FRAMEBUFFER, discards.size(), discards.data());
}

- (void)informAboutFramebufferChangesIfRequired {
  CGSize currentFramebufferSize = self.framebufferSize;
  if (currentFramebufferSize != self.previousFramebufferSize) {
    self.previousFramebufferSize = currentFramebufferSize;
    if ([self.framebufferDelegate
         respondsToSelector:@selector(presentationView:framebufferChangedToSize:)]) {
      [self.framebufferDelegate presentationView:self
                        framebufferChangedToSize:currentFramebufferSize];
    }
  }
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)drawToBoundFramebuffer {
  if ([self.drawDelegate respondsToSelector:@selector(drawContentForPresentationView:)] &&
      [self.drawDelegate drawContentForPresentationView:self]) {
    return;
  }

  [self updateContent];

  [self.context clearColor:self.backgroundColor.lt_ltVector];

  // Get the visible content rectangle, in floating-point pixel units of the content coordinate
  // system.
  CGRect visibleContentRect = self.contentLocationProvider.visibleContentRect;

  // Draw the background and anything that should be drawn below the content.
  [self drawBackgroundForVisibleContentRect:visibleContentRect];

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
      if ([self.drawDelegate respondsToSelector:@selector(presentationView:updateContentInRect:)]) {
        [self.drawDelegate presentationView:self updateContentInRect:self.contentRectToUpdate];
      }
    }];

    // Reset the rectToDraw.
    self.contentRectToUpdate = CGRectNull;
  }
}

- (void)drawBackgroundForVisibleContentRect:(CGRect)visibleContentRect {
  if (![self.drawDelegate respondsToSelector:@selector(presentationView:
                                                       drawBackgroundBelowContentAroundRect:)]) {
    return;
  }

  CGAffineTransform transform = [self transformForVisibleContentRect:visibleContentRect];
  CGRect rect = CGRectApplyAffineTransform(CGRectFromSize(self.contentTextureSize), transform);
  [self.drawDelegate presentationView:self drawBackgroundBelowContentAroundRect:rect];
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
  if ([self.drawDelegate respondsToSelector:@selector(alternativeTextureForView:)]) {
    textureToDraw = [self.drawDelegate alternativeTextureForView:self] ?: textureToDraw;
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
      if ([self.drawDelegate respondsToSelector:@selector(presentationView:drawProcessedContent:
                                                          withVisibleContentRect:)]) {
        didDrawProcessedContent = [self.drawDelegate presentationView:self
                                                 drawProcessedContent:textureToDraw
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
          respondsToSelector:@selector(presentationView:drawOverlayAboveContentWithTransform:)]) {
    CGAffineTransform transform = [self transformForVisibleContentRect:visibleContentRect];
    [self.drawDelegate presentationView:self drawOverlayAboveContentWithTransform:transform];
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
  // Transform the visible content rect from floating-point pixel units of the content coordinate
  // system into point units of the presentation coordinate system.
  CGRect visibleBox = CGRectApplyAffineTransform(self.contentBounds,
                                                 [self transformForVisibleContentRect:rect]);

  UIEdgeInsets insets = self.contentLocationProvider.contentInset * self.contentScaleFactor;
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
  return CGRectFromSize(self.framebufferSize);
}

- (CGSize)contentSize {
  return self.contentTexture.size;
}

- (CGRect)contentBounds {
  return CGRectFromSize(self.contentSize);
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

@synthesize drawDelegate = _drawDelegate;
@synthesize framebufferDelegate = _framebufferDelegate;
@synthesize contentTransparency = _contentTransparency;
@synthesize checkerboardPattern = _checkerboardPattern;

- (void)setCheckerboardPattern:(BOOL)checkerboardPattern {
  _checkerboardPattern = checkerboardPattern;
  [self.backgroundDrawer setSourceTexture:self.textureForBackground];
}

@dynamic backgroundColor;

- (void)setBackgroundColor:(nullable UIColor *)backgroundColor {
  backgroundColor = [backgroundColor colorWithAlphaComponent:1] ?: [self defaultBackgroundColor];
  super.backgroundColor = backgroundColor;
  [self.backgroundTexture clearColor:[backgroundColor lt_ltVector]];
}

- (UIColor *)defaultBackgroundColor {
  return [UIColor blackColor];
}

- (CGSize)contentTextureSize {
  return self.contentTexture.size;
}

- (CGFloat)zoomScale {
  return self.contentLocationProvider.zoomScale;
}

@end
