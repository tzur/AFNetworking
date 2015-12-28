// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMTexture.h"

#import "LTBoundaryCondition.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTexture+Protected.h"

@interface LTMMTexture () {
  /// Reference to the pixel buffer that backs the texture.
  lt::Ref<CVPixelBufferRef> _pixelBuffer;

  /// Reference to the texture object.
  lt::Ref<CVOpenGLESTextureRef> _texture;

  /// Reference to the texture cache object.
  lt::Ref<CVOpenGLESTextureCacheRef> _textureCache;
}

/// Lock for texture read/write synchronization.
@property (strong, nonatomic) NSRecursiveLock *lock;

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
  [self createPixelBuffer];
  [self createTextureCache];
  [self allocateTexture];
  [self bindAndExecute:^{
    [self setMinFilterInterpolation:self.minFilterInterpolation];
    [self setMagFilterInterpolation:self.magFilterInterpolation];
    [self setWrap:self.wrap];
    [self setMaxMipmapLevel:self.maxMipmapLevel];
  }];
}

- (void)createPixelBuffer {
  NSDictionary *attributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}};

  CVPixelBufferRef pixelBufferRef;
  OSType pixelFormatType = self.pixelFormat.cvPixelFormatType;
  LTParameterAssert(pixelFormatType != kUnknownType, @"Pixel format %@ is not compatible with "
                    "CoreVideo, so no pixel buffer can be created from it", self.pixelFormat);
  CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault, self.size.width, self.size.height,
                                        pixelFormatType, (__bridge CFDictionaryRef)attributes,
                                        &pixelBufferRef);
  if (result != kCVReturnSuccess) {
    [LTGLException raise:kLTTextureCreationFailedException
                  format:@"Failed creating pixel buffer with error %d", result];
  }

  _pixelBuffer.reset(pixelBufferRef);
}

- (void)createTextureCache {
  EAGLContext *context = [EAGLContext currentContext];
  LTAssert(context, @"Must have an active OpenGL ES context");

  CVOpenGLESTextureCacheRef textureCacheRef;
  CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL,
                                                 &textureCacheRef);
  if (result != kCVReturnSuccess) {
    [LTGLException raise:kLTTextureCreationFailedException
                  format:@"Failed creating texture cache with error %d", result];
  }

  _textureCache.reset(textureCacheRef);
}

- (void)allocateTexture {
  LTGLVersion version = [LTGLContext currentContext].version;
  GLenum internalFormat = [self.pixelFormat internalFormatForVersion:version];
  GLenum format = [self.pixelFormat formatForVersion:version];
  GLenum precision = [self.pixelFormat precisionForVersion:version];

  CVOpenGLESTextureRef textureRef;
  CVReturn result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                 _textureCache.get(),
                                                                 _pixelBuffer.get(),
                                                                 NULL,
                                                                 GL_TEXTURE_2D,
                                                                 internalFormat,
                                                                 self.size.width, self.size.height,
                                                                 format,
                                                                 precision,
                                                                 0,
                                                                 &textureRef);
  if (result != kCVReturnSuccess) {
    [LTGLException raise:kLTTextureCreationFailedException
                  format:@"Failed creating texture with error %d", result];
  }

  _texture.reset(textureRef);
}

- (void)destroy {
  if (!self.name) {
    return;
  }

  [self lockTextureAndExecute:^{
    _pixelBuffer.reset(nullptr);
    _texture.reset(nullptr);

    if (_textureCache) {
      CVOpenGLESTextureCacheFlush(_textureCache.get(), 0);
      _textureCache.reset(nullptr);
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
                fromRect:CGRectFromSize(fbo.size)];
  }];
}

- (void)beginSamplingWithGPU {
  [self.lock lock];
}

- (void)endSamplingWithGPU {
  [self.lock unlock];
}

- (void)beginWritingWithGPU {
  [self.lock lock];
  self.fillColor = LTVector4::null();
}

- (void)endWritingWithGPU {
  // Make \c self.syncObject a synchronization barrier that is right beyond the last drawing to this
  // texture in the GPU queue.
  [[LTGLContext currentContext] executeForOpenGLES2:^{
    self.syncObject = glFenceSyncAPPLE(GL_SYNC_GPU_COMMANDS_COMPLETE_APPLE, 0);
  } openGLES3:^{
    self.syncObject = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
  }];

  [self updateGenerationID];
  [self.lock unlock];
}

