// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Protected.h"

#import "LTBoundaryCondition.h"
#import "LTCGExtensions.h"
#import "LTDevice.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLException.h"
#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTMathUtils.h"
#import "LTTextureContentsDataArchiver.h"

NS_ASSUME_NONNULL_BEGIN

LTTexturePrecision LTTexturePrecisionFromMatType(int type) {
  switch (CV_MAT_DEPTH(type)) {
    case CV_8U:
      return LTTexturePrecisionByte;
    case CV_16U:
      return LTTexturePrecisionHalfFloat;
    case CV_32F:
      return LTTexturePrecisionFloat;
    default:
      [LTGLException raise:kLTTextureUnsupportedFormatException
                    format:@"Invalid depth: %d, type: %d", CV_MAT_DEPTH(type), type];
      __builtin_unreachable();
  }
}

LTTexturePrecision LTTexturePrecisionFromMat(const cv::Mat &image) {
  return LTTexturePrecisionFromMatType(image.type());
}

LTTextureChannels LTTextureChannelsFromMatType(int type) {
  switch (CV_MAT_CN(type)) {
    case 1:
      return LTTextureChannelsOne;
    case 2:
      return LTTextureChannelsTwo;
    case 4:
      return LTTextureChannelsFour;
    default:
      [LTGLException raise:kLTTextureUnsupportedFormatException
                    format:@"Invalid number of channels: %d", CV_MAT_CN(type)];
      __builtin_unreachable();
  }
}

LTTextureChannels LTTextureChannelsFromMat(const cv::Mat &image) {
  return LTTextureChannelsFromMatType(image.type());
}

LTTextureFormat LTTextureFormatFromMatType(int type) {
  switch (CV_MAT_CN(type)) {
    case 1:
      if ([LTDevice currentDevice].supportsRGTextures) {
        return LTTextureFormatRed;
      } else {
        return LTTextureFormatLuminance;
      }
    case 2:
      if ([LTDevice currentDevice].supportsRGTextures) {
        return LTTextureFormatRG;
      } else {
        return LTTextureFormatRGBA;
      }
    case 4:
      return LTTextureFormatRGBA;
    default:
      [LTGLException raise:kLTTextureUnsupportedFormatException
                    format:@"Invalid number of channels: %d, type: %d", CV_MAT_CN(type), type];
      __builtin_unreachable();
  }
}

LTTextureFormat LTTextureFormatFromMat(const cv::Mat &image) {
  return LTTextureFormatFromMatType(image.type());
}

LTTextureChannels LTTextureChannelsFromFormat(LTTextureFormat format) {
  switch (format) {
    case LTTextureFormatRed:
    case LTTextureFormatLuminance:
      return LTTextureChannelsOne;
    case LTTextureFormatRG:
      return LTTextureChannelsTwo;
    case LTTextureFormatRGBA:
      return LTTextureChannelsFour;
  }
}

int LTMatDepthForPrecision(LTTexturePrecision precision) {
  switch (precision) {
    case LTTexturePrecisionByte:
      return CV_8U;
    case LTTexturePrecisionHalfFloat:
      return CV_16U;
    case LTTexturePrecisionFloat:
      return CV_32F;
  }
}

int LTMatTypeForPrecisionAndChannels(LTTexturePrecision precision, LTTextureChannels channels) {
  return CV_MAKETYPE(LTMatDepthForPrecision(precision), (int)channels);
}

int LTMatTypeForPrecisionAndFormat(LTTexturePrecision precision, LTTextureFormat format) {
  return CV_MAKETYPE(LTMatDepthForPrecision(precision), (int)LTTextureChannelsFromFormat(format));
}

static NSString *NSStringFromLTTexturePrecision(LTTexturePrecision precision) {
  switch (precision) {
    case LTTexturePrecisionByte:
      return @"LTTexturePrecisionByte";
    case LTTexturePrecisionFloat:
      return @"LTTexturePrecisionFloat";
    case LTTexturePrecisionHalfFloat:
      return @"LTTexturePrecisionHalfFloat";
  }
}

