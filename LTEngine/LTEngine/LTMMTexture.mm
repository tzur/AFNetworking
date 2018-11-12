// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMMTexture.h"

#if COREVIDEO_SUPPORTS_IOSURFACE
  #import <IOSurface/IOSurfaceObjC.h>
  #import <OpenGLEs/EAGLIOSurface.h>
#endif

#import <Metal/Metal.h>

#import "CIContext+PixelFormat.h"
#import "CIImage+Swizzle.h"
#import "CVPixelBuffer+LTEngine.h"
#import "LTBoundaryCondition.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLContext+Internal.h"
#import "LTGLKitExtensions.h"
#import "LTGPUResourceProxy.h"
#import "LTOpenCVExtensions.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTexture+Protected.h"

@interface LTMMTexture () <LTGPUResource> {
  /// Reference to the pixel buffer that backs the texture.
  lt::Ref<CVPixelBufferRef> _pixelBuffer;

  /// Reference to the texture object.
  lt::Ref<CVOpenGLESTextureRef> _texture;

  /// Reference to the texture cache object.
  lt::Ref<CVOpenGLESTextureCacheRef> _textureCache;
}

/// Index of the pixel buffer plane backing this texture, or \c 0 if the pixel buffer is not planar.
@property (readonly, nonatomic) size_t planeIndex;

/// Lock for texture read/write synchronization.
@property (strong, nonatomic) NSRecursiveLock *lock;

/// OpenGL sync object used in the scenarios of GPU write followed by a CPU read/write, to make sure
/// the GPU has finished writing to the texture before reading the buffer from the CPU.
@property (nonatomic, nullable) GLsync writeSyncObject;

/// OpenGL sync object used in the scenario of GPU read followed by a CPU write, to avoid
/// out-of-order execution which will cause the CPU write to be performed before the GPU read.
@property (nonatomic, nullable) GLsync readSyncObject;

@end

@implementation LTMMTexture

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
              maxMipmapLevel:(GLint)maxMipmapLevel
              allocateMemory:(BOOL)allocateMemory {
  LTParameterAssert(!maxMipmapLevel, @"LTMMTexture does not support mipmaps");
  LTGPUResourceProxy * _Nullable proxy = nil;
  if (self = [super initWithSize:size pixelFormat:pixelFormat maxMipmapLevel:maxMipmapLevel
                  allocateMemory:allocateMemory]) {
    [self setupPixelBuffer:[self createPixelBuffer]];
    [self setupOpenGLParameters];
    proxy = [[LTGPUResourceProxy alloc] initWithResource:self];
    [self.context addResource:nn((typeof(self))proxy)];
  }
  return (typeof(self))proxy;
}

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
  LTParameterAssert(pixelBuffer);
  LTParameterAssert(!CVPixelBufferIsPlanar(pixelBuffer),
                    @"The given pixel buffer must not be planar");

  CGSize size = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
  LTGLPixelFormat *pixelFormat =
      [[LTGLPixelFormat alloc]
       initWithCVPixelFormatType:CVPixelBufferGetPixelFormatType(pixelBuffer)];

  if (self = [super initWithSize:size pixelFormat:pixelFormat maxMipmapLevel:0 allocateMemory:NO]) {
    _planeIndex = 0;
    [self setupPixelBuffer:lt::Ref<CVPixelBufferRef>(CVPixelBufferRetain(pixelBuffer))];
    [self setupOpenGLParameters];
  }
  return self;
}

- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer planeIndex:(size_t)planeIndex {
  LTParameterAssert(pixelBuffer);
  LTParameterAssert(CVPixelBufferIsPlanar(pixelBuffer),
                    @"The given pixel buffer must be planar");

  const size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
  LTParameterAssert(planeIndex < planeCount, @"The given plane index: %zu is invalid. "
                    "The given pixel buffer has only %zu planes", planeIndex, planeCount);

  CGSize size = CGSizeMake(CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex),
                           CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex));
  LTGLPixelFormat *pixelFormat =
      [[LTGLPixelFormat alloc]
       initWithPlanarCVPixelFormatType:CVPixelBufferGetPixelFormatType(pixelBuffer)
       planeIndex:planeIndex];

  if (self = [super initWithSize:size pixelFormat:pixelFormat maxMipmapLevel:0 allocateMemory:NO]) {
    _planeIndex = planeIndex;
    [self setupPixelBuffer:lt::Ref<CVPixelBufferRef>(CVPixelBufferRetain(pixelBuffer))];
    [self setupOpenGLParameters];
  }
  return self;
}

