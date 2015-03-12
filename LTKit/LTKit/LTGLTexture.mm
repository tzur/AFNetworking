// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import "LTCGExtensions.h"
#import "LTDevice.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLException.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
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
- (void)increaseGenerationID;

@property (readonly, nonatomic) int matType;
@property (readwrite, nonatomic) LTVector4 fillColor;

@end

@implementation LTGLTexture

- (instancetype)initWithPropertiesOf:(LTTexture *)texture {
  if (self = [super initWithSize:texture.size precision:texture.precision
                          format:texture.format allocateMemory:NO]) {
    [self allocateMipmapLevels:texture.maxMipmapLevel forTexture:self];
  }
  return self;
}

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
  LTParameterAssert(LTIsPowerOfTwo(currentLevelSize), @"Base image must be a power of two");

  for (Matrices::size_type i = 1; i < images.size(); ++i) {
    LTParameterAssert(images[i].type() == images[0].type(), @"Image type for level %lu (%d) "
                      "doesn't match base level type (%d)", i, images[i].type(), self.matType);

    CGSize previousLevelSize = currentLevelSize;
    currentLevelSize = LTCGSizeOfMat(images[i]);

    LTParameterAssert(currentLevelSize.width * 2 == previousLevelSize.width &&
                      currentLevelSize.height * 2 == previousLevelSize.height,
                      @"Given image at level %lu doesn't has a size of (%g, %g), which is not a"
                      "dyadic downsampling from its parent of size (%g, %g)", i,
                      currentLevelSize.width, currentLevelSize.height,
                      previousLevelSize.width, previousLevelSize.height);
  }
}

- (void)addImagesToMipmap:(const Matrices &)images {
  // The initial image has been already added.
  [self bindAndExecute:^{
    [self writeToTexture:^{
      for (Matrices::size_type i = 1; i < images.size(); ++i) {
        glTexImage2D(GL_TEXTURE_2D, (GLint)i, self.format, images[i].cols, images[i].rows,
                     0, self.format, self.precision, images[i].data);
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
        CGSize size = self.size;
        for (GLint i = 0; i <= self.maxMipmapLevel; ++i) {
          glTexImage2D(GL_TEXTURE_2D, i, self.format, size.width, size.height, 0,
                       self.format, self.precision, NULL);
          size = std::round(size / 2);
        }
      }];
    }
  }];

  LTGLCheck(@"Error applying texture parameters");
}

- (void)destroy {
  if (!self.name) {
    return;
  }
  [self unbind];

  glDeleteTextures(1, &_name);
  LTGLCheckDbg(@"Error deleting texture");
  _name = 0;
}

- (cv::Mat)imageAtLevel:(NSUInteger)level {
  LTParameterAssert((GLint)level <= self.maxMipmapLevel);
  __block cv::Mat image;
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:self level:level];
  [fbo bindAndExecute:^{
    [self readRect:CGRectFromSize(self.size / std::pow(2, level)) toImage:&image];
  }];
  return image;
}

- (void)storeRect:(CGRect)rect toImage:(cv::Mat *)image {
  // Preconditions.
  LTParameterAssert([self inTextureRect:rect],
                    @"Rect for retrieving matrix from texture is out of bounds: (%g, %g, %g, %g)",
                    rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

  // \c glReadPixels requires framebuffer object that is bound to the texture that is being read.
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:self];
  [fbo bindAndExecute:^{
    [self readRect:rect toImage:image];
  }];
}

- (void)readRect:(CGRect)rect toImage:(cv::Mat *)image {
  int matType = [self matType];
  int matTypeForReading = [self matTypeForReading];

  image->create(rect.size.height, rect.size.width, matType);

  // If the mat has the desired data type, read directly into it. Otherwise, allocate a new mat and
  // read the data to it.
  cv::Mat readImage;
  if (matType != matTypeForReading) {
    readImage = cv::Mat(rect.size.height, rect.size.width, matTypeForReading);
  } else {
    readImage = *image;
  }

  [self readFromTexture:^{
    [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
      // Since the default pack alignment is 4, it is necessarry to verify there's no special
      // packing of the texture that may effect the representation of the Mat if the number of bytes
      // per row % 4 != 0.
      context.packAlignment = 1;
      // Read pixels into the mutable data, according to the texture precision.
      glReadPixels(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height,
                   [self bestSupportedReadingFormat],
                   LTTexturePrecisionFromMatType(matTypeForReading),
                   readImage.data);
    }];
  }];

  // Convert read data to the output image's type, if needed.
  if (matType != matTypeForReading) {
    LTConvertMat(readImage, image, matType);
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
  LTParameterAssert(image.type() == [self matType], @"Given image has different type than the "
                    "type derived for this texture (%d vs. %d)", image.type(), [self matType]);
  LTParameterAssert(image.isContinuous(), @"Given image matrix must be continuous");

  [self bindAndExecute:^{
    [self writeRect:rect fromImage:image];
  }];
  
  self.fillColor = LTVector4Null;
}