static NSString *NSStringFromLTTextureFormat(LTTextureFormat format) {
  switch (format) {
    case LTTextureFormatRed:
      return @"LTTextureFormatRed";
    case LTTextureFormatRG:
      return @"LTTextureFormatRG";
    case LTTextureFormatRGBA:
      return @"LTTextureFormatRGBA";
    case LTTextureFormatLuminance:
      return @"LTTextureFormatLuminance";
  }
}

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

/// While \c YES, the \c generationID property will not be updated.
@property (nonatomic) BOOL isGenerationIDLocked;

/// While \c YES, the \c fillColor property will not be updated.
@property (nonatomic) BOOL isFillColorLocked;

@end

@implementation LTTexture

#pragma mark -
#pragma mark Abstract methods
#pragma mark -

- (instancetype)initWithSize:(CGSize)size precision:(LTTexturePrecision)precision
                      format:(LTTextureFormat)format allocateMemory:(BOOL)allocateMemory {
  if (self = [super init]) {
    LTParameterAssert([self formatSupported:format],
                      @"Given texture format %d is not supported in this system", format);
    LTParameterAssert(std::floor(size) == size, @"Given size (%g, %g) is not integral",
                      size.width, size.height);
    LTParameterAssert(size.height > 0 && size.width > 0, @"Given size (%g, %g) has width or height "
                      "which are <= 0", size.width, size.height);

    _precision = precision;
    _format = format;
    _channels = LTTextureChannelsFromFormat(format);
    _size = size;
    _fillColor = LTVector4Null;
    _generationID = [NSUUID UUID].UUIDString;

    self.bindStateStack = [[NSMutableArray alloc] init];
    [self setDefaultValues];
    [self create:allocateMemory];
  }
  return self;
}

- (instancetype)initWithImage:(const cv::Mat &)image {
  if (self = [self initWithSize:CGSizeMake(image.cols, image.rows)
                      precision:LTTexturePrecisionFromMat(image)
                         format:LTTextureFormatFromMat(image)
                 allocateMemory:NO]) {
    [self load:image];
  }
  return self;
}

- (instancetype)initByteRGBAWithSize:(CGSize)size {
  return [self initWithSize:size precision:LTTexturePrecisionByte
                     format:LTTextureFormatRGBA allocateMemory:YES];
}

- (instancetype)initWithPropertiesOf:(LTTexture *)texture {
  return [self initWithSize:texture.size precision:texture.precision
                     format:texture.format allocateMemory:YES];
}

- (void)dealloc {
  [self destroy];
}

- (BOOL)formatSupported:(LTTextureFormat)format {
  switch (format) {
    case LTTextureFormatLuminance:
    case LTTextureFormatRGBA:
      return YES;
    case LTTextureFormatRed:
    case LTTextureFormatRG:
      return [LTDevice currentDevice].supportsRGTextures;
  }
}

- (void)setDefaultValues {
  _minFilterInterpolation = LTTextureInterpolationLinear;
  _magFilterInterpolation = LTTextureInterpolationLinear;
  _wrap = LTTextureWrapClamp;
  _maxMipmapLevel = 0;
}

- (void)create:(BOOL __unused)allocateMemory {
  LTAssert(NO, @"-[LTTexture create:] is an abstract method that should be overridden by "
           "subclasses");
}

- (void)destroy {
  LTAssert(NO, @"-[LTTexture destroy] is an abstract method that should be overridden by "
           "subclasses");
}

- (void)storeRect:(CGRect __unused)rect toImage:(cv::Mat __unused *)image {
  LTAssert(NO, @"-[LTTexture storeRect:toImage:] is an abstract method that should be overridden "
           "by subclasses");
}

