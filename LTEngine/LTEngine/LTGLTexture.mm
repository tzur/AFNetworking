// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLTexture.h"

#import <Metal/Metal.h>

#import "CVPixelBuffer+LTEngine.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLContext+Internal.h"
#import "LTGPUResourceProxy.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Protected.h"

/// Raises if the given vector of images is not a valid mipmap.
static void LTVerifyMipmapImages(const Matrices &images) {
  LTParameterAssert(images.size(), @"Images vector must contain at least one image");

  const cv::Mat &baseImage = images.front();
  CGSize currentLevelSize = CGSizeMake(baseImage.cols, baseImage.rows);

  for (Matrices::size_type i = 1; i < images.size(); ++i) {
    LTParameterAssert(images[i].type() == baseImage.type(), @"Image type for level %zu (%d) "
                      "doesn't match base level type (%d)", i, images[i].type(), baseImage.type());

    CGSize previousLevelSize = currentLevelSize;
    currentLevelSize = CGSizeMake(images[i].cols, images[i].rows);

    LTParameterAssert(currentLevelSize == std::floor(previousLevelSize / 2),
                      @"Given image at level %zu doesn't has a size of %@, which is not a "
                      "floor(previousSize / 2) from its previous level of size %@", i,
                      NSStringFromCGSize(currentLevelSize), NSStringFromCGSize(previousLevelSize));
  }
}

@implementation LTGLTexture

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
              maxMipmapLevel:(GLint)maxMipmapLevel
              allocateMemory:(BOOL)allocateMemory {
  LTGPUResourceProxy * _Nullable proxy = nil;
  if (self = [super initWithSize:size pixelFormat:pixelFormat maxMipmapLevel:maxMipmapLevel
                  allocateMemory:allocateMemory]) {
    [self create:allocateMemory];
    proxy = [[LTGPUResourceProxy alloc] initWithResource:self];
    [self.context addResource:nn((typeof(self))proxy)];
  }
  return (typeof(self))proxy;
}

- (instancetype)initWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
              maxMipmapLevel:(GLint)maxMipmapLevel {
  return [self initWithSize:size pixelFormat:pixelFormat maxMipmapLevel:maxMipmapLevel
             allocateMemory:YES];
}

- (instancetype)initWithBaseLevelMipmapImage:(const cv::Mat &)image {
  LTVerifyMipmapImages({image});

  CGSize size = CGSizeMake(image.cols, image.rows);
  LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithMatType:image.type()];
  GLint maxMipmapLevel = log2(std::max(image.rows, image.cols));

  if (self = [self initWithSize:size pixelFormat:pixelFormat maxMipmapLevel:maxMipmapLevel
                 allocateMemory:NO]) {
    [self load:image];
    [self bindAndExecute:^{
      glGenerateMipmap(GL_TEXTURE_2D);
    }];
  }
  return self;
}

- (instancetype)initWithMipmapImages:(const Matrices &)images {
  LTVerifyMipmapImages(images);

  const cv::Mat &baseImage = images.front();
  CGSize size = CGSizeMake(baseImage.cols, baseImage.rows);
  LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithMatType:baseImage.type()];
  GLint maxMipmapLevel = (GLint)(images.size() - 1);

  if (self = [self initWithSize:size pixelFormat:pixelFormat maxMipmapLevel:maxMipmapLevel
                 allocateMemory:NO]) {
    [self loadMipmapImages:images];
  }
  return self;
}

- (void)loadMipmapImages:(const Matrices &)images {
  [self bindAndExecute:^{
    [self writeWithBlock:^{
      GLenum internalFormat = self.pixelFormat.textureInternalFormat;
      GLenum precision = self.pixelFormat.precision;
      GLenum format = self.pixelFormat.format;

      for (Matrices::size_type i = 0; i < images.size(); ++i) {
        glTexImage2D(GL_TEXTURE_2D, (GLint)i, internalFormat, images[i].cols, images[i].rows, 0,
                     format, precision, images[i].data);
      }
    }];
  }];

  LTGLCheck(@"Error loading texture mipmap levels");
}

- (instancetype)initWithMTLTexture:(id<MTLTexture>)mtlTexture {
  LTParameterAssert(mtlTexture.storageMode == MTLStorageModeShared,
                    @"Texture storage mode isn't supported: %@", mtlTexture);

  lt::Ref<CVPixelBufferRef> pixelBuffer = [LTGLTexture pixelBufferFromMTLTexture:mtlTexture];
  if (pixelBuffer) {
    return [self initWithPixelBuffer:pixelBuffer.get()];
  }

  std::vector<cv::Mat> images = [LTGLTexture readMipmapImagesFromMTLTexture:mtlTexture];
  return images.size() == 1 ?
      [self initWithImage:images[0]] : [self initWithMipmapImages:images];
}

