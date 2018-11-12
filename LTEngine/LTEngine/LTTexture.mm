// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

#import <Metal/Metal.h>

#import "CIContext+PixelFormat.h"
#import "CIImage+Swizzle.h"
#import "CVPixelBuffer+LTEngine.h"
#import "LTBoundaryCondition.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLContext+Internal.h"
#import "LTImage.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Protected.h"
#import "LTTextureContentsDataArchiver.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTTextureParameters
#pragma mark -

@interface LTTextureParameters : NSObject

@property (nonatomic) LTTextureInterpolation minFilterInterpolation;
@property (nonatomic) LTTextureInterpolation magFilterInterpolation;
@property (nonatomic) LTTextureWrap wrap;

@end

@implementation LTTextureParameters
@end

#pragma mark -
#pragma mark LTTextureBindState
#pragma mark -

@interface LTTextureBindState : NSObject

/// The active texture unit while binding the texture.
@property (nonatomic) GLint boundTextureUnit;

/// Set to the previously bound texture, or \c 0 if the texture is not bound.
@property (nonatomic) GLint previousTexture;

@end

@implementation LTTextureBindState
@end

#pragma mark -
#pragma mark LTTexture
#pragma mark -

@interface LTTexture ()

/// Stack which holds the bind state of the texture, for each active bind.
@property (nonatomic) NSMutableArray *bindStateStack;

/// OpenGL identifier of the texture.
@property (readwrite, nonatomic) GLuint name;

/// Pixel format of the attachable.
@property (strong, readwrite, nonatomic) LTGLPixelFormat *pixelFormat;

/// Size of the attachable.
@property (nonatomic) CGSize size;

/// While \c YES, the \c generationID property will not be updated.
@property (nonatomic) BOOL isGenerationIDLocked;

@end

@implementation LTTexture

@synthesize context = _context;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
              maxMipmapLevel:(GLint)maxMipmapLevel
              allocateMemory:(BOOL __unused)allocateMemory {
  if (self = [super init]) {
    _context = [LTGLContext currentContext];
    [self verifyPixelFormat:pixelFormat];
    LTParameterAssert(std::floor(size) == size, @"Given size (%g, %g) is not integral",
                      size.width, size.height);
    LTParameterAssert(size.height > 0 && size.width > 0, @"Given size (%g, %g) has width or height "
                      "which are <= 0", size.width, size.height);
    LTParameterAssert(maxMipmapLevel >= 0, @"Given maxMipmapLevel (%ld) is negative",
                      (long)maxMipmapLevel);

    _pixelFormat = pixelFormat;
    _size = size;
    _maxMipmapLevel = maxMipmapLevel;
    _fillColor = LTVector4::null();
    _generationID = [NSUUID UUID].UUIDString;

    self.bindStateStack = [[NSMutableArray alloc] init];
    [self setDefaultValues];
  }
  return self;
}

- (instancetype)initWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
              allocateMemory:(BOOL)allocateMemory {
  return [self initWithSize:size pixelFormat:pixelFormat maxMipmapLevel:0
             allocateMemory:allocateMemory];
}

- (instancetype)initWithImage:(const cv::Mat &)image {
  if (self = [self initWithSize:CGSizeMake(image.cols, image.rows)
                    pixelFormat:[[LTGLPixelFormat alloc] initWithMatType:image.type()]
                 allocateMemory:NO]) {
    [self load:image];
  }
  return self;
}

- (instancetype)initWithPropertiesOf:(LTTexture *)texture {
  return [self initWithSize:texture.size pixelFormat:texture.pixelFormat
             maxMipmapLevel:texture.maxMipmapLevel
             allocateMemory:YES];
}

- (void)verifyPixelFormat:(LTGLPixelFormat *)pixelFormat {
  LTParameterAssert(pixelFormat);

  LTParameterAssert(pixelFormat.format != LTGLInvalidEnum,
                    @"Pixel format %@ doesn't have a matching GL format", pixelFormat);
  LTParameterAssert(pixelFormat.textureInternalFormat != LTGLInvalidEnum,
                    @"Pixel format %@ doesn't have a matching GL internal format", pixelFormat);
  LTParameterAssert(pixelFormat.precision != LTGLInvalidEnum,
                    @"Pixel format %@ doesn't have a matching GL precision", pixelFormat);
}

