// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEAGLView.h"

#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLContext.h"
#import "LTRenderbuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTEAGLView ()

/// Holds this view's layer backing store.
@property (strong, nonatomic, nullable) LTRenderbuffer *renderbuffer;

/// Framebuffer that points to the renderbuffer that holds the view storage.
@property (strong, nonatomic, nullable) LTFbo *framebuffer;

/// \c YES if drawing is currently disabled. No delegate draw calls will be made while this flag is
/// set.
@property (nonatomic) BOOL drawingDisabled;

/// Size of the underlying drawable buffer.
@property (readwrite, nonatomic) CGSize drawableSize;

@end

@implementation LTEAGLView

- (instancetype)initWithFrame:(CGRect)frame context:(LTGLContext *)context {
  if (self = [super initWithFrame:frame]) {
    _context = context;

    [self observeActivityNotifications];

    [super setContentScaleFactor:[UIScreen mainScreen].nativeScale];
    self.opaque = YES;
  }
  return self;
}

- (void)dealloc {
  [self unobserveActivityNotifications];
}

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

#pragma mark -
#pragma mark Notifications
#pragma mark -

- (void)observeActivityNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive)
                                               name:UIApplicationWillResignActiveNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
}

- (void)unobserveActivityNotifications {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willResignActive {
  self.drawingDisabled = YES;
}

- (void)didBecomeActive {
  if (self.drawingDisabled) {
    self.drawingDisabled = NO;
    [self setNeedsDisplay];
  }
}

#pragma mark -
#pragma mark Layer and view display
#pragma mark -

- (void)layoutSubviews {
  [super layoutSubviews];
  [self createRenderTargetIfNeeded];
  [self setNeedsDisplay];
}

- (void)displayLayer:(CALayer __unused *)layer {
  if (self.drawingDisabled) {
    return;
  }

  [LTGLContext setCurrentContext:self.context];
  [self.framebuffer bindAndDraw:^{
    [self drawRect:self.bounds];
  }];
  [self.renderbuffer present];
}

- (void)drawRect:(CGRect __unused)rect {
  [self.delegate eaglView:self drawInRect:self.bounds];
}

- (void)setNeedsDisplay {
  [super setNeedsDisplay];
  [self.layer setNeedsDisplay];
}

- (void)setNeedsDisplayInRect:(CGRect)rect {
  [super setNeedsDisplayInRect:rect];
  [self.layer setNeedsDisplayInRect:rect];
}

- (void)setOpaque:(BOOL)opaque {
  [super setOpaque:opaque];
  self.layer.opaque = opaque;
}

- (void)setContentScaleFactor:(CGFloat __unused)contentScaleFactor {
  // Changing the content scale factor after the view is set up causes the context to fail
  // allocating the backing storage for the layer. Therefore, the scale factor is set once in the
  // initializer and is not allowed to change.
}

#pragma mark -
#pragma mark Render target
#pragma mark -

- (void)createRenderTargetIfNeeded {
  CGSize newDrawableSize = std::floor(self.bounds.size * self.contentScaleFactor);
  if (self.drawableSize == newDrawableSize) {
    return;
  }

  [LTGLContext setCurrentContext:self.context];

  // Make sure the renderbuffer and the framebuffer are deallocated, otherwise
  // -[EAGLContext renderbufferStorage:fromDrawable:] will not create a storage for the
  // renderbuffer.
  [self destroyRenderTarget];

  if (newDrawableSize != CGSizeZero) {
    [self createRenderTarget];
  }
  self.drawableSize = self.renderbuffer.size;
}

- (void)destroyRenderTarget {
  self.renderbuffer = nil;
  self.framebuffer = nil;
}

- (void)createRenderTarget {
  self.renderbuffer = [[LTRenderbuffer alloc] initWithDrawable:(id<EAGLDrawable>)self.layer];
  self.framebuffer = [self.context.fboPool fboWithRenderbuffer:self.renderbuffer];
}

@end

NS_ASSUME_NONNULL_END
