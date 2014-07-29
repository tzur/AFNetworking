// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

#import "LTCGExtensions.h"
#import "LTGLContext.h"

@interface LTFbo ()

/// Framebuffer identifier.
@property (nonatomic) GLuint framebuffer;

/// Framebuffer size.
@property (nonatomic) CGSize size;

/// Viewport to use when binding the framebuffer.
@property (nonatomic) CGRect viewport;

/// Set to the previously bound framebuffer, or \c 0 if the framebuffer is not bound.
@property (nonatomic) GLint previousFramebuffer;

/// Viewport to restore when the current framebuffer unbinds.
@property (nonatomic) CGRect previousViewport;

/// YES if the program is currently bound.
@property (nonatomic) BOOL bound;

@end

@implementation LTFbo

#pragma mark -
#pragma mark Initialization and Setup
#pragma mark -

- (instancetype)initWithFramebufferIdentifier:(GLuint)identifier size:(CGSize)size
                                     viewport:(CGRect)viewport {
  LTParameterAssert(std::min(size) >= 1);
  LTParameterAssert(!CGRectIsNull(viewport) && !CGRectIsEmpty(viewport));
  if (self = [super init]) {
    self.size = size;
    self.viewport = viewport;
    self.framebuffer = identifier;
    self.previousViewport = CGRectNull;
  }
  return self;
}

#pragma mark -
#pragma mark Binding
#pragma mark -

- (void)bind {
  if (self.bound) {
    return;
  }
  
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_previousFramebuffer);
  GLint viewport[4];
  glGetIntegerv(GL_VIEWPORT, viewport);
  self.previousViewport = CGRectMake(viewport[0], viewport[1], viewport[2], viewport[3]);

  glBindFramebuffer(GL_FRAMEBUFFER, self.framebuffer);
  glViewport(self.viewport.origin.x, self.viewport.origin.y,
             self.viewport.size.width, self.viewport.size.height);
  self.bound = YES;
}

- (void)unbind {
  if (!self.bound) {
    return;
  }

  glBindFramebuffer(GL_FRAMEBUFFER, self.previousFramebuffer);
  if (!CGRectIsNull(self.previousViewport)) {
    glViewport(self.previousViewport.origin.x, self.previousViewport.origin.y,
               self.previousViewport.size.width, self.previousViewport.size.height);
  }

  self.previousFramebuffer = 0;
  self.previousViewport = CGRectNull;
  self.bound = NO;
}

- (void)bindAndExecute:(LTVoidBlock)block {
  LTParameterAssert(block);
  if (self.bound) {
    block();
  } else {
    [self bind];
    block();
    [self unbind];
  }
}

- (void)bindAndDraw:(LTVoidBlock)block {
  [self bindAndExecute:block];
}

#pragma mark -
#pragma mark Operations
#pragma mark -

- (void)clearWithColor:(GLKVector4)color {
  [self bindAndDraw:^{
    [[LTGLContext currentContext] clearWithColor:color];
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (GLuint)name {
  return self.framebuffer;
}

@end
