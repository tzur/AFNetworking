// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "LTFbo.h"
#import "LTGLException.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

@interface LTTexture ()

- (BOOL)inTextureRect:(CGRect)rect;

@property (readonly, nonatomic) int matType;

@end

@implementation LTGLTexture

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
  LTGLCheckDbg(@"Error deleting texture");
  _name = 0;
}

- (void)storeRect:(CGRect)rect toImage:(cv::Mat *)image {
  // Preconditions.
  LTAssert([self inTextureRect:rect],
           @"Rect for retrieving matrix from texture is out of bounds: (%g, %g, %g, %g)",
           rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

  image->create(rect.size.height, rect.size.width, self.matType);

  // \c glReadPixels requires framebuffer object that is bound to the texture that is being read.
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:self];
  [fbo bindAndExecute:^{
    // Read pixels into the mutable data, according to the texture precision.
    glReadPixels(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, GL_RGBA,
                 self.precision, image->data);
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

- (LTTexture *)clone {
  LTTexture *cloned = [[LTGLTexture alloc] initWithSize:self.size precision:self.precision
                                               channels:self.channels allocateMemory:YES];
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:cloned];

  [self cloneToFramebuffer:fbo];

  return cloned;
}

- (void)cloneTo:(LTTexture *)texture {
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];

  [self cloneToFramebuffer:fbo];
}

- (void)cloneToFramebuffer:(LTFbo *)fbo {
  LTProgram *program = [[LTProgram alloc]
                        initWithVertexSource:[LTShaderStorage LTPassthroughShaderVsh]
                        fragmentSource:[LTShaderStorage LTPassthroughShaderFsh]];
  LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:self];

  CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
  [rectDrawer drawRect:rect inFrameBuffer:fbo fromRect:rect];
}

@end