- (void)setDefaultValues {
  _minFilterInterpolation = LTTextureInterpolationLinear;
  _magFilterInterpolation = LTTextureInterpolationLinear;
  _wrap = LTTextureWrapClamp;
}

#pragma mark -
#pragma mark Abstract methods
#pragma mark -

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

- (instancetype)initWithMTLTexture:(__unused id<MTLTexture>)texture {
  LTMethodNotImplemented();
}

- (instancetype)initWithPixelBuffer:(__unused CVPixelBufferRef)pixelBuffer {
  LTMethodNotImplemented();
}

#pragma clang diagnostic pop

- (void)dispose {
  LTMethodNotImplemented();
}

- (void)storeRect:(CGRect __unused)rect toImage:(cv::Mat __unused *)image {
  LTMethodNotImplemented();
}

- (void)loadRect:(CGRect __unused)rect fromImage:(const cv::Mat __unused &)image {
  LTMethodNotImplemented();
}

- (LTTexture *)clone {
  LTMethodNotImplemented();
}

- (void)cloneTo:(LTTexture __unused *)texture {
  LTMethodNotImplemented();
}

- (lt::Ref<CVPixelBufferRef>)pixelBuffer {
  LTMethodNotImplemented();
}

- (id<MTLTexture>)mtlTextureWithDevice:(id<MTLDevice> __unused)device {
  LTMethodNotImplemented();
}

#pragma mark -
#pragma mark LTTexture implemented methods
#pragma mark -

- (void)load:(const cv::Mat &)image {
  [self loadRect:CGRectMake(0, 0, image.cols, image.rows) fromImage:image];
}

- (void)bind {
  LTTextureBindState *currentState = [self currentBindState];
  if ([self alreadyBoundToTextureUnit:currentState.boundTextureUnit]) {
    return;
  }

  [self.bindStateStack addObject:currentState];
}

- (void)unbind {
  if (!self.bindStateStack.count) {
    return;
  }

  LTTextureBindState *state = [self.bindStateStack lastObject];
  [self.bindStateStack removeLastObject];

  [self restoreBindState:state];
}

- (LTTextureBindState *)currentBindState {
  LTTextureBindState *state = [[LTTextureBindState alloc] init];

  GLint boundTextureUnit, previousTexture;
  glGetIntegerv(GL_ACTIVE_TEXTURE, &boundTextureUnit);
  glGetIntegerv(GL_TEXTURE_BINDING_2D, &previousTexture);
  glBindTexture(GL_TEXTURE_2D, self.name);

  state.boundTextureUnit = boundTextureUnit;
  state.previousTexture = previousTexture;

  return state;
}

- (void)restoreBindState:(LTTextureBindState *)state {
  glActiveTexture(state.boundTextureUnit);
  glBindTexture(GL_TEXTURE_2D, state.previousTexture);
}

- (void)bindAndExecute:(NS_NOESCAPE LTVoidBlock)block {
  LTParameterAssert(block);
  if ([self alreadyBoundToCurrentTextureUnit]) {
    block();
  } else {
    [self bind];
    block();
    [self unbind];
  }
}

- (BOOL)alreadyBoundToCurrentTextureUnit {
  GLint boundTextureUnit;
  glGetIntegerv(GL_ACTIVE_TEXTURE, &boundTextureUnit);
  return [self alreadyBoundToTextureUnit:boundTextureUnit];
}

- (BOOL)alreadyBoundToTextureUnit:(GLint)textureUnit {
  for (LTTextureBindState *state in self.bindStateStack) {
    if (state.boundTextureUnit == textureUnit) {
      return YES;
    }
  }
  return NO;
}

- (void)mappedImageForReading:(NS_NOESCAPE LTTextureMappedReadBlock)block {
  LTParameterAssert(block);

  cv::Mat image([self image]);
  block(image, YES);
}

- (void)mappedImageForWriting:(NS_NOESCAPE LTTextureMappedWriteBlock)block {
  LTParameterAssert(block);

  cv::Mat image([self image]);
  self.fillColor = LTVector4::null();
  block(&image, YES);

  // User wrote data to image, so it must be uploaded back to the GPU.
  [self load:image];
}

