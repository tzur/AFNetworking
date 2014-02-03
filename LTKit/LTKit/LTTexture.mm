// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

#import "LTBoundaryCondition.h"
#import "LTGLException.h"
#import "LTImage.h"

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
      return LTTextureChannelsR;
    case 2:
      return LTTextureChannelsRG;
    case 4:
      return LTTextureChannelsRGBA;
    default:
      [LTGLException raise:kLTTextureUnsupportedFormatException
                    format:@"Invalid number of channels: %d, type: %d", CV_MAT_CN(type), type];
      __builtin_unreachable();
  }
}

LTTextureChannels LTTextureChannelsFromMat(const cv::Mat &image) {
  return LTTextureChannelsFromMatType(image.type());
}

int LTNumberOfChannelsForChannels(LTTextureChannels channels) {
  switch (channels) {
    case LTTextureChannelsR:
      return 1;
    case LTTextureChannelsRG:
      return 2;
    case LTTextureChannelsRGBA:
      return 4;
  }
}

int LTMatTypeForPrecisionAndChannels(LTTexturePrecision precision, LTTextureChannels channels) {
  int numChannels = LTNumberOfChannelsForChannels(channels);
  switch (precision) {
    case LTTexturePrecisionByte:
      return CV_MAKETYPE(CV_8U, numChannels);
    case LTTexturePrecisionHalfFloat:
      return CV_MAKETYPE(CV_16U, numChannels);
    case LTTexturePrecisionFloat:
      return CV_MAKETYPE(CV_32F, numChannels);
  }
}

#pragma mark -
#pragma mark LTTextureParameters
#pragma mark -

@interface LTTextureParameters : NSObject

@property (nonatomic) LTTextureInterpolation minFilterInterpolation;
@property (nonatomic) LTTextureInterpolation magFilterInterpolation;
@property (nonatomic) LTTextureWrap wrap;
@property (nonatomic) GLint maxMipmapLevel;

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

/// Type of \c cv::Mat according to the current \c precision of the texture.
@property (readonly, nonatomic) int matType;

/// OpenGL identifier of the texture.
@property (readwrite, nonatomic) GLuint name;

@end

@implementation LTTexture

#pragma mark -
#pragma mark Abstract methods
#pragma mark -

- (id)initWithSize:(CGSize)size precision:(LTTexturePrecision)precision
          channels:(LTTextureChannels)channels allocateMemory:(BOOL)allocateMemory {
  if (self = [super init]) {
    _precision = precision;
    _channels = channels;
    _size = size;

    self.bindStateStack = [[NSMutableArray alloc] init];
    [self setDefaultValues];
    [self create:allocateMemory];
  }
  return self;
}

- (id)initWithImage:(const cv::Mat &)image {
  if (self = [self initWithSize:CGSizeMake(image.cols, image.rows)
                      precision:LTTexturePrecisionFromMat(image)
                       channels:LTTextureChannelsFromMat(image)
                 allocateMemory:NO]) {
    [self load:image];
  }
  return self;
}

- (id)initByteRGBAWithSize:(CGSize)size {
  return [self initWithSize:size precision:LTTexturePrecisionByte
                   channels:LTTextureChannelsRGBA allocateMemory:YES];
}

- (id)initWithPropertiesOf:(LTTexture *)texture {
  return [self initWithSize:texture.size precision:texture.precision
                   channels:texture.channels allocateMemory:YES];
}

