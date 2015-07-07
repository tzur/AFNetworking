// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMTexture.h"

#import "LTBoundaryCondition.h"
#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTexture+Protected.h"

@interface LTMMTexture ()

/// Lock for texture read/write synchronization.
@property (strong, nonatomic) NSRecursiveLock *lock;

/// Reference to the pixel buffer that backs the texture.
@property (nonatomic) CVPixelBufferRef pixelBufferRef;

/// Reference to the texture object.
@property (nonatomic) CVOpenGLESTextureRef textureRef;

/// Reference to the texture cache object.
@property (nonatomic) CVOpenGLESTextureCacheRef textureCacheRef;

/// OpenGL sync object used for GPU/CPU synchronization.
@property (nonatomic) GLsync syncObject;

@end

@implementation LTMMTexture

#pragma mark -
#pragma mark Abstract implementation
#pragma mark -

- (void)create:(BOOL __unused)allocateMemory {
  // It's impossible to avoid memory allocation since the shared memory texture buffer must be
  // allocated via CV* functions to allow updates to reflect to OpenGL.
  [self createTextureForMatType:self.matType];
}

- (void)createTextureForMatType:(int)type {
  [self createPixelBufferForMatType:type];
  [self allocateTexture];
  [self bindAndExecute:^{
    [self setMinFilterInterpolation:self.minFilterInterpolation];
    [self setMagFilterInterpolation:self.magFilterInterpolation];
    [self setWrap:self.wrap];
    [self setMaxMipmapLevel:self.maxMipmapLevel];
  }];
}

- (void)createPixelBufferForMatType:(int)type {
  OSType pixelFormat = [self pixelFormatForMatType:type];
  NSDictionary *attributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}};

  CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault, self.size.width, self.size.height,
                                        pixelFormat, (__bridge CFDictionaryRef)attributes,
                                        &_pixelBufferRef);
  if (result != kCVReturnSuccess) {
    [LTGLException raise:kLTTextureCreationFailedException
                  format:@"Failed creating pixel buffer with error %d", result];
  }
}

- (void)allocateTexture {
  CVReturn result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                 self.textureCacheRef,
                                                                 self.pixelBufferRef,
                                                                 NULL,
                                                                 GL_TEXTURE_2D,
                                                                 self.format,
                                                                 self.size.width, self.size.height,
                                                                 self.format,
                                                                 self.precision,
                                                                 0,
                                                                 &_textureRef);
  if (result != kCVReturnSuccess) {
    [LTGLException raise:kLTTextureCreationFailedException
                  format:@"Failed creating texture with error %d", result];
  }
}

- (OSType)pixelFormatForMatType:(int)type {
  switch (LTTextureChannelsFromMatType(type)) {
    case LTTextureChannelsOne:
      switch (LTTexturePrecisionFromMatType(type)) {
        case LTTexturePrecisionByte:
          return kCVPixelFormatType_OneComponent8;
        case LTTexturePrecisionHalfFloat:
          return kCVPixelFormatType_OneComponent16Half;
        case LTTexturePrecisionFloat:
          return kCVPixelFormatType_OneComponent32Float;
      }
      break;
    case LTTextureChannelsTwo:
      switch (LTTexturePrecisionFromMatType(type)) {
        case LTTexturePrecisionByte:
          return kCVPixelFormatType_TwoComponent8;
        case LTTexturePrecisionHalfFloat:
          return kCVPixelFormatType_TwoComponent16Half;
        case LTTexturePrecisionFloat:
          return kCVPixelFormatType_TwoComponent32Float;
      }
      break;
    case LTTextureChannelsFour:
      switch (LTTexturePrecisionFromMatType(type)) {
        case LTTexturePrecisionByte:
          return kCVPixelFormatType_32BGRA;
        case LTTexturePrecisionHalfFloat:
          return kCVPixelFormatType_64RGBAHalf;
        case LTTexturePrecisionFloat:
          return kCVPixelFormatType_128RGBAFloat;
      }
      break;
  }
}