- (void)mappedCGImage:(NS_NOESCAPE LTTextureMappedCGImageBlock)block {
  LTParameterAssert(block);

  [self mappedImageForReading:^(const cv::Mat &mapped, BOOL isCopy) {
    NSUInteger length = mapped.rows * mapped.step[0];
    NSData *data = [NSData dataWithBytesNoCopy:mapped.data length:length freeWhenDone:NO];
    lt::Ref<CGDataProviderRef> provider(CGDataProviderCreateWithCFData((CFDataRef)data));

    lt::Ref<CGColorSpaceRef> colorSpace([self newColorSpaceForMat:mapped]);
    CGBitmapInfo bitmapInfo = [self bitmapInfoForMat:mapped];

    lt::Ref<CGImageRef> image(CGImageCreate(mapped.cols, mapped.rows,
                                            8 * mapped.elemSize1(), 8 * mapped.elemSize(),
                                            mapped.step[0], colorSpace.get(), bitmapInfo,
                                            provider.get(), NULL, YES, kCGRenderingIntentDefault));
    block(image.get(), isCopy);
  }];
}

- (void)drawWithCoreGraphics:(NS_NOESCAPE LTTextureCoreGraphicsBlock)block {
  LTParameterAssert(block);

  [self mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    size_t bitsPerComponent = mapped->elemSize1() * 8;
    lt::Ref<CGColorSpaceRef> colorSpace([self newColorSpaceForMat:*mapped]);
    CGBitmapInfo bitmapInfo = [self bitmapInfoForMat:*mapped];

    lt::Ref<CGContextRef> context(
      CGBitmapContextCreate(mapped->data, self.size.width, self.size.height,
                            bitsPerComponent, mapped->step[0], colorSpace.get(), bitmapInfo)
    );

    // Flip context since CoreGraphics' origin is bottom-left.
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0,
                                                           self.size.height);
    CGContextConcatCTM(context.get(), flipVertical);

    block(context.get());
  }];
}

- (CGColorSpaceRef)newColorSpaceForMat:(const cv::Mat &)mat {
  switch (mat.channels()) {
    case 1:
      return CGColorSpaceCreateDeviceGray();
    case 4:
      return CGColorSpaceCreateDeviceRGB();
    default:
      LTAssert(NO, @"Texture has %d channels, which is not supported for a CGBitmapContext",
               mat.channels());
  }
}

- (CGBitmapInfo)bitmapInfoForMat:(const cv::Mat &)mat {
  CGBitmapInfo bitmapFlags = 0;

  switch (mat.channels()) {
    case 1:
      bitmapFlags |= kCGImageAlphaNone;
      break;
    case 4:
      bitmapFlags |= kCGImageAlphaPremultipliedLast;
      break;
    default:
      LTAssert(NO, @"Texture has %d channels, which is not supported for a CGBitmapContext",
               mat.channels());
  }

  if (mat.depth() == CV_16F) {
    // CGContext initializes successfully, when running on simulator and device, with float
    // components only with kCGBitmapByteOrder16Little set. This requirement is documented only in
    // the reported error (which occurs when trying to initialize the context with default byte
    // ordering).
    bitmapFlags |= kCGBitmapFloatComponents | kCGBitmapByteOrder16Little;
  } else {
    bitmapFlags |= kCGBitmapByteOrderDefault;
  }

  return bitmapFlags;
}

