// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "LTDevice.h"
#import "LTFbo.h"
#import "LTGLException.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

/// Returns the \c CGSize of the given \c mat.
CGSize LTCGSizeOfMat(const cv::Mat &mat) {
  return CGSizeMake(mat.cols, mat.rows);
}

@interface LTTexture ()

- (BOOL)inTextureRect:(CGRect)rect;
- (BOOL)isPowerOfTwo:(CGSize)size;

@property (readonly, nonatomic) int matType;

@end

@implementation LTGLTexture

#pragma mark -
#pragma mark Mipmaps
#pragma mark -

- (instancetype)initWithBaseLevelMipmapImage:(const cv::Mat &)image {
  [self verifyMipmapImages:{image}];
  if (self = [self initWithImage:image]) {
    [self bindAndExecute:^{
      glGenerateMipmap(GL_TEXTURE_2D);
      self.maxMipmapLevel = log2(std::max(image.rows, image.cols));
    }];
  }
  return self;
}

- (instancetype)initWithMipmapImages:(const Matrices &)images {
  [self verifyMipmapImages:images];
  if (self = [self initWithImage:images[0]]) {
    [self addImagesToMipmap:images];
  }
  return self;
}

- (void)verifyMipmapImages:(const Matrices &)images {
  LTParameterAssert(images.size(), @"Images vector must contain at least one image");

  CGSize currentLevelSize = LTCGSizeOfMat(images[0]);
  LTParameterAssert([self isPowerOfTwo:currentLevelSize], @"Base image must be a power of two");

  for (Matrices::size_type i = 1; i < images.size(); ++i) {
    LTParameterAssert(images[i].type() == images[0].type(), @"Image type for level %lu (%d) doesn't "
                      "match base level type (%d)", i, images[i].type(), self.matType);

    CGSize previousLevelSize = currentLevelSize;
    currentLevelSize = LTCGSizeOfMat(images[i]);

    LTParameterAssert(currentLevelSize.width * 2 == previousLevelSize.width &&
                      currentLevelSize.height * 2 == previousLevelSize.height,
                      @"Given image at level %lu doesn't has a size of (%g, %g), which is not a"
                      "dyadic downsampling from its parent of size (%g, %g)", i,
                      currentLevelSize.width, currentLevelSize.height, previousLevelSize.width,
                      previousLevelSize.height);
  }
}

- (void)addImagesToMipmap:(const Matrices &)images {
  // The initial image has been already added.
  [self bindAndExecute:^{
    [self writeToTexture:^{
      for (Matrices::size_type i = 1; i < images.size(); ++i) {
        glTexImage2D(GL_TEXTURE_2D, (GLint)i, self.channels, images[i].cols, images[i].rows,
                     0, self.channels, self.precision, images[i].data);
      }
    }];
  }];

  LTGLCheck(@"Error loading texture mipmap levels");

  // Allow rendering with incomplete mipmap levels.
  self.maxMipmapLevel = (GLint)(images.size() - 1);
}

#pragma mark -
#pragma mark LTTexture abstract methods implementation
#pragma mark -

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
    [self setMaxMipmapLevel:self.maxMipmapLevel];

    if (allocateMemory) {
      [self writeToTexture:^{
        glTexImage2D(GL_TEXTURE_2D, 0, self.channels, self.size.width, self.size.height, 0,
                     self.channels, self.precision, NULL);
      }];
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
  LTParameterAssert([self inTextureRect:rect],
                    @"Rect for retrieving matrix from texture is out of bounds: (%g, %g, %g, %g)",
                    rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

  // \c glReadPixels requires framebuffer object that is bound to the texture that is being read.
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:self];
  [fbo bindAndExecute:^{
    image->create(rect.size.height, rect.size.width, [self matTypeForReading]);
    [self readFromTexture:^{
      // Read pixels into the mutable data, according to the texture precision.
      glReadPixels(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height,
                   LTTextureChannelsFromMat(*image), LTTexturePrecisionFromMat(*image),
                   image->data);
    }];
  }];
}

- (int)matTypeForReading {
  return CV_MAKETYPE([self matDepthForReading], [self matChannelsForReading]);
}

- (int)matDepthForReading {
  switch (self.precision) {
    case LTTexturePrecisionByte:
      // GL_UNSIGNED_BYTE is always supported for byte textures.
      return CV_8U;
    case LTTexturePrecisionHalfFloat:
      // GL_HALF_FLOAT is only supported on device.
      GLint type;
      glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_TYPE, &type);
      if (type == GL_HALF_FLOAT_OES) {
        return CV_16U;
      } else {
        return CV_32F;
      }
    case LTTexturePrecisionFloat:
      // If reading is possible, then support for GL_FLOAT is guaranteed.
      return CV_32F;
  }
}

- (int)matChannelsForReading {
  switch (self.channels) {
    case LTTextureChannelsR:
    case LTTextureChannelsRG:
      // Try to get the minimal number of channels available.
      GLint format;
      glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_FORMAT, &format);
      switch (format) {
        case GL_RED_EXT:
          return (self.channels == LTTextureChannelsR) ? 1 : 4;
        case GL_RG_EXT:
          return 2;
        default:
          return 4;
      }
    case LTTextureChannelsRGBA:
      // Reading GL_RGBA is always supported, for all depths.
      return 4;
  }
}

- (void)loadRect:(CGRect)rect fromImage:(const cv::Mat &)image {
  // Preconditions.
  LTParameterAssert([self inTextureRect:rect],
                    @"Rect for retrieving image from texture is out of bounds: (%g, %g, %g, %g)",
                    rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
  LTParameterAssert(image.cols == rect.size.width && image.rows == rect.size.height,
                    @"Trying to load to rect with size (%g, %g) from a Mat with different size: "
                    "(%d, %d)", rect.size.width, rect.size.height, image.cols, image.rows);
  // TODO: (yaron) add test for image type.

  [self bindAndExecute:^{
    [self writeToTexture:^{
      // If the rect occupies the entire image, use glTexImage2D, otherwise use glTexSubImage2D.
      if (CGRectEqualToRect(rect, CGRectMake(0, 0, self.size.width, self.size.height))) {
        glTexImage2D(GL_TEXTURE_2D, 0, self.channels, rect.size.width, rect.size.height, 0,
                     self.channels, self.precision, image.data);
      } else {
        // TODO: (yaron) this may create another copy of the texture. This needs to be profiled and
        // if suffers from performance impact, consider using glTexStorage.
        glTexSubImage2D(GL_TEXTURE_2D, 0, rect.origin.x, rect.origin.y,
                        rect.size.width, rect.size.height, self.channels, self.precision,
                        image.data);
      }
    }];
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
                        initWithVertexSource:[LTPassthroughShaderVsh source]
                        fragmentSource:[LTPassthroughShaderFsh source]];
  LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:self];

  CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
  [rectDrawer drawRect:rect inFramebuffer:fbo fromRect:rect];
}

// Assuming that OpenGL calls are synchronized (when used in a single-threaded environment), no
// synchronization needs to be done.
- (void)beginReadFromTexture {}
- (void)endReadFromTexture {}
- (void)beginWriteToTexture {}
- (void)endWriteToTexture {}

@end
