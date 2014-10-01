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
  [super setImageFrame:imageFrame];
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
  LTParameterAssert(imageFrame.frameMask.size.width == imageFrame.frameMask.size.height);
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
  [self.inputTexture executeAndPreserveParameters:^{
    [self.auxiliaryTextures[[LTImageFrameFsh baseTexture]] setWrap:LTTextureWrapRepeat];
    [(self.auxiliaryTextures[[LTImageFrameFsh baseMaskTexture]]) setWrap:LTTextureWrapRepeat];
    [super process];
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

LTPropertyWithoutSetter(LTVector2, translation, Translation,
                        -LTVector2One, LTVector2One, LTVector2Zero);
- (void)setTranslation:(LTVector2)translation {
  [self _verifyAndSetTranslation:translation];
  self[[LTImageFrameFsh translation]] = $(translation);
}

@end