- (CVOpenGLESTextureCacheRef)textureCacheRef {
  if (!_textureCacheRef) {
    EAGLContext *context = [EAGLContext currentContext];
    LTAssert(context, @"Must have an active OpenGL ES context");

    CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL,
                                                   &_textureCacheRef);
    if (result != kCVReturnSuccess) {
      [LTGLException raise:kLTTextureCreationFailedException
                    format:@"Failed creating texture cache with error %d", result];
    }
  }
  return _textureCacheRef;
}

- (void)destroy {
  if (!self.name) {
    return;
  }

  [self lockTextureAndExecute:^{
    if (self.pixelBufferRef) {
      CVPixelBufferRelease(self.pixelBufferRef);
      self.pixelBufferRef = NULL;
    }
    if (self.textureRef) {
      CFRelease(self.textureRef);
      self.textureRef = NULL;
    }
    if (self.textureCacheRef) {
      CVOpenGLESTextureCacheFlush(self.textureCacheRef, 0);
      CFRelease(self.textureCacheRef);
      self.textureCacheRef = NULL;
    }
    self.syncObject = nil;
  }];
}

- (void)storeRect:(CGRect)rect toImage:(cv::Mat *)image {
  // Preconditions.
  LTParameterAssert([self inTextureRect:rect],
                    @"Rect for retrieving matrix from texture is out of bounds: (%g, %g, %g, %g)",
                    rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

  [self mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    cv::Rect roi(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    mapped(roi).copyTo(*image);
  }];
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

  if (!self.textureRef) {
    [self createTextureForMatType:image.type()];
  }

  [self mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    LTParameterAssert(image.type() == mapped->type(), @"Source image's type (%d) must match "
                      "mapped image's type (%d)", image.type(), mapped->type());
    cv::Rect roi(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    image.copyTo((*mapped)(roi));
  }];
}

- (LTTexture *)clone {
  LTTexture *cloned = [[LTMMTexture alloc] initWithPropertiesOf:self];
  [self cloneTo:cloned];
  return cloned;
}

- (void)cloneTo:(LTTexture *)texture {
  LTParameterAssert(texture.size == self.size,
                    @"Cloned texture size must be equal to this texture size");

  [texture performWithoutUpdatingGenerationID:^{
    if (!self.fillColor.isNull()) {
      [texture clearWithColor:self.fillColor];
    } else {
      LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:texture];
      [self cloneToFramebuffer:fbo];
    }
  }];
  texture.generationID = self.generationID;
}

- (void)cloneToFramebuffer:(LTFbo *)fbo {
  LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithSourceTexture:self];

  [self executeAndPreserveParameters:^{
    self.minFilterInterpolation = LTTextureInterpolationNearest;
    self.magFilterInterpolation = LTTextureInterpolationNearest;

    [rectDrawer drawRect:CGRectFromSize(self.size) inFramebuffer:fbo
                fromRect:CGRectFromSize(fbo.texture.size)];
  }];
}

- (void)beginReadFromTexture {
  [self.lock lock];
}

- (void)endReadFromTexture {
  [self.lock unlock];
}

- (void)beginWriteToTexture {
  [self.lock lock];
  self.fillColor = LTVector4Null;
}

- (void)endWriteToTexture {
  // Make \c self.syncObject a synchronization barrier that is right beyond the last drawing to this
  // texture in the GPU queue.
  self.syncObject = glFenceSyncAPPLE(GL_SYNC_GPU_COMMANDS_COMPLETE_APPLE, 0);

  [self updateGenerationID];
  [self.lock unlock];
}

#pragma mark -
#pragma mark Overridden methods
#pragma mark -

- (LTVector4s)pixelValues:(const CGPoints &)locations {
  __block LTVector4s values(locations.size());

  [self mappedImageForReading:^(const cv::Mat &texture, BOOL) {
    for (CGPoints::size_type i = 0; i < locations.size(); ++i) {
      // Use boundary conditions similar to Matlab's 'symmetric'.
      LTVector2 location = [LTSymmetricBoundaryCondition
                             boundaryConditionForPoint:LTVector2(locations[i].x,
                                                                      locations[i].y)
                             withSignalSize:cv::Size2i(self.size.width, self.size.height)];
      cv::Point2i point = cv::Point2i(std::floor(location.x), std::floor(location.y));

      values[i] = LTPixelValueFromImage(texture, point);
    }
  }];

  return values;
}