- (void)writeRect:(CGRect)rect fromImage:(const cv::Mat &)image {
  cv::Mat storedImage;
  if ([self matType] == [self matTypeForWriting]) {
    storedImage = image;
  } else {
    LTConvertMat(image, &storedImage, [self matTypeForWriting]);
  }

  [self writeToTexture:^{
    [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
      // Since the default pack alignment is 4, it is necessarry to verify there's no special
      // packing of the texture that may effect the representation of the Mat if the number of bytes
      // per row % 4 != 0.
      context.unpackAlignment = 1;

      // If the rect occupies the entire image, use glTexImage2D, otherwise use glTexSubImage2D.
      if (CGRectEqualToRect(rect, CGRectMake(0, 0, self.size.width, self.size.height))) {
        glTexImage2D(GL_TEXTURE_2D, 0, self.format, rect.size.width, rect.size.height, 0,
                     self.format, self.precision, image.data);
      } else {
        // TODO: (yaron) this may create another copy of the texture. This needs to be profiled and
        // if suffers from performance impact, consider using glTexStorage.
        glTexSubImage2D(GL_TEXTURE_2D, 0, rect.origin.x, rect.origin.y,
                        rect.size.width, rect.size.height, self.format, self.precision,
                        image.data);
      }
    }];
  }];
}

- (LTTexture *)clone {
  LTGLTexture *cloned = [[LTGLTexture alloc] initWithSize:self.size precision:self.precision
                                                   format:self.format allocateMemory:NO];
  [cloned allocateMipmapLevels:self.maxMipmapLevel forTexture:cloned];

  [self cloneTo:cloned];
  return cloned;
}

- (void)allocateMipmapLevels:(GLint)levels forTexture:(LTGLTexture *)texture {
  LTParameterAssert(levels >= 0);
  LTParameterAssert(texture);
  texture.maxMipmapLevel = levels;
  [texture bindAndExecute:^{
    [texture writeToTexture:^{
      CGSize size = texture.size;
      for (GLint i = 0; i <= texture.maxMipmapLevel; ++i) {
        glTexImage2D(GL_TEXTURE_2D, i, texture.format, size.width, size.height, 0,
                     texture.format, texture.precision, NULL);
        size = std::round(size / 2);
      }
    }];
  }];

  LTGLCheck(@"Error allocating mipmap levels");
}

- (void)cloneTo:(LTTexture *)texture {
  LTParameterAssert(texture.size == self.size,
                    @"Cloned texture size must be equal to this texture size");
  LTParameterAssert(texture.maxMipmapLevel == self.maxMipmapLevel,
                    @"Cloned texture must have the same number of mipmap levels");

  if (!self.fillColor.isNull()) {
    [texture clearWithColor:self.fillColor];
  } else {
    for (GLint i = 0; i <= self.maxMipmapLevel; ++i) {
      LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture level:i];
      [self cloneToFramebuffer:fbo];
    }
  }
}

- (void)cloneToFramebuffer:(LTFbo *)fbo {
  LTProgram *program = [[LTProgram alloc]
                        initWithVertexSource:[LTPassthroughShaderVsh source]
                        fragmentSource:[LTPassthroughShaderFsh source]];
  LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:self];

  CGRect sourceRect = CGRectMake(0, 0, self.size.width, self.size.height);
  CGRect targetRect = CGRectMake(0, 0, fbo.texture.size.width, fbo.texture.size.height);
  [self executeAndPreserveParameters:^{
    self.magFilterInterpolation = LTTextureInterpolationNearest;
    self.minFilterInterpolation = self.maxMipmapLevel ?
        LTTextureInterpolationNearestMipmapNearest : LTTextureInterpolationNearest;
    [rectDrawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
  }];
}

// Assuming that OpenGL calls are synchronized (when used in a single-threaded environment), no
// synchronization needs to be done, therefore no logic appears in reading and writing, besides
// updating the generation ID.

- (void)beginReadFromTexture {
}

- (void)endReadFromTexture {
}

- (void)beginWriteToTexture {
}

- (void)endWriteToTexture {
  [self increaseGenerationID];
}

#pragma mark -
#pragma mark Reading and writing formats
#pragma mark -

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
  switch ([self bestSupportedReadingFormat]) {
    case LTTextureFormatRed:
      return 1;
    case LTTextureFormatRG:
      return 2;
    case LTTextureFormatRGBA:
      return 4;
    case LTTextureFormatLuminance:
      return 4;
  }
}

- (LTTextureFormat)bestSupportedReadingFormat {
  switch (self.format) {
    case LTTextureFormatRed:
    case LTTextureFormatRG:
      // Get the minimal number of channels available.
      GLint format;
      glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_FORMAT, &format);
      switch (format) {
        case GL_RED_EXT:
          return (self.format == LTTextureFormatRed) ? LTTextureFormatRed : LTTextureFormatRGBA;
        case GL_RG_EXT:
          return LTTextureFormatRG;
        default:
          return LTTextureFormatRGBA;
      }
    case LTTextureFormatRGBA:
      return LTTextureFormatRGBA;
    case LTTextureFormatLuminance:
      return LTTextureFormatRGBA;
  }
}

- (int)matTypeForWriting {
  switch (self.channels) {
    case LTTextureChannelsOne:
    case LTTextureChannelsTwo:
      if ([LTDevice currentDevice].supportsRGTextures) {
        return [self matType];
      } else {
        return CV_MAKETYPE(CV_MAT_DEPTH([self matType]), 4);
      }
    case LTTextureChannelsFour:
      return [self matType];
  }
}

@end