- (void)dealloc {
  [self destroy];
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

- (void)mappedImage:(LTTextureMappedBlock)block {
  LTParameterAssert(block);

  cv::Mat image([self image]);
  block(image, YES);
  [self load:image];
}

- (GLKVector4)pixelValue:(CGPoint)location {
  cv::Mat image = [self imageWithRect:CGRectMake(location.x, location.y, 1, 1)];
  return [self pixelValueFromImage:image location:{0, 0}];
}

- (GLKVector4)pixelValueFromImage:(const cv::Mat &)image location:(cv::Point2i)location {
  // Reading half-float is currently not supported.
  // TODO: (yaron) implement a half-float <--> float converter when needed.

  switch (image.type()) {
    case CV_8U: {
      uchar value = image.at<uchar>(location.y, location.x);
      return {{value / 255.f, 0.f, 0.f, 0.f}};
    }
    case CV_8UC4: {
      cv::Vec4b value = image.at<cv::Vec4b>(location.y, location.x);
      return {{value(0) / 255.f, value(1) / 255.f, value(2) / 255.f, value(3) / 255.f}};
    }
    case CV_32F: {
      float value = image.at<float>(location.y, location.x);
      return {{value, 0, 0, 0}};
    }
    case CV_32FC4: {
      cv::Vec4f value = image.at<cv::Vec4f>(location.y, location.x);
      return {{value(0), value(1), value(2), value(3)}};
    }
    default:
      [LTGLException raise:kLTTextureUnsupportedFormatException
                    format:@"Unsupported matrix type: %d", image.type()];
      __builtin_unreachable();
  }
}

- (GLKVector4s)pixelValues:(const CGPoints &)locations {
  // This is naive implementation which calls -[LTTexture pixelValue:] for each given pixel.
  GLKVector4s values(locations.size());

  for (CGPoints::size_type i = 0; i < locations.size(); ++i) {
    // Use boundary conditions similar to Matlab's 'symmetric'.
    GLKVector2 location = [LTSymmetricBoundaryCondition
                           boundaryConditionForPoint:GLKVector2Make(locations[i].x, locations[i].y)
                           withSignalSize:cv::Size2i(self.size.width, self.size.height)];
    values[i] = [self pixelValue:CGPointMake(floorf(location.x), floorf(location.y))];
  }

  return values;
}

/// Returns a \c cv::Mat with the current texture. This is an expensive operation, that should be
/// avoided when possible. The resulting \c cv::Mat element type will be set to the texture's
/// precision.
- (cv::Mat)imageWithRect:(CGRect)rect {
  cv::Mat image(rect.size.height, rect.size.width, self.matType);

  [self storeRect:rect toImage:&image];
  
  return image;
}

- (cv::Mat)image {
  cv::Mat image(self.size.height, self.size.width, self.matType);
  
  [self storeRect:CGRectMake(0, 0, self.size.width, self.size.height) toImage:&image];

  return image;
}

- (void)executeAndPreserveParameters:(LTVoidBlock)execute {
  LTParameterAssert(execute);
  LTTextureParameters *parameters = [self currentParameters];
  execute();
  [self setCurrentParameters:parameters];
}

#pragma mark -
#pragma mark Storing and fetching internal parameters
#pragma mark -

- (LTTextureParameters *)currentParameters {
  LTTextureParameters *parameters = [[LTTextureParameters alloc] init];
  parameters.minFilterInterpolation = self.minFilterInterpolation;
  parameters.magFilterInterpolation = self.magFilterInterpolation;
  parameters.wrap = self.wrap;
  parameters.maxMipmapLevel = self.maxMipmapLevel;
  return parameters;
}

- (void)setCurrentParameters:(LTTextureParameters *)parameters {
  [self bindAndExecute:^{
    self.minFilterInterpolation = parameters.minFilterInterpolation;
    self.magFilterInterpolation = parameters.magFilterInterpolation;
    self.wrap = parameters.wrap;
    self.maxMipmapLevel = parameters.maxMipmapLevel;
  }];
}

#pragma mark -
#pragma mark Utility methods
#pragma mark -

- (BOOL)inTextureRect:(CGRect)rect {
  CGRect texture = CGRectMake(0, 0, self.size.width, self.size.height);
  return CGRectContainsRect(texture, rect);
}

- (BOOL)isPowerOfTwo:(CGSize)size {
  int width = size.width;
  int height = size.height;
  
  return !((width & (width - 1)) || (height & (height - 1)));
}

#pragma mark -
#pragma mark Properties
#pragma mark -

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
  if (wrap == LTTextureWrapRepeat && ![self isPowerOfTwo:self.size]) {
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

- (id)debugQuickLookObject {
  return [[[LTImage alloc] initWithMat:[self image] copy:NO] UIImage];
}

@end