- (void)loadRect:(CGRect __unused)rect fromImage:(const cv::Mat __unused &)image {
  LTAssert(NO, @"-[LTTexture loadRect:fromImage] is an abstract method that should be overridden "
           "by subclasses");
}

- (LTTexture *)clone {
  LTAssert(NO, @"-[LTTexture clone] is an abstract method that should be overridden by subclasses");
  __builtin_unreachable();
}

- (void)cloneTo:(LTTexture __unused *)texture {
  LTAssert(NO, @"-[LTTexture cloneTo:] is an abstract method that should be overridden by "
           "subclasses");
}

- (void)beginReadFromTexture {
  LTAssert(NO, @"-[LTTexture beginReadFromTexture] is an abstract method that should be "
           "overridden by subclasses");
}

- (void)endReadFromTexture {
  LTAssert(NO, @"-[LTTexture endReadFromTexture] is an abstract method that should be overridden "
           "by subclasses");
}

- (void)beginWriteToTexture {
  LTAssert(NO, @"-[LTTexture beginWriteToTexture] is an abstract method that should be overridden "
           "by subclasses");
}

- (void)endWriteToTexture {
  LTAssert(NO, @"-[LTTexture endWriteToTexture] is an abstract method that should be overridden "
           "by subclasses");
}

#pragma mark -
#pragma mark LTTexture implemented methods
#pragma mark -

- (void)load:(const cv::Mat &)image {
  [self loadRect:CGRectMake(0, 0, image.cols, image.rows) fromImage:image];
}

- (void)readFromTexture:(LTVoidBlock)block {
  LTParameterAssert(block);
  [self beginReadFromTexture];
  block();
  [self endReadFromTexture];
}

- (void)writeToTexture:(LTVoidBlock)block {
  LTParameterAssert(block);
  [self beginWriteToTexture];
  block();
  [self endWriteToTexture];
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

- (void)bindAndExecute:(LTVoidBlock)block {
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

- (void)mappedImageForReading:(LTTextureMappedReadBlock)block {
  LTParameterAssert(block);

  cv::Mat image([self image]);
  block(image, YES);
}

- (void)mappedImageForWriting:(LTTextureMappedWriteBlock)block {
  LTParameterAssert(block);

  cv::Mat image([self image]);
  self.fillColor = LTVector4Null;
  block(&image, YES);

  // User wrote data to image, so it must be uploaded back to the GPU.
  [self load:image];
}

- (void)mappedCGImage:(LTTextureMappedCGImageBlock)block {
  LTParameterAssert(block);

  [self mappedImageForReading:^(const cv::Mat &mapped, BOOL isCopy) {
    NSUInteger length = mapped.rows * mapped.step[0];
    NSData *data = [NSData dataWithBytesNoCopy:mapped.data length:length freeWhenDone:NO];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);

    CGColorSpaceRef colorSpace = [self newColorSpaceForMat:mapped];
    CGBitmapInfo bitmapInfo = [self bitmapInfoForMat:mapped];

    CGImageRef imageRef = CGImageCreate(mapped.cols, mapped.rows,
                                        8 * mapped.elemSize1(), 8 * mapped.elemSize(),
                                        mapped.step[0], colorSpace, bitmapInfo,
                                        provider, NULL, YES, kCGRenderingIntentDefault);
    block(imageRef, isCopy);

    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
  }];
}

- (void)drawWithCoreGraphics:(LTTextureCoreGraphicsBlock)block {
  LTParameterAssert(block);

  [self mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    size_t bitsPerComponent = mapped->elemSize1() * 8;
    CGColorSpaceRef colorSpace = [self newColorSpaceForMat:*mapped];
    CGBitmapInfo bitmapInfo = [self bitmapInfoForMat:*mapped];

    CGContextRef context = CGBitmapContextCreate(mapped->data, self.size.width, self.size.height,
                                                 bitsPerComponent, mapped->step[0], colorSpace,
                                                 bitmapInfo);

    // Flip context since CoreGraphics' origin is bottom-left.
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0,
                                                           self.size.height);
    CGContextConcatCTM(context, flipVertical);

    block(context);

    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
  }];
}

