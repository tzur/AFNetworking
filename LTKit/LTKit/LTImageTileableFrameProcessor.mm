// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageTileableFrameProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTMathUtils.h"
#import "LTShaderStorage+LTImageFrameFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

@interface LTImageFrameProcessor ()
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;
- (void)setImageFrame:(LTImageFrame *)imageFrame;
- (void)assertImageFrameCorrectness:(LTImageFrame *)imageFrame;
@end

@implementation LTImageTileableFrameProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithInput:input output:output]) {
    self[[LTImageFrameFsh isTileable]] = @YES;
  }
  return self;
}

- (void)setImageFrame:(LTImageFrame *)imageFrame {
  [self setImageFrame:imageFrame angle:self.defaultAngle translation:self.defaultTranslation];
}

- (void)setImageFrame:(LTImageFrame *)imageFrame angle:(CGFloat)angle
          translation:(CGPoint)translation {
  [super setImageFrame:imageFrame];
  self.angle = angle;
  self.translation = translation;
  CGSize sizeOfTile = (imageFrame.baseTexture.size != CGSizeMake(1, 1)) ?
      imageFrame.baseTexture.size : imageFrame.baseMask.size;
  [self setScaleUniform:sizeOfTile];
}

- (void)assertImageFrameCorrectness:(LTImageFrame *)imageFrame {
  CGSize sizeOfOnePoint = CGSizeMake(0, 0);
  LTParameterAssert(!(imageFrame.baseTexture.size == sizeOfOnePoint &&
                     imageFrame.baseMask.size == sizeOfOnePoint) ||
                    (imageFrame.baseTexture.size == imageFrame.baseMask.size));
  LTParameterAssert(LTIsPowerOfTwo(imageFrame.baseTexture.size) &&
                    LTIsPowerOfTwo(imageFrame.baseMask.size));
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [[LTImageFrameProcessor inputModelPropertyKeys] setByAddingObjectsFromArray:@[
      @instanceKeypath(LTImageTileableFrameProcessor, angle),
      @instanceKeypath(LTImageTileableFrameProcessor, translation)
    ]];
  });
  
  return properties;
}

#pragma mark -
#pragma mark Uniforms
#pragma mark -

- (void)setScaleUniform:(CGSize)baseTextureSize {
  CGSize scalingFactor = self.outputSize / baseTextureSize;
  self[[LTImageFrameFsh scaling]] = $(LTVector2(scalingFactor.width, scalingFactor.height));
}

#pragma mark -
#pragma mark Processor
#pragma mark -

- (void)process {
  [self setTexturesToRepeatAndExecute:^{
    [super process];
  }];
}

- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect {
  [self setTexturesToRepeatAndExecute:^{
    [super processToFramebufferWithSize:size outputRect:rect];
  }];
}

- (void)setTexturesToRepeatAndExecute:(LTVoidBlock)block {
  LTParameterAssert(block);
  [self.auxiliaryTextures[[LTImageFrameFsh baseTexture]] executeAndPreserveParameters:^{
    [self.auxiliaryTextures[[LTImageFrameFsh baseMaskTexture]] executeAndPreserveParameters:^{
      [self.auxiliaryTextures[[LTImageFrameFsh baseTexture]] setWrap:LTTextureWrapRepeat];
      [self.auxiliaryTextures[[LTImageFrameFsh baseMaskTexture]] setWrap:LTTextureWrapRepeat];
      block();
    }];
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyWithoutSetter(CGFloat, angle, Angle, -M_PI, M_PI, 0);
- (void)setAngle:(CGFloat)angle {
  [self _verifyAndSetAngle:angle];
  self[[LTImageFrameFsh rotation]] = $(GLKMatrix2MakeRotation(angle));
}

- (CGPoint)defaultTranslation {
  return CGPointZero;
}

- (void)setTranslation:(CGPoint)translation {
  self[[LTImageFrameFsh translation]] = $(LTVector2(translation.x, translation.y));
}

@end
