// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTScreenFbo.h"

#import "LTGLException.h"

@implementation LTScreenFbo

- (instancetype)initWithSize:(CGSize)size {
  GLint framebuffer;
  GLint viewport[4];
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &framebuffer);
  glGetIntegerv(GL_VIEWPORT, viewport);
  [self validateFramebuffer:framebuffer];
  return [super initWithFramebufferIdentifier:framebuffer size:size
          viewport:CGRectMake(viewport[0], viewport[1], viewport[2], viewport[3])];
}

- (void)validateFramebuffer:(GLint)framebuffer {
  GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  if (status != GL_FRAMEBUFFER_COMPLETE) {
    [LTGLException raise:kLTFboCreationFailedException format:@"Screen framebuffer incomplete "
     "(status: 0x%x, framebuffer: %d)", status, framebuffer];
  }
}

@end
