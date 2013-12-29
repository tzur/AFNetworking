// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

#import "LTBoundaryCondition.h"
#import "LTGLException.h"
#import "LTImage.h"

static LTTexturePrecision LTPrecisionFromMat(const cv::Mat &image) {
  switch (image.depth()) {
    case CV_8U:
      return LTTexturePrecisionByte;
    case CV_16U:
      return LTTexturePrecisionHalfFloat;
    case CV_32F:
      return LTTexturePrecisionFloat;
    default:
      [LTGLException raise:kLTTextureUnsupportedFormatException
                    format:@"Invalid depth in given image: %d", image.depth()];
      __builtin_unreachable();
  }
}

static LTTextureChannels LTChannelsFromMat(const cv::Mat &image) {
  switch (image.channels()) {
    case 4:
      return LTTextureChannelsRGBA;
    default:
      [LTGLException raise:kLTTextureUnsupportedFormatException
                    format:@"Invalid number of channels in given image: %d", image.channels()];
      __builtin_unreachable();
  }
}

@interface LTTexture ()

/// Set to the previously bound texture, or \c 0 if the texture is not bound.
@property (nonatomic) GLint previousTexture;

/// The active texture unit while binding the texture.
@property (nonatomic) GLint boundTextureUnit;

/// YES if the texture is currently bound.
@property (nonatomic) BOOL bound;

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
    _minFilterInterpolation = LTTextureInterpolationLinear;
    _magFilterInterpolation = LTTextureInterpolationLinear;
    _wrap = LTTextureWrapClamp;
    _precision = precision;
    _channels = channels;
    _size = size;
    
    [self create:allocateMemory];
  }
  return self;
}

- (id)initWithImage:(const cv::Mat &)image {
  if (self = [self initWithSize:CGSizeMake(image.cols, image.rows)
                      precision:LTPrecisionFromMat(image)
                       channels:LTChannelsFromMat(image)
                 allocateMemory:NO]) {
    [self load:image];
  }
  return self;
}

- (void)dealloc {
  [self destroy];
}

- (void)load:(const cv::Mat __unused &)image {
  LTAssert(NO, @"-[LTTexture load:] is an abstract method that should be overridden by subclasses");
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

#pragma mark -
#pragma mark LTTexture implemented methods
#pragma mark -

- (void)bind {
  if (self.bound) {
    return;
  }

  glGetIntegerv(GL_ACTIVE_TEXTURE, &_boundTextureUnit);
  glGetIntegerv(GL_TEXTURE_BINDING_2D, &_previousTexture);
  glBindTexture(GL_TEXTURE_2D, self.name);
  
  self.bound = YES;
}

- (void)unbind {
  if (!self.bound) {
    return;
  }

  GLint activeTextureUnit;
  glGetIntegerv(GL_ACTIVE_TEXTURE, &activeTextureUnit);

  // Make sure we switch to the active texture unit at the time of binding.
  if (activeTextureUnit != self.boundTextureUnit) {
    glActiveTexture(self.boundTextureUnit);
  }
  glBindTexture(GL_TEXTURE_2D, self.previousTexture);
  if (activeTextureUnit != self.boundTextureUnit) {
    glActiveTexture(activeTextureUnit);
  }
  
  self.previousTexture = 0;
  self.bound = NO;
}

- (void)bindAndExecute:(LTVoidBlock)block {
  if (self.bound) {
    block();
  } else {
    [self bind];
    if (block) block();
    [self unbind];
  }
}

- (GLKVector4)pixelValue:(CGPoint)location {
  cv::Mat image = [self imageWithRect:CGRectMake(location.x, location.y, 1, 1)];
  
  // Reading half-float is currently not supported.
  // TODO: (yaron) implement a half-float <--> float converter when needed.
  
  switch (image.type()) {
    case CV_8U: {
      uchar value = image.at<uchar>(0, 0);
      return {{value / 255.f, 0.f, 0.f, 0.f}};
    }
    case CV_8UC4: {
      cv::Vec4b value = image.at<cv::Vec4b>(0, 0);
      return {{value(0) / 255.f, value(1) / 255.f, value(2) / 255.f, value(3) / 255.f}};
    }
    case CV_32F: {
      float value = image.at<float>(0, 0);
      return {{value, 0, 0, 0}};
    }
    case CV_32FC4: {
      cv::Vec4f value = image.at<cv::Vec4f>(0, 0);
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
                           withSignalSize:cv::Vec2i(self.size.width, self.size.height)];
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
  
  [self bindAndExecute:^{
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilterInterpolation);
  }];
  
  _minFilterInterpolation = minFilterInterpolation;
}

- (void)setMagFilterInterpolation:(LTTextureInterpolation)magFilterInterpolation {
  if (!self.name) {
    return;
  }
  
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

- (int)matType {
  switch (self.channels) {
    case LTTextureChannelsRGBA:
      switch (self.precision) {
        case LTTexturePrecisionByte:
          return CV_8UC4;
        case LTTexturePrecisionHalfFloat:
          return CV_16UC4;
        case LTTexturePrecisionFloat:
          return CV_32FC4;
      }
      break;
  }
}

#pragma mark -
#pragma mark Debugging
#pragma mark -

- (id)debugQuickLookObject {
  return [[[LTImage alloc] initWithMat:[self image] copy:NO] UIImage];
}

@end