- (void)setupPixelBuffer:(lt::Ref<CVPixelBufferRef>)pixelBuffer {
  _pixelBuffer = std::move(pixelBuffer);
#if COREVIDEO_SUPPORTS_IOSURFACE
  if (@available(iOS 11.0, *)) {
    auto _Nullable backingSurface = CVPixelBufferGetIOSurface(_pixelBuffer.get());
    if (!backingSurface) {
      [LTGLException raise:kLTTextureCreationFailedException
                    format:@"Pixel buffer must be backed by IOSurface"];
    }
    [self setupSurfaceBackedTexture];
    return;
  }
#endif

  [self setupTextureCacheBackedTexture];
}

#if COREVIDEO_SUPPORTS_IOSURFACE
- (void)setupSurfaceBackedTexture {
  auto internalFormat = self.pixelFormat.textureInternalFormat;
  auto format = self.pixelFormat.format;
  auto precision = self.pixelFormat.precision;
  auto eaglContext = self.context.context;
  auto _Nullable surface = CVPixelBufferGetIOSurface(_pixelBuffer.get());
  LTParameterAssert(surface, @"Pixel buffer must be backed by IOSurface");

  glGenTextures(1, &_name);
  [self bindAndExecute:^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    auto success = [eaglContext texImageIOSurface:surface target:GL_TEXTURE_2D
                                   internalFormat:internalFormat width:self.size.width
                                           height:self.size.height format:format type:precision
                                            plane:(uint32_t)self.planeIndex];
#pragma clang diagnostic pop
    if (!success) {
      [LTGLException raise:kLTTextureCreationFailedException
                    format:@"Failed creating OpenGL texture %u backed by %@", self->_name, surface];
    }
  }];
  LTGLCheckDbg(@"Error occurred when creating OpenGL texture %u backed by IOSurface %@", _name,
               surface);
}
#endif

- (lt::Ref<CVPixelBufferRef>)createPixelBuffer {
  OSType pixelFormatType = self.pixelFormat.cvPixelFormatType;
  LTParameterAssert(pixelFormatType != kUnknownType, @"Pixel format %@ is not compatible with "
                    "CoreVideo, so no pixel buffer can be created from it", self.pixelFormat);

  return LTCVPixelBufferCreate(self.size.width, self.size.height, pixelFormatType);
}

- (void)setupTextureCacheBackedTexture {
  [self createTextureCache];
  [self allocateTextureCacheBackedTexture];
  _name = CVOpenGLESTextureGetName(_texture.get());
}

- (void)setupOpenGLParameters {
  [self bindAndExecute:^{
    [self setMinFilterInterpolation:self.minFilterInterpolation];
    [self setMagFilterInterpolation:self.magFilterInterpolation];
    [self setWrap:self.wrap];
    [self setMaxMipmapLevel:self.maxMipmapLevel];
  }];
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

- (void)allocateTextureCacheBackedTexture {
  GLenum internalFormat = self.pixelFormat.textureInternalFormat;
  GLenum format = self.pixelFormat.format;
  GLenum precision = self.pixelFormat.precision;

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
                                                                 self.planeIndex,
                                                                 &textureRef);
  if (result != kCVReturnSuccess) {
    [LTGLException raise:kLTTextureCreationFailedException
                  format:@"Failed creating texture with error %d", result];
  }

  _texture.reset(textureRef);
}

#if COREVIDEO_SUPPORTS_IOSURFACE
  - (instancetype)initWithMTLTexture:(id<MTLTexture>)mtlTexture {
    LTParameterAssert(mtlTexture.storageMode == MTLStorageModeShared,
                      @"Texture storage mode isn't supported: %@", mtlTexture);

    // iosurface property is part of private API starting from iOS 10.
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wunguarded-availability-new"
    IOSurfaceRef _Nullable iosurface = mtlTexture.iosurface;
    #pragma clang diagnostic pop

    LTAssert(iosurface, @"MTLTexture backing content isn't supported %@", mtlTexture);
    return [self initWithPixelBuffer:LTCVPixelBufferCreateWithIOSurface(iosurface, @{
      (NSString *)kCVPixelBufferOpenGLESCompatibilityKey: @YES,
      (NSString *)kCVPixelBufferMetalCompatibilityKey: @YES
    }).get()];
  }