- (void)mappedCIImage:(NS_NOESCAPE LTTextureMappedCIImageBlock)block {
  LTParameterAssert(block);

  [self mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    @autoreleasepool {
      auto pixelBuffer(LTCVPixelBufferCreate(mapped.cols, mapped.rows,
                                             self.pixelFormat.cvPixelFormatType));

      LTCVPixelBufferImageForWriting(pixelBuffer.get(), ^(cv::Mat *image) {
        mapped.copyTo(*image);
      });

      CIImage *image = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer.get() options:@{
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

  @autoreleasepool {
    CIImage * _Nullable image = block();
    if (!image) {
      return;
    }

    // In case the target pixel format is BGRA, and since we are treating it as RGBA the image
    // needs to be swizzled so it will be correctly written.
    if (self.pixelFormat.ciFormatForCVPixelFormatType == kCIFormatBGRA8) {
      image = image.lt_swizzledImage;
    }

    OSType cvPixelFormatType = self.pixelFormat.cvPixelFormatType;

#if TARGET_OS_SIMULATOR
    // Simulator does not support rendering to certain target types of less than four channels, so
    // we'll render to 4 channels in this scenario, and take only the required channels later on.
    if ([self.pixelFormat isEqual:$(LTGLPixelFormatR8Unorm)]) {
      cvPixelFormatType = $(LTGLPixelFormatRGBA8Unorm).cvPixelFormatType;
    }
#endif

    __block auto pixelBuffer(LTCVPixelBufferCreate(self.size.width, self.size.height,
                                                   cvPixelFormatType));

    CIContext *context = [CIContext lt_contextWithPixelFormat:(self.pixelFormat)];
    [context render:image toCVPixelBuffer:pixelBuffer.get()
             bounds:CGRectFromSize(self.size) colorSpace:NULL];

    [self mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      LTCVPixelBufferImageForReading(pixelBuffer.get(), ^(const cv::Mat &image) {
#if TARGET_OS_SIMULATOR
        std::vector<int> fromTo;
        for (int i = 0; i < mapped->channels(); ++i) {
          fromTo.push_back(i);
          fromTo.push_back(i);
        }
        cv::mixChannels(&image, 1, mapped, 1, fromTo.data(), mapped->channels());
#else
        image.copyTo(*mapped);
#endif
      });
    }];
  }
}

- (LTVector4)pixelValue:(CGPoint)location {
  cv::Point2i samplingPoint = [self samplingPointsFromLocations:{location}].front();
  cv::Mat image = [self imageWithRect:CGRectMake(samplingPoint.x, samplingPoint.y, 1, 1)];
  return LTPixelValueFromImage(image, {0, 0});
}

- (LTTextureSamplingPoints)samplingPointsFromLocations:(const std::vector<CGPoint> &)locations {
  LTTextureSamplingPoints samplingPoints(locations.size());

  std::transform(locations.cbegin(), locations.cend(), samplingPoints.begin(),
                 [self](CGPoint location) {
                   // Use boundary conditions similar to Matlab's 'symmetric'.
                   LTVector2 boundedLocation = [LTSymmetricBoundaryCondition
                                                boundaryConditionForPoint:LTVector2(location)
                                                withSignalSize:self.size];
                   return [self pixelSamplingPointWithBoundedLocation:boundedLocation];
                 });

  return samplingPoints;
}

- (cv::Point2i)pixelSamplingPointWithBoundedLocation:(LTVector2)position {
  int x = std::floor(position.x);
  int y = std::floor(position.y);

  // Edge case where sampling position is exactly at the edges of the texture.
  if (x == self.size.width && self.size.width) {
    x -= 1;
  }
  if (y == self.size.height && self.size.height) {
    y -= 1;
  }

  return cv::Point2i(x, y);
}

- (LTVector4s)pixelValues:(const std::vector<CGPoint> &)locations {
  // This is naive implementation which calls -[LTTexture pixelValue:] for each given pixel.
  LTVector4s values(locations.size());

  std::transform(locations.cbegin(), locations.cend(), values.begin(), [&](const CGPoint location) {
    return [self pixelValue:location];
  });

  return values;
}

/// Returns a \c cv::Mat with the current texture. This is an expensive operation, that should be
/// avoided when possible. The resulting \c cv::Mat element type will be set to the texture's
/// precision.
- (cv::Mat)imageWithRect:(CGRect)rect {
  cv::Mat image;
  [self storeRect:rect toImage:&image];
  return image;
}

- (cv::Mat)image {
  cv::Mat image;
  [self storeRect:CGRectMake(0, 0, self.size.width, self.size.height) toImage:&image];
  return image;
}

- (void)executeAndPreserveParameters:(NS_NOESCAPE LTVoidBlock)execute {
  LTParameterAssert(execute);
  LTTextureParameters *parameters = [self currentParameters];
  execute();
  [self setCurrentParameters:parameters];
}

- (void)clearColor:(LTVector4)color {
  // Set the fillColor first to avoid it changing multiple times across the clearing process.
  self.fillColor = color;

  for (GLint i = 0; i <= self.maxMipmapLevel; ++i) {
    LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:self level:i];
    [fbo clearColor:color];
  }
}

#pragma mark -
#pragma mark Storing and fetching internal parameters
#pragma mark -

- (LTTextureParameters *)currentParameters {
  LTTextureParameters *parameters = [[LTTextureParameters alloc] init];
  parameters.minFilterInterpolation = self.minFilterInterpolation;
  parameters.magFilterInterpolation = self.magFilterInterpolation;
  parameters.wrap = self.wrap;
  return parameters;
}

- (void)setCurrentParameters:(LTTextureParameters *)parameters {
  [self bindAndExecute:^{
    self.minFilterInterpolation = parameters.minFilterInterpolation;
    self.magFilterInterpolation = parameters.magFilterInterpolation;
    self.wrap = parameters.wrap;
  }];
}

#pragma mark -
#pragma mark Utility methods
#pragma mark -

- (BOOL)inTextureRect:(CGRect)rect {
  CGRect texture = CGRectMake(0, 0, self.size.width, self.size.height);
  return CGRectContainsRect(texture, rect);
}

- (void)updateGenerationID {
  self.generationID = [NSUUID UUID].UUIDString;
}

- (void)performWithoutUpdatingGenerationID:(NS_NOESCAPE LTVoidBlock)block {
  LTParameterAssert(block);
  BOOL locked = self.isGenerationIDLocked;
  self.isGenerationIDLocked = YES;
  block();
  self.isGenerationIDLocked = locked;
}

#pragma mark -
#pragma mark LTFboAttachable
#pragma mark -

- (LTFboAttachableType)attachableType {
  return LTFboAttachableTypeTexture2D;
}

- (void)writeToAttachableWithBlock:(NS_NOESCAPE LTVoidBlock)block {
  LTParameterAssert(block);
  [self beginWritingWithGPU];
  block();
  [self endWritingWithGPU];
}

- (void)clearAttachableWithColor:(LTVector4)color block:(NS_NOESCAPE LTVoidBlock)block {
  [self writeToAttachableWithBlock:block];

  // Not a mipmap - fill color applies to the entire texture.
  if (!self.maxMipmapLevel) {
    self.fillColor = color;
    return;
  }

  // Mipmap - unset fill color if one of the levels were cleared with a different color than the
  // current fill color.
  if (self.fillColor != color) {
    self.fillColor = LTVector4::null();
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setGenerationID:(id)generationID {
  if (_generationID == generationID || [_generationID isEqual:generationID] ||
      self.isGenerationIDLocked) {
    return;
  }

  _generationID = generationID;
}

- (void)setMinFilterInterpolation:(LTTextureInterpolation)minFilterInterpolation {
  if (!self.name) {
    return;
  }

  if (!self.maxMipmapLevel) {
    LTAssert(minFilterInterpolation == LTTextureInterpolationNearest ||
             minFilterInterpolation == LTTextureInterpolationLinear,
             @"Min filter interpolation for mipmaps is valid for mipmap textures only");
  }

  [self bindAndExecute:^{
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilterInterpolation);
  }];

  _minFilterInterpolation = minFilterInterpolation;
}

- (void)setMagFilterInterpolation:(LTTextureInterpolation)magFilterInterpolation {
  if (!self.name) {
    return;
  }

  LTAssert(magFilterInterpolation == LTTextureInterpolationNearest ||
           magFilterInterpolation == LTTextureInterpolationLinear,
           @"Mag filter interpolation must be nearest or linear only");

  [self bindAndExecute:^{
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilterInterpolation);
  }];

  _magFilterInterpolation = magFilterInterpolation;
}

- (void)setWrap:(LTTextureWrap)wrap {
  if (!self.name) {
    return;
  }

  // When changing the mode to repeat, make sure the texture is POT.
  if (wrap == LTTextureWrapRepeat && !LTIsPowerOfTwo(self.size)) {
    LogWarning(@"Trying to change texture wrap method to repeat for NPOT texture");
    return;
  }

  [self bindAndExecute:^{
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap);
  }];

  _wrap = wrap;
}

- (void)setMaxMipmapLevel:(GLint)maxMipmapLevel {
  if (!self.name) {
    return;
  }

  [self bindAndExecute:^{
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, maxMipmapLevel);
  }];

  _maxMipmapLevel = maxMipmapLevel;
}

- (LTGLPixelComponents)components {
  return self.pixelFormat.components;
}

- (LTGLPixelDataType)dataType {
  return self.pixelFormat.dataType;
}

- (int)matType {
  return self.pixelFormat.matType;
}

#pragma mark -
#pragma mark Debugging
#pragma mark -

- (NSString *)debugDescription {
  return [NSString stringWithFormat:@"<%@: %p, size: %@, pixelFormat: %@, "
          "generation ID: %@>", [self class], self, NSStringFromCGSize(self.size),
          self.pixelFormat.name, self.generationID];
}

- (id)debugQuickLookObject {
  return [[[LTImage alloc] initWithMat:[self image] copy:NO] UIImage];
}

@end

NS_ASSUME_NONNULL_END