#if COREVIDEO_SUPPORTS_IOSURFACE
  + (lt::Ref<CVPixelBufferRef>)pixelBufferFromMTLTexture:(id<MTLTexture>)texture {
    // iosurface property is part of private API starting from iOS 10.
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wunguarded-availability-new"
    IOSurfaceRef _Nullable iosurface = texture.iosurface;
    #pragma clang diagnostic pop

    if (iosurface) {
      return LTCVPixelBufferCreateWithIOSurface(iosurface, @{
        (NSString *)kCVPixelBufferOpenGLESCompatibilityKey: @YES,
        (NSString *)kCVPixelBufferMetalCompatibilityKey: @YES
      });
    }
    return {};
  }
#else
  + (lt::Ref<CVPixelBufferRef>)pixelBufferFromMTLTexture:(__unused id<MTLTexture>)texture {
    LTAssert(NO, @"Metal isn't supported by simulator");
  }
#endif

+ (std::vector<cv::Mat>)readMipmapImagesFromMTLTexture:(id<MTLTexture>)mtlTexture {
  std::vector<cv::Mat> images(mtlTexture.mipmapLevelCount);
  auto size = CGSizeMake(mtlTexture.width, mtlTexture.height);
  auto pixelFormat = [[LTGLPixelFormat alloc] initWithMTLPixelFormat:mtlTexture.pixelFormat];
  NSUInteger i = 0;
  while (i < mtlTexture.mipmapLevelCount && size.height && size.width) {
    cv::Mat image(size.height, size.width, pixelFormat.matType);
    auto region = MTLRegionMake2D(0, 0, size.width, size.height);
    [mtlTexture getBytes:image.data bytesPerRow:image.step[0] fromRegion:region mipmapLevel:i];
    images[i] = image;
    size = size / 2;
    ++i;
  }
  return images;
}

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
  __block LTGLTexture *texture;
  LTCVPixelBufferImageForReading(pixelBuffer, ^(const cv::Mat &image) {
    texture = [self initWithImage:image];
  });
  return texture;
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
    [self setMaxMipmapLevel:self.maxMipmapLevel];

    if (allocateMemory) {
      [self allocateMemoryForAllLevels];
    }
  }];

  LTGLCheck(@"Error applying texture parameters");
}

- (void)allocateMemoryForAllLevels {
  [self writeWithBlock:^{
    GLenum internalFormat = self.pixelFormat.textureInternalFormat;
    GLenum precision = self.pixelFormat.precision;
    GLenum format = self.pixelFormat.format;
    CGSize size = self.size;

    for (GLint i = 0; i <= self.maxMipmapLevel; ++i) {
      glTexImage2D(GL_TEXTURE_2D, i, internalFormat, size.width, size.height, 0, format, precision,
                   NULL);
      size = std::round(size / 2);
    }
  }];
}

- (void)dealloc {
  [self dispose];
}

- (void)dispose {
  if (!self.name || !self.context) {
    return;
  }

  [self.context removeResource:self];
  [self unbind];
  glDeleteTextures(1, &_name);
  LTGLCheckDbg(@"Error deleting texture");
  _name = 0;
}

#pragma mark -
#pragma mark LTTexture abstract methods implementation
#pragma mark -

- (cv::Mat)imageAtLevel:(NSUInteger)level {
  LTParameterAssert((GLint)level <= self.maxMipmapLevel);
  __block cv::Mat image;
  LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:self level:(GLint)level];
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
  LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:self];
  [fbo bindAndExecute:^{
    [self readRect:rect toImage:image];
  }];
}