#else
  - (instancetype)initWithMTLTexture:(__unused id<MTLTexture>)mtlTexture {
    LTAssert(NO, @"Metal isn't supported by simulator");
  }
#endif

- (void)dealloc {
  [self dispose];
}

- (void)dispose {
  if (!self.name || !self.context) {
    return;
  }

  [self.context removeResource:self];
  [self lockTextureAndExecute:^{
    self->_pixelBuffer.reset(nullptr);
    self->_texture.reset(nullptr);

    if (self->_textureCache) {
      CVOpenGLESTextureCacheFlush(self->_textureCache.get(), 0);
      self->_textureCache.reset(nullptr);
    } else if (self->_name) {
      [self unbind];
      glDeleteTextures(1, &self->_name);
      LTGLCheckDbg(@"Error deleting memory mapped texture");
    }

    self.readSyncObject = nil;
    self.writeSyncObject = nil;
    self->_name = 0;
  }];
}

#pragma mark -
#pragma mark Abstract implementation
#pragma mark -

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
      [texture clearColor:self.fillColor];
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
  self.readSyncObject = [self createAndPushSyncObject];

  [self.lock unlock];
}

- (void)beginWritingWithGPU {
  [self.lock lock];
  self.fillColor = LTVector4::null();
}

- (void)endWritingWithGPU {
  self.writeSyncObject = [self createAndPushSyncObject];

  [self updateGenerationID];
  [self.lock unlock];
}

- (GLsync)createAndPushSyncObject {
  return glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
}

- (lt::Ref<CVPixelBufferRef>)pixelBuffer {
  [self lockTextureAndExecute:^{
    // Need to wait for both read and write syncs since returning a pixelbuffer can be used for both
    // reading or writing.
    [self waitForSyncObject:self.writeSyncObject];
    [self waitForSyncObject:self.readSyncObject];

    self.writeSyncObject = nil;
    self.readSyncObject = nil;
  }];

  return lt::Ref<CVPixelBufferRef>(CVPixelBufferRetain(_pixelBuffer.get()));
}

#if COREVIDEO_SUPPORTS_IOSURFACE
  - (id<MTLTexture>)mtlTextureWithDevice:(id<MTLDevice>)device {
    // Access to [self pixelBuffer] guarantee proper synchronization.
    lt::Ref<CVPixelBufferRef> pixelBuffer = [self pixelBuffer];
    IOSurfaceRef _Nullable iosurface = CVPixelBufferGetIOSurface(pixelBuffer.get());
    LTAssert(iosurface, @"Texture %@ must be backed by iosurface", self);

    auto descriptor =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.pixelFormat.mtlPixelFormat
                                                           width:self.size.width
                                                          height:self.size.height
                                                       mipmapped:NO];

    // Creating an MTLTexture from IOSurface is available from iOS 10 as a private API.
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wunguarded-availability-new"
    id<MTLTexture> mtlTexture = [device newTextureWithDescriptor:descriptor iosurface:iosurface
                                                           plane:0];
    #pragma clang diagnostic pop

    LTAssert(mtlTexture, @"Failed creating MTLTexture from %@, on device %@", self, device);
    return mtlTexture;
  }
#else
  - (id<MTLTexture>)mtlTextureWithDevice:(__unused id<MTLDevice>)device {
    LTAssert(NO, @"Metal isn't supported by simulator");
  }
#endif

#pragma mark -
#pragma mark Overridden methods
#pragma mark -