- (CGColorSpaceRef)newColorSpaceForMat:(const cv::Mat &)mat {
  switch (mat.channels()) {
    case 1:
      return CGColorSpaceCreateDeviceGray();
      break;
    case 4:
      return CGColorSpaceCreateDeviceRGB();
      break;
    default:
      LTAssert(NO, @"Texture has %d channels, which is not supported for a CGBitmapContext",
               mat.channels());
  }
}

- (CGBitmapInfo)bitmapInfoForMat:(const cv::Mat &)mat {
  switch (mat.channels()) {
    case 1:
      return kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    case 4:
      return kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault;
    default:
      LTAssert(NO, @"Texture has %d channels, which is not supported for a CGBitmapContext",
               mat.channels());
  }
}

- (LTVector4)pixelValue:(CGPoint)location {
  cv::Mat image = [self imageWithRect:CGRectMake(location.x, location.y, 1, 1)];
  return LTPixelValueFromImage(image, {0, 0});
}

- (LTVector4s)pixelValues:(const CGPoints &)locations {
  // This is naive implementation which calls -[LTTexture pixelValue:] for each given pixel.
  LTVector4s values(locations.size());

  for (CGPoints::size_type i = 0; i < locations.size(); ++i) {
    // Use boundary conditions similar to Matlab's 'symmetric'.
    LTVector2 location = [LTSymmetricBoundaryCondition
                           boundaryConditionForPoint:LTVector2(locations[i].x, locations[i].y)
                           withSignalSize:cv::Size2i(self.size.width, self.size.height)];
    values[i] = [self pixelValue:CGPointMake(floorf(location.x), floorf(location.y))];
  }

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

- (void)executeAndPreserveParameters:(LTVoidBlock)execute {
  LTParameterAssert(execute);
  LTTextureParameters *parameters = [self currentParameters];
  execute();
  [self setCurrentParameters:parameters];
}

- (void)clearWithColor:(LTVector4)color {
  self.fillColor = color;
  [self performWithoutUpdatingFillColor:^{
    for (GLint i = 0; i <= self.maxMipmapLevel; ++i) {
      LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:self level:i];
      [fbo clearWithColor:color];
    }
  }];
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

- (void)performWithoutUpdatingGenerationID:(LTVoidBlock)block {
  LTParameterAssert(block);
  BOOL locked = self.isGenerationIDLocked;
  self.isGenerationIDLocked = YES;
  block();
  self.isGenerationIDLocked = locked;
}

- (void)performWithoutUpdatingFillColor:(LTVoidBlock)block {
  LTParameterAssert(block);
  BOOL locked = self.isFillColorLocked;
  self.isFillColorLocked = YES;
  block();
  self.isFillColorLocked = locked;
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

- (void)setFillColor:(LTVector4)fillColor {
  if (_fillColor == fillColor || self.isFillColorLocked) {
    return;
  }

  _fillColor = fillColor;
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
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL_APPLE, maxMipmapLevel);
  }];

  _maxMipmapLevel = maxMipmapLevel;
}

- (int)matType {
  return LTMatTypeForPrecisionAndChannels(self.precision, self.channels);
}

#pragma mark -
#pragma mark Debugging
#pragma mark -

- (NSString *)debugDescription {
  return [NSString stringWithFormat:@"<%@: %p, size: %@, precision: %@, format: %@, "
          "generation ID: %lu>", [self class], self, NSStringFromCGSize(self.size),
          NSStringFromLTTexturePrecision(self.precision), NSStringFromLTTextureFormat(self.format),
          (unsigned long)self.generationID];
}

- (id)debugQuickLookObject {
  return [[[LTImage alloc] initWithMat:[self image] copy:NO] UIImage];
}

@end

NS_ASSUME_NONNULL_END