#pragma mark -
#pragma mark Locking
#pragma mark -

- (NSRecursiveLock *)lock {
  if (!_lock) {
    _lock = [[NSRecursiveLock alloc] init];
  }
  return _lock;
}

- (void)lockTextureAndExecute:(LTVoidBlock)block {
  @try {
    [self.lock lock];
    block();
  } @finally {
    [self.lock unlock];
  }
}

#pragma mark -
#pragma mark Memory mapping
#pragma mark -

typedef LTTextureMappedWriteBlock LTTextureMappedBlock;

- (void)mappedImageForReading:(LTTextureMappedReadBlock)block {
  LTParameterAssert(block);

  [self mappedImageWithBlock:^(cv::Mat *mapped, BOOL isCopy) {
    block(*mapped, isCopy);
  } withFlags:kCVPixelBufferLock_ReadOnly];
}

- (void)mappedImageForWriting:(LTTextureMappedWriteBlock)block {
  self.fillColor = LTVector4Null;
  [self mappedImageWithBlock:block withFlags:0];
  [self updateGenerationID];
}

- (void)mappedImageWithBlock:(LTTextureMappedBlock)block withFlags:(CVOptionFlags)lockFlags {
  LTParameterAssert(block);

  [self lockTextureAndExecute:^{
    LTAssert(self.pixelBufferRef, @"Pixelbuffer must be created before calling mappedImage:");

    // Make sure everything is written to the texture before reading back to CPU.
    if (glIsSyncAPPLE(self.syncObject)) {
      [self waitForGPU];
    }

    [self lockBufferAndExecute:^{
      void *base = CVPixelBufferGetBaseAddress(self.pixelBufferRef);
      cv::Mat mat(self.size.height, self.size.width, self.matType, base,
                  CVPixelBufferGetBytesPerRow(self.pixelBufferRef));
      block(&mat, NO);
    } withFlags:lockFlags];
  }];
}

- (void)waitForGPU {
  GLint64 maxTimeout;
  glGetInteger64vAPPLE(GL_MAX_SERVER_WAIT_TIMEOUT_APPLE, &maxTimeout);
  GLenum waitResult = glClientWaitSyncAPPLE(self.syncObject,
                                            GL_SYNC_FLUSH_COMMANDS_BIT_APPLE,
                                            maxTimeout);
  self.syncObject = nil;

  LTAssert(waitResult != GL_TIMEOUT_EXPIRED_APPLE, @"Timed out while waiting for sync object");
  LTAssert(waitResult != GL_WAIT_FAILED_APPLE, @"Failed waiting on sync object");
}

- (void)lockBufferAndExecute:(LTVoidBlock)block withFlags:(CVOptionFlags)lockFlags {
  CVReturn lockResult = CVPixelBufferLockBaseAddress(self.pixelBufferRef, lockFlags);
  if (kCVReturnSuccess != lockResult) {
    [LTGLException raise:kLTMMTextureBufferLockingFailedException
                  format:@"Failed locking base address of buffer with error %d", lockResult];
  }

  if (block) block();

  CVReturn unlockResult = CVPixelBufferUnlockBaseAddress(self.pixelBufferRef, lockFlags);
  if (kCVReturnSuccess != unlockResult) {
    [LTGLException raise:kLTMMTextureBufferLockingFailedException
                  format:@"Failed unlocking base address of buffer with error %d", unlockResult];
  }
}

- (void)setSyncObject:(GLsync)syncObject {
  if (glIsSyncAPPLE(_syncObject)) {
    glDeleteSyncAPPLE(_syncObject);
  }
  _syncObject = syncObject;
}

#pragma mark -
#pragma mark Public properties
#pragma mark -

- (GLuint)name {
  return self.textureRef ? CVOpenGLESTextureGetName(self.textureRef) : 0;
}

@end
