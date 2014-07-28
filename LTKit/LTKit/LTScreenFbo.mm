// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTScreenFbo.h"

@implementation LTScreenFbo

- (instancetype)initWithSize:(CGSize)size {
  GLint framebuffer;
  GLint viewport[4];
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &framebuffer);
  glGetIntegerv(GL_VIEWPORT, viewport);
  return [super initWithFramebufferIdentifier:framebuffer size:size
          viewport:CGRectMake(viewport[0], viewport[1], viewport[2], viewport[3])];
}

@end