- (void)readRect:(CGRect)rect toImage:(cv::Mat *)image {
  int matType = [self matType];
  int matTypeForReading = [self matTypeForReading];
  LTGLPixelFormat *readingPixelFormat = [[LTGLPixelFormat alloc] initWithMatType:matTypeForReading];
  image->create(rect.size.height, rect.size.width, matType);

  // If the mat has the desired data type, read directly into it. Otherwise, allocate a new mat and
  // read the data to it.
  cv::Mat readImage;
  if (matType != matTypeForReading) {
    readImage = cv::Mat(rect.size.height, rect.size.width, matTypeForReading);
  } else {
    readImage = *image;
  }

  [self.context executeAndPreserveState:^(LTGLContext *context) {
    // Since the default pack alignment is 4, it is necessarry to verify there's no special
    // packing of the texture that may effect the representation of the Mat if the number of bytes
    // per row % 4 != 0.
    context.packAlignment = 1;

    GLenum format = readingPixelFormat.format;
    GLenum precision = readingPixelFormat.precision;

    // Read pixels into the mutable data, according to the texture precision.
    glReadPixels(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height,
                 format, precision, readImage.data);
    LTGLCheckDbg(@"Failed to read pixels from rect: %@, format: %u, precision: %u",
                 NSStringFromCGRect(rect), format, precision);
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

  [self bindAndExecute:^{
    [self writeRect:rect fromImage:image];
  }];
}

- (void)writeRect:(CGRect)rect fromImage:(const cv::Mat &)image {
  cv::Mat storedImage;
  if ([self matType] == [self matTypeForWriting] && image.isContinuous()) {
    storedImage = image;
  } else {
    // Conversion has a pleasant side effect of producing continuous matrices.
    LTConvertMat(image, &storedImage, [self matTypeForWriting]);
  }
  LTAssert(storedImage.isContinuous(), @"Expected converted matrix to be continuous");

  [self writeWithBlock:^{
    [self.context executeAndPreserveState:^(LTGLContext *context) {
      // Since the default pack alignment is 4, it is necessarry to verify there's no special
      // packing of the texture that may effect the representation of the Mat if the number of bytes
      // per row % 4 != 0.
      context.unpackAlignment = 1;

      GLenum internalFormat = self.pixelFormat.textureInternalFormat;
      GLenum precision = self.pixelFormat.precision;
      GLenum format = self.pixelFormat.format;

      // If the rect occupies the entire image, use glTexImage2D, otherwise use glTexSubImage2D.
      if (CGRectEqualToRect(rect, CGRectMake(0, 0, self.size.width, self.size.height))) {
        glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, rect.size.width, rect.size.height, 0, format,
                     precision, storedImage.data);
      } else {
        // TODO:(yaron) this may create another copy of the texture. This needs to be profiled and
        // if suffers from performance impact, consider using glTexStorage.
        glTexSubImage2D(GL_TEXTURE_2D, 0, rect.origin.x, rect.origin.y,
                        rect.size.width, rect.size.height, format, precision, storedImage.data);
      }
      LTGLCheckDbg(@"Failed to load data to sub-image with rect %@", NSStringFromCGRect(rect));
    }];
  }];
}

- (LTTexture *)clone {
  LTGLTexture *cloned = [[LTGLTexture alloc] initWithSize:self.size pixelFormat:self.pixelFormat
                                           maxMipmapLevel:self.maxMipmapLevel
                                           allocateMemory:YES];
  [self cloneTo:cloned];
  return cloned;
}

- (void)cloneTo:(LTTexture *)texture {
  LTParameterAssert(texture.size == self.size,
                    @"Cloned texture size must be equal to this texture size");
  LTParameterAssert(texture.maxMipmapLevel == self.maxMipmapLevel,
                    @"Cloned texture must have the same number of mipmap levels");

  [texture performWithoutUpdatingGenerationID:^{
    if (!self.fillColor.isNull()) {
      [texture clearColor:self.fillColor];
    } else {
      for (GLint i = 0; i <= self.maxMipmapLevel; ++i) {
        LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:texture level:i];
        [self cloneToFramebuffer:fbo];
      }
    }
  }];
  texture.generationID = self.generationID;
}

- (void)cloneToFramebuffer:(LTFbo *)fbo {
  LTProgram *program = [[LTProgram alloc]
                        initWithVertexSource:[LTPassthroughShaderVsh source]
                        fragmentSource:[LTPassthroughShaderFsh source]];
  LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:self];

  CGRect sourceRect = CGRectMake(0, 0, self.size.width, self.size.height);
  CGRect targetRect = CGRectMake(0, 0, fbo.size.width, fbo.size.height);
  [self executeAndPreserveParameters:^{
    self.magFilterInterpolation = LTTextureInterpolationNearest;
    self.minFilterInterpolation = self.maxMipmapLevel ?
        LTTextureInterpolationNearestMipmapNearest : LTTextureInterpolationNearest;
    [rectDrawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
  }];
}

- (lt::Ref<CVPixelBufferRef>)pixelBuffer {
  lt::Ref<CVPixelBufferRef> pixelBuffer = LTCVPixelBufferCreate(self.size.width, self.size.height,
                                                                self.pixelFormat.cvPixelFormatType);

  LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
    // -storeRect:toImage does not work with non continuous matrices.
    if (image->isContinuous()) {
      [self storeRect:CGRectMake(0, 0, self.size.width, self.size.height) toImage:image];
    } else {
      [self image].copyTo(*image);
    }
  });

  return pixelBuffer;
}

