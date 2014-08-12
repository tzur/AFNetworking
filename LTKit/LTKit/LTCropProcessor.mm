// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCropProcessor.h"

#import "LTCGExtensions.h"
#import "LTCropDrawer.h"
#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTTexture+Factory.h"

@interface LTCropProcessor ()

/// Input texture of the processor.
@property (strong, nonatomic) LTTexture *inputTexture;

/// Most recent processing output texture.
@property (strong, nonatomic) LTTexture *outputTexture;

/// Drawer used for processing.
@property (strong, nonatomic) LTCropDrawer *drawer;

/// Transformation matrix representing the stacked rotations and flips applied on the
/// origin-centered normalized input coordinates ([-0.5,0.5] x [-0.5,0.5]);
///
/// @note This origin-centered assumption allows us to easily stack the operations by multiplying
/// the matrix with the operation-specific transform.
@property (nonatomic) GLKMatrix2 transform;

/// Represents the normalized crop rectangle in the unrotated and unflipped coordinate system.
@property (nonatomic) LTCropDrawerRect normalizedCropRectangle;

/// Cached version of the crop rectangle, used to avoid recalculating the current rectangle from the
/// \c normalizedCropRectangle unless the \c transform was updated.
@property (nonatomic) CGRect cachedCropRectangle;

/// The transform corresponding to the cached version of the \c cropRectangle.
@property (nonatomic) GLKMatrix2 cachedTransform;

@end

@implementation LTCropProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input {
  LTParameterAssert(input);
  if (self = [super init]) {
    self.inputTexture = input;
    self.transform = GLKMatrix2Identity;
    self.normalizedCropRectangle = CGRectMake(0, 0, 1, 1);
    [self createDrawer];
  }
  return self;
}

- (void)createDrawer {
  LTParameterAssert(self.inputTexture);
  self.drawer = [[LTCropDrawer alloc] initWithTexture:self.inputTexture];
}

#pragma mark -
#pragma mark Processor
#pragma mark -

- (void)process {
  [self prepareOutputTexture];
  
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:self.outputTexture];
  [self.inputTexture executeAndPreserveParameters:^{
    self.inputTexture.minFilterInterpolation = LTTextureInterpolationNearest;
    self.inputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    
    LTCropDrawerRect targetRect(CGRectFromSize(fbo.size));
    LTCropDrawerRect sourceRect = [self sourceRectangleForDrawer];
    
    [self.drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
  }];
}

- (void)prepareOutputTexture {
  CGSize targetSize = [self sizeForOutputTexture];
  if (self.outputTexture.size != targetSize) {
    self.outputTexture = [LTTexture textureWithSize:targetSize precision:self.inputTexture.precision
                                             format:self.inputTexture.format allocateMemory:YES];
  }
}
   
- (LTCropDrawerRect)sourceRectangleForDrawer {
  LTCropDrawerRect rect =
      self.applyCrop ? self.normalizedCropRectangle : [self uncroppedSourceRectangle];
  rect *= self.inputTexture.size;
  return rect;
}

- (LTCropDrawerRect)uncroppedSourceRectangle {
  return [self transform:GLKMatrix2Transpose(self.transform) rect:CGRectMake(0, 0, 1, 1)];
}

- (CGSize)sizeForOutputTexture {
  return [self rotatedSize:CGRoundRect([self sourceRectangleForDrawer]).size];
}

- (CGSize)rotatedSize:(CGSize)size {
  return (self.rotations % 2) ? CGSizeMake(size.height, size.width) : size;
}

- (LTCropDrawerRect)transform:(const GLKMatrix2 &)transform rect:(LTCropDrawerRect)rect {
  for (LTVector2 &v : rect.corners) {
    v = [self transform:transform vector:v];
  }
  return rect;
}

- (LTVector2)transform:(const GLKMatrix2 &)transform vector:(LTVector2)vector {
  vector -= 0.5;
  vector = GLKMatrix2MultiplyVector2(transform, vector);
  vector += 0.5;
  return vector;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setFlipHorizontal:(BOOL)flipHorizontal {
  if (flipHorizontal == _flipHorizontal) {
    return;
  }
  
  _flipHorizontal = flipHorizontal;
  self.transform = GLKMatrix2Multiply(GLKMatrix2MakeScale(-1, 1), self.transform);
}

- (void)setFlipVertical:(BOOL)flipVertical {
  if (flipVertical == _flipVertical) {
    return;
  }
  
  _flipVertical = flipVertical;
  self.transform = GLKMatrix2Multiply(GLKMatrix2MakeScale(1, -1), self.transform);
}

- (void)setRotations:(NSInteger)rotations {
  if (rotations % 4 == _rotations % 4) {
    _rotations = rotations;
    return;
  }

  self.transform = [self rotateMatrix:self.transform from:_rotations to:rotations];
  _rotations = rotations;
}

- (GLKMatrix2)rotateMatrix:(GLKMatrix2)matrix from:(NSInteger)rotations to:(NSInteger)newRotations {
  static const GLKMatrix2 kClockwise = GLKMatrix2Make(0, 1, -1, 0);
  static const GLKMatrix2 kCounterClockwise = GLKMatrix2Make(0, -1, 1, 0);
  NSInteger difference = (newRotations - rotations) % 4;
  for (NSInteger i = 0; std::abs(i) < std::abs(difference); ++i) {
    matrix = GLKMatrix2Multiply(difference > 0 ? kClockwise : kCounterClockwise, matrix);
  }
  return matrix;
}

- (void)setCropRectangle:(CGRect)cropRectangle {
  LTCropDrawerRect rect = cropRectangle;
  rect /= [self rotatedSize:self.inputTexture.size];
  self.normalizedCropRectangle = [self transform:GLKMatrix2Transpose(self.transform) rect:rect];
  self.cachedTransform = GLKMatrix2();
}

- (CGRect)cropRectangle {
  if (self.cachedTransform != self.transform) {
    LTCropDrawerRect rect = [self transform:self.transform rect:self.normalizedCropRectangle];
    rect *= [self rotatedSize:self.inputTexture.size];
    self.cachedCropRectangle = CGRoundRect(rect);
    self.cachedTransform = self.transform;
  }
  
  return self.cachedCropRectangle;
}

@end