- (LTVector4s)pixelValues:(const std::vector<CGPoint> &)locations {
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

- (void)lockTextureAndExecute:(NS_NOESCAPE LTVoidBlock)block {
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

- (void)mappedImageForReading:(NS_NOESCAPE LTTextureMappedReadBlock)block {
  LTParameterAssert(block);

  [self mappedImageWithBlock:^(cv::Mat *mapped, BOOL isCopy) {
    block(*mapped, isCopy);
  } withFlags:kCVPixelBufferLock_ReadOnly];
}

- (void)mappedImageForWriting:(NS_NOESCAPE LTTextureMappedWriteBlock)block {
  self.fillColor = LTVector4::null();
  [self mappedImageWithBlock:block withFlags:0];
  [self updateGenerationID];
}

- (void)mappedImageWithBlock:(NS_NOESCAPE LTTextureMappedBlock)block
                   withFlags:(CVOptionFlags)lockFlags {
  LTParameterAssert(block);

  [self lockTextureAndExecute:^{
    LTAssert(self->_pixelBuffer, @"Pixel buffer must be created before calling mappedImage:");

    // GPU read sync is required only when mapping the texture for writing. There's no hazard when
    // mapping for reading since the texture is not modified.
    if (!(lockFlags & kCVPixelBufferLock_ReadOnly)) {
      [self waitForSyncObject:self.readSyncObject];
      self.readSyncObject = nil;
    }

    [self waitForSyncObject:self.writeSyncObject];
    self.writeSyncObject = nil;

    if (!CVPixelBufferIsPlanar(self->_pixelBuffer.get())) {
      LTCVPixelBufferImage(self->_pixelBuffer.get(), lockFlags, ^(cv::Mat *image) {
        block(image, NO);
      });
    } else {
      LTCVPixelBufferPlaneImage(self->_pixelBuffer.get(), self.planeIndex, lockFlags,
                                ^(cv::Mat *image) {
        block(image, NO);
      });
    }
  }];
}

- (void)waitForSyncObject:(nullable GLsync)sync {
  // According to \c glIsSync docs: "zero is not the name of a sync object". Therefore we can bail
  // out quickly by checking this specific value.
  if (!sync) {
    return;
  }

  if (!glIsSync(sync)) {
    return;
  }

  // While flushing is an expensive operation and should not be necessary at this point according to
  // the specification of glClientWaitSync(APPLE), there seems to be a bug in the implementation of
  // glClientWaitSync(APPLE) occurring on devices running iOS 10. Hence, we perform a manual
  // flushing.
  glFlush();

  static const GLuint64 kMaxTimeout = std::numeric_limits<GLuint64>::max();
  GLenum waitResult = glClientWaitSync(sync, GL_SYNC_FLUSH_COMMANDS_BIT, kMaxTimeout);

  LTAssert(waitResult != GL_TIMEOUT_EXPIRED_APPLE, @"Timed out while waiting for sync object");
  LTAssert(waitResult != GL_WAIT_FAILED_APPLE, @"Failed waiting on sync object");
}

- (void)setWriteSyncObject:(nullable GLsync)writeSyncObject {
  [self deleteSyncObjectIfExists:_writeSyncObject];
  _writeSyncObject = writeSyncObject;
}

- (void)setReadSyncObject:(nullable GLsync)readSyncObject {
  [self deleteSyncObjectIfExists:_readSyncObject];
  _readSyncObject = readSyncObject;
}

- (void)deleteSyncObjectIfExists:(nullable GLsync)sync {
  if (glIsSync(sync)) {
    glDeleteSync(sync);
  }
}

- (void)mappedCIImage:(NS_NOESCAPE LTTextureMappedCIImageBlock)block {
  LTParameterAssert(block);

  [self mappedImageForReading:^(const cv::Mat &, BOOL) {
    @autoreleasepool {
      CIImage *image = [[CIImage alloc] initWithCVPixelBuffer:self->_pixelBuffer.get() options:@{
        kCIImageColorSpace: [NSNull null]
      }];

      // In case the internal pixel format is BGRA, and since we are treating it as RGBA the image
      // needs to be swizzled so it can be correctly used.
      if (self.pixelFormat.ciFormatForCVPixelFormatType == kCIFormatBGRA8) {
        image = image.lt_swizzledImage;
      }

      block(image);
    }
  }];
}

- (void)drawWithCoreImage:(NS_NOESCAPE LTTextureCoreImageBlock)block {
  LTParameterAssert(block);

#if TARGET_OS_SIMULATOR
  // Simulator does not support rendering to certain target types of less than four channels, so
  // let the superclass handle this.
  [super drawWithCoreImage:block];
#else
  @autoreleasepool {
    __block CIImage * _Nullable image = block();
    if (!image) {
      return;
    }

    [self mappedImageForWriting:^(cv::Mat *, BOOL) {
      // In case the internal pixel format is BGRA, and since we are treating it as RGBA the image
      // needs to be swizzled so it will be correctly written.
      if (self.pixelFormat.ciFormatForCVPixelFormatType == kCIFormatBGRA8) {
        image = image.lt_swizzledImage;
      }

      CIContext *context = [CIContext lt_contextWithPixelFormat:(self.pixelFormat)];
      [context render:image toCVPixelBuffer:self->_pixelBuffer.get()
               bounds:CGRectFromSize(self.size) colorSpace:NULL];
    }];
  }
#endif
}

@end