- (id<MTLTexture>)mtlTextureWithDevice:(id<MTLDevice>)device {
  auto descriptor =
      [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.pixelFormat.mtlPixelFormat
                                                         width:self.size.width
                                                        height:self.size.height
                                                     mipmapped:self.maxMipmapLevel > 0];
  if (self.maxMipmapLevel) {
    descriptor.mipmapLevelCount = self.maxMipmapLevel + 1;
  }

  auto _Nullable mtlTexture = [device newTextureWithDescriptor:descriptor];
  LTAssert(mtlTexture, @"Failed creating MTLTexture from descriptor: %@", descriptor);

  for (NSUInteger i = 0; i < mtlTexture.mipmapLevelCount; ++i) {
    cv::Mat image = [self imageAtLevel:i];
    auto region = MTLRegionMake2D(0, 0, image.cols, image.rows);
    [mtlTexture replaceRegion:region mipmapLevel:i withBytes:image.data bytesPerRow:image.step[0]];
  }

  return mtlTexture;
}

#pragma mark -
#pragma mark LTTexture+Sampling
#pragma mark -

// Assuming that OpenGL calls are synchronized (when used in a single-threaded environment), no
// synchronization needs to be done, therefore no logic appears in reading and writing, besides
// updating the generation ID.

- (void)beginSamplingWithGPU {
}

- (void)endSamplingWithGPU {
}

#pragma mark -
#pragma mark LTTexture+Writing
#pragma mark -

- (void)beginWritingWithGPU {
  self.fillColor = LTVector4::null();
}

- (void)endWritingWithGPU {
  [self updateGenerationID];
}

- (void)writeWithBlock:(NS_NOESCAPE LTVoidBlock)block {
  // LTGLTexture doesn't support memory mapping, therefore any write should be treated as write via
  // framebuffer.
  [self writeToAttachableWithBlock:block];
}

#pragma mark -
#pragma mark Reading and writing formats
#pragma mark -

- (int)matTypeForReading {
  return CV_MAKETYPE([self matDepthForReading], [self matChannelsForReading]);
}

- (int)matDepthForReading {
  if (self.dataType == LTGLPixelDataType8Unorm) {
    // GL_UNSIGNED_BYTE is always supported for byte textures.
    return CV_8U;
  } else if (self.dataType == LTGLPixelDataType16Float) {
    // GL_HALF_FLOAT is only supported on device.
    GLint type;
    glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_TYPE, &type);
    if (type == GL_HALF_FLOAT) {
      return CV_16F;
    } else {
      return CV_32F;
    }
  } else if (self.dataType == LTGLPixelDataType32Float) {
    // If reading is possible, then support for GL_FLOAT is guaranteed.
    return CV_32F;
  } else {
    LTParameterAssert(NO, @"Reading is not supported for pixel format %@", self.pixelFormat);
  }
}

- (int)matChannelsForReading {
  switch ([self bestSupportedReadingComponents]) {
    case LTGLPixelComponentsR:
    case LTGLPixelComponentsDepth:
      return 1;
    case LTGLPixelComponentsRG:
      return 2;
    case LTGLPixelComponentsRGBA:
      return 4;
  }
}

- (LTGLPixelComponents)bestSupportedReadingComponents {
  switch (self.components) {
    case LTGLPixelComponentsR:
    case LTGLPixelComponentsDepth:
    case LTGLPixelComponentsRG:
      // Get the minimal number of channels available.
      GLint format;
      glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_FORMAT, &format);
      // GL_RED and GL_RG have the same values as GL_RED_EXT and GL_RG_EXT, so no further conversion
      // is needed here.
      switch (format) {
        case GL_RED_EXT:
          return (self.components == LTGLPixelComponentsR) ? LTGLPixelComponentsR :
              LTGLPixelComponentsRGBA;
        case GL_RG_EXT:
          return LTGLPixelComponentsRG;
        default:
          return LTGLPixelComponentsRGBA;
      }
    case LTGLPixelComponentsRGBA:
      return LTGLPixelComponentsRGBA;
  }
}

- (int)matTypeForWriting {
  switch (self.components) {
    case LTGLPixelComponentsR:
    case LTGLPixelComponentsDepth:
    case LTGLPixelComponentsRG:
    case LTGLPixelComponentsRGBA:
      return [self matType];
  }
}

@end
