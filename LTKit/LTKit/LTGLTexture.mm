// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "LTGLException.h"

@interface LTTexture ()

- (BOOL)inTextureRect:(CGRect)rect;

@property (readonly, nonatomic) int matType;

@end

@interface LTGLTexture ()

/// GL identifier of the texture.
@property (readwrite, nonatomic) GLuint name;

@end

@implementation LTGLTexture

@synthesize name = _name;

- (void)load:(const cv::Mat &)image {
  [self loadRect:CGRectMake(0, 0, image.cols, image.rows) fromImage:image];
}

- (void)create:(BOOL)allocateMemory {
  if (self.name) {
    return;
  }

  glGenTextures(1, &_name);
  LTGLCheck(@"Failed generating texture");

  [self bindAndExecute:^{
    [self setMinFilterInterpolation:self.minFilterInterpolation];
    [self setMagFilterInterpolation:self.magFilterInterpolation];
    [self setWrap:self.wrap];

    if (allocateMemory) {
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.size.width, self.size.height, 0, GL_RGBA,
                   self.precision, NULL);
    }
  }];

  LTGLCheck(@"Error applying texture parameters");
}

- (void)destroy {
  [self unbind];

  glDeleteTextures(1, &_name);
  _name = 0;
}

- (void)storeRect:(CGRect)rect toImage:(cv::Mat *)image {
  // Preconditions.
  LTAssert([self inTextureRect:rect],
           @"Rect for retrieving matrix from texture is out of bounds: (%g, %g, %g, %g)",
           rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

  image->create(rect.size.height, rect.size.width, self.matType);

  [self bindAndExecute:^{
    // TODO: (yaron) replace this with FBO class once we have it.

    // Create a framebuffer and attach it to the texture. This is the only way to read texture using
    // glReadPixels.
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    LTGLCheck(@"Error while creating framebuffer");

    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self.name, 0);
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
      LogError(@"Failed to make complete framebuffer object, reason: %x, glError: %d",
               status, glGetError());
      return;
    }

    // Read pixels into the mutable data, according to the texture precision.
    glReadPixels(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, GL_RGBA,
                 self.precision, image->data);

    // Destroy framebuffer.
    glDeleteFramebuffers(1, &framebuffer);
  }];
}

- (void)loadRect:(CGRect)rect fromImage:(const cv::Mat &)image {
  // Preconditions.
  LTAssert([self inTextureRect:rect],
           @"Rect for retrieving image from texture is out of bounds: (%g, %g, %g, %g)",
           rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
  LTAssert(image.cols == rect.size.width && image.rows == rect.size.height,
           @"Trying to load to rect with size (%g, %g) from a Mat with different size: (%d, %d)",
           rect.size.width, rect.size.height, image.cols, image.rows);

  [self bindAndExecute:^{
    // If the rect occupies the entire image, use glTexImage2D, otherwise use glTexSubImage2D.
    if (CGRectEqualToRect(rect, CGRectMake(0, 0, self.size.width, self.size.height))) {
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, rect.size.width, rect.size.height, 0, GL_RGBA,
                   self.precision, image.data);
    } else {
      glTexSubImage2D(GL_TEXTURE_2D, 0, rect.origin.x, rect.origin.y,
                      rect.size.width, rect.size.height, GL_RGBA, self.precision, image.data);
    }
  }];
}

@end
