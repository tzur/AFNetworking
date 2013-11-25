// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

@interface LTFbo ()

// Texture assocaited with the fbo.
@property (strong, nonatomic) LTTexture *texture;
// Framebuffer identifier.
@property (nonatomic) GLuint framebuffer;
// Framebuffer to bind when the fbo unbinds.
@property (nonatomic) GLint framebufferToRebind;
// Viewport to restore when the fbo unbinds.
@property (nonatomic) CGRect viewportToRestore;
// Is currently bound. Used to enforce proper bind->unbind calls.
@property (nonatomic) BOOL currentlyBound;

@end

@implementation LTFbo

static const GLint NO_FRAMEBUFFER = -1;

#pragma mark -
#pragma mark Initialization and Setup
#pragma mark -

- (id)initWithTexture:(LTTexture *)texture {
  if (self = [super init]) {
    // Set the default properties, and try to setup the framebuffer. Return nil in case the
    // framebuffer setup failed.
    self.framebufferToRebind = NO_FRAMEBUFFER;
    self.viewportToRestore = CGRectNull;
    self.texture = texture;
    if (![self setupFramebuffer]) {
      return nil;
    }
  }
  return self;
}

- (void)dealloc {
  
}

- (BOOL)setupFramebuffer {
  return NO;
}

#pragma mark -
#pragma mark Bind/Unbind
#pragma mark -

- (void)bind {
  [self bind:YES];
}

- (void)bind:(BOOL)saveCurrentState {
  NSAssert(!self.currentlyBound, @"Tried to bind fbo while it is already bound");
  
  // Store the previous framebuffer and viewport, if necessary.
  if (saveCurrentState) {
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_framebufferToRebind);
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    self.viewportToRestore = CGRectMake(viewport[0], viewport[1], viewport[2], viewport[3]);
  }
  
  // Bind to offscreen framebuffer and set the viewport according to its size.
  glBindFramebuffer(GL_FRAMEBUFFER, self.framebuffer);
  glViewport(0, 0, self.texture.size.width, self.texture.size.height);
  self.currentlyBound = YES;
}

- (void)unbind {
  [self unbindToAnotherFbo:nil];
}

- (void)unbindToAnotherFbo:(LTFbo *)fbo {
  NSAssert(self.currentlyBound, @"Tried to unbind fbo while it is not currently bound");
  
  // If another fbo is given, bind to it instead of unbinding, but configure its previous
  // framebuffer and viewport so it'll bind to the current fbo's previous framebuffer and restore
  // its previous viewport when it unbinds.
  if (fbo) {
    fbo.framebufferToRebind = self.framebufferToRebind;
    fbo.viewportToRestore = self.viewportToRestore;
    [fbo bind:NO];
  } else {
    // Otherwise, Bind to the saved framebuffer, and restore the saved viewport.
    if (self.framebufferToRebind != NO_FRAMEBUFFER) {
      glBindFramebuffer(GL_FRAMEBUFFER, self.framebufferToRebind);
    }
    if (!CGRectIsNull(self.viewportToRestore)) {
      glViewport(self.viewportToRestore.origin.x, self.viewportToRestore.origin.y,
                 self.viewportToRestore.size.width, self.viewportToRestore.size.height);
    }
  }
  
  self.currentlyBound = false;
  self.framebufferToRebind = NO_FRAMEBUFFER;
  self.viewportToRestore = CGRectNull;
}

#pragma mark -
#pragma mark Utility
#pragma mark -

#pragma mark -
#pragma mark Properties
#pragma mark -

- (GLuint)name {
  return self.texture.name;
}

- (CGSize)size {
  return self.texture.size;
}


@end