#pragma mark -
#pragma mark Overridden methods
#pragma mark -

- (LTVector4s)pixelValues:(const CGPoints &)locations {
  __block LTVector4s values(locations.size());

  LTTextureSamplingPoints samplingPoints([self samplingPointsFromLocations:locations]);

  [self mappedImageForReading:^(const cv::Mat &texture, BOOL) {
    std::transform(samplingPoints.cbegin(), samplingPoints.cend(), values.begin(),
                   [&texture](cv::Point2i point) {
                     return LTPixelValueFromImage(texture, point);
                   });
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
  self.fillColor = LTVector4::null();
  [self mappedImageWithBlock:block withFlags:0];
  [self updateGenerationID];
}

- (void)mappedImageWithBlock:(LTTextureMappedBlock)block withFlags:(CVOptionFlags)lockFlags {
  LTParameterAssert(block);

  [self lockTextureAndExecute:^{
    LTAssert(_pixelBuffer, @"Pixelbuffer must be created before calling mappedImage:");

    // Make sure everything is written to the texture before reading back to CPU.
    __block BOOL isSync;
    [[LTGLContext currentContext] executeForOpenGLES2:^{
      isSync = glIsSyncAPPLE(self.syncObject);
    } openGLES3:^{
      isSync = glIsSync(self.syncObject);
    }];
    if (isSync) {
      [self waitForGPU];
    }

    [self lockBufferAndExecute:^{
      void *base = CVPixelBufferGetBaseAddress(_pixelBuffer.get());
      cv::Mat mat(self.size.height, self.size.width, self.matType, base,
                  CVPixelBufferGetBytesPerRow(_pixelBuffer.get()));
      block(&mat, NO);
    } withFlags:lockFlags];
  }];
}

- (void)waitForGPU {
  static const GLuint64 kMaxTimeout = std::numeric_limits<GLuint64>::max();

  __block GLenum waitResult;
  [[LTGLContext currentContext] executeForOpenGLES2:^{
    waitResult = glClientWaitSyncAPPLE(self.syncObject, GL_SYNC_FLUSH_COMMANDS_BIT, kMaxTimeout);
  } openGLES3:^{
    waitResult = glClientWaitSync(self.syncObject, GL_SYNC_FLUSH_COMMANDS_BIT, kMaxTimeout);
  }];
  self.syncObject = nil;

  LTAssert(waitResult != GL_TIMEOUT_EXPIRED_APPLE, @"Timed out while waiting for sync object");
  LTAssert(waitResult != GL_WAIT_FAILED_APPLE, @"Failed waiting on sync object");
}

- (void)lockBufferAndExecute:(LTVoidBlock)block withFlags:(CVOptionFlags)lockFlags {
  CVReturn lockResult = CVPixelBufferLockBaseAddress(_pixelBuffer.get(), lockFlags);
  if (kCVReturnSuccess != lockResult) {
    [LTGLException raise:kLTMMTextureBufferLockingFailedException
                  format:@"Failed locking base address of buffer with error %d", lockResult];
  }

  if (block) block();

  CVReturn unlockResult = CVPixelBufferUnlockBaseAddress(_pixelBuffer.get(), lockFlags);
  if (kCVReturnSuccess != unlockResult) {
    [LTGLException raise:kLTMMTextureBufferLockingFailedException
                  format:@"Failed unlocking base address of buffer with error %d", unlockResult];
  }
}

- (void)setSyncObject:(GLsync)syncObject {
  [[LTGLContext currentContext] executeForOpenGLES2:^{
    if (glIsSyncAPPLE(_syncObject)) {
      glDeleteSyncAPPLE(_syncObject);
    }
  } openGLES3:^{
    if (glIsSync(_syncObject)) {
      glDeleteSync(_syncObject);
    }
  }];
  _syncObject = syncObject;
}

#pragma mark -
#pragma mark Public properties
#pragma mark -

- (GLuint)name {
  return _texture ? CVOpenGLESTextureGetName(_texture.get()) : 0;
}

@end
