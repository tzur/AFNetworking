// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTImageBorderProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTImageBorderFsh.h"
#import "LTTexture+Factory.h"

@implementation LTImageBorderProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  NSDictionary *auxiliaryTextures =
    @{[LTImageBorderFsh frontTexture]: [self defaultFrontTexture],
      [LTImageBorderFsh backTexture]: [self defaultBackTexture]};
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTImageBorderFsh source] sourceTexture:input
                       auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    self[[LTImageBorderFsh aspectRatio]] = @([self aspectRatio]);
    [self resetInputModel];
  }
  return self;
}

- (LTTexture *)defaultFrontTexture {
  return [self defaultBorderTexture];
}

- (LTTexture *)defaultBackTexture {
  return [self defaultBorderTexture];
}

- (LTTexture *)defaultBorderTexture {
  LTTexture *greyTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(1, 1)];
  [greyTexture clearWithColor:LTVector4(0.5)];
  return greyTexture;
}

- (CGFloat)aspectRatio {
  return self.inputSize.width / self.inputSize.height;
}

- (LTSymmetrizationType)defaultFrontSymmetrization {
  return LTSymmetrizationTypeOriginal;
}

- (LTSymmetrizationType)defaultBackSymmetrization {
  return LTSymmetrizationTypeOriginal;
}

- (BOOL)defaultFrontFlipVertical {
  return NO;
}

- (BOOL)defaultFrontFlipHorizontal {
  return NO;
}

- (BOOL)defaultBackFlipVertical {
  return NO;
}

- (BOOL)defaultBackFlipHorizontal {
  return NO;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTImageBorderProcessor, width),
      @instanceKeypath(LTImageBorderProcessor, spread),
      @instanceKeypath(LTImageBorderProcessor, color),
      @instanceKeypath(LTImageBorderProcessor, opacity),
       
      @instanceKeypath(LTImageBorderProcessor, frontTexture),
      @instanceKeypath(LTImageBorderProcessor, backTexture),

      @instanceKeypath(LTImageBorderProcessor, frontSymmetrization),
      @instanceKeypath(LTImageBorderProcessor, backSymmetrization),
      @instanceKeypath(LTImageBorderProcessor, edge0),
      @instanceKeypath(LTImageBorderProcessor, edge1),

      @instanceKeypath(LTImageBorderProcessor, frontFlipHorizontal),
      @instanceKeypath(LTImageBorderProcessor, frontFlipVertical),
      @instanceKeypath(LTImageBorderProcessor, backFlipHorizontal),
      @instanceKeypath(LTImageBorderProcessor, backFlipVertical)
    ]];
  });
  
  return properties;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyWithoutSetter(CGFloat, width, Width, -1, 1, 0);
- (void)setWidth:(CGFloat)width {
  [self _verifyAndSetWidth:width];
  [self updateWithWidthAndSpread];
}

- (void)updateWithWidthAndSpread {
  CGFloat ratio = [self aspectRatio];
  LTVector2 frontWidth;
  LTVector2 backWidth;
  if (ratio < 1) {
    frontWidth = LTVector2(self.width, self.width * ratio);
    backWidth = LTVector2(self.width + self.spread, (self.width + self.spread) * ratio);
  } else {
    frontWidth = LTVector2(self.width / ratio, self.width);
    backWidth = LTVector2((self.width + self.spread) / ratio, self.width + self.spread);
  }
  self[[LTImageBorderFsh frontWidth]] = $(frontWidth);
  self[[LTImageBorderFsh backWidth]] = $(backWidth);
}

LTPropertyWithoutSetter(CGFloat, spread, Spread, -1, 1, 0);
- (void)setSpread:(CGFloat)spread {
  [self _verifyAndSetSpread:spread];
  [self updateWithWidthAndSpread];
}

LTPropertyWithoutSetter(CGFloat, opacity, Opacity, 0, 1, 1);
- (void)setOpacity:(CGFloat)opacity {
  [self _verifyAndSetOpacity:opacity];
  self[[LTImageBorderFsh opacity]] = @(opacity);
}

LTPropertyWithoutSetter(LTVector3, color, Color, LTVector3Zero, LTVector3One, LTVector3One);
- (void)setColor:(LTVector3)color {
  [self _verifyAndSetColor:color];
  self[[LTImageBorderFsh frameColor]] = $(color);
}

- (void)setFrontTexture:(LTTexture *)frontTexture {
  if (!frontTexture) {
    frontTexture = [self defaultBorderTexture];
  }
  LTParameterAssert([self isValidTexture:frontTexture], @"Front texture should be square.");
  _frontTexture = frontTexture;
  [self setAuxiliaryTexture:frontTexture withName:[LTImageBorderFsh frontTexture]];
}

- (void)setBackTexture:(LTTexture *)backTexture {
  if (!backTexture) {
    backTexture = [self defaultBorderTexture];
  }
  LTParameterAssert([self isValidTexture:backTexture], @"Back texture should be square.");
  _backTexture = backTexture;
  [self setAuxiliaryTexture:backTexture withName:[LTImageBorderFsh backTexture]];
}

- (BOOL)isValidTexture:(LTTexture *)texture {
  BOOL squareRatio = (texture.size.width == texture.size.height);
  return squareRatio;
}

#pragma mark -
#pragma mark Symmetrization
#pragma mark -

- (void)setFrontSymmetrization:(LTSymmetrizationType)frontSymmetrization {
  _frontSymmetrization = frontSymmetrization;
  self[[LTImageBorderFsh frontSymmetrization]] = @(frontSymmetrization);
}

- (void)setBackSymmetrization:(LTSymmetrizationType)backSymmetrization {
  _backSymmetrization = backSymmetrization;
  self[[LTImageBorderFsh backSymmetrization]] = @(backSymmetrization);
}

LTPropertyWithoutSetter(CGFloat, edge0, Edge0, 0, 0.5, 0);
- (void)setEdge0:(CGFloat)edge0 {
  [self _verifyAndSetEdge0:edge0];
  self[[LTImageBorderFsh edge0]] = @(edge0);
}

LTPropertyWithoutSetter(CGFloat, edge1, Edge1, 0, 0.5, 0.25);
- (void)setEdge1:(CGFloat)edge1 {
  [self _verifyAndSetEdge1:edge1];
  self[[LTImageBorderFsh edge1]] = @(edge1);
}

- (void)setFrontFlipHorizontal:(BOOL)frontFlipHorizontal {
  _frontFlipHorizontal = frontFlipHorizontal;
  self[[LTImageBorderFsh frontFlipHorizontal]] = @(frontFlipHorizontal);
}

- (void)setFrontFlipVertical:(BOOL)frontFlipVertical {
  _frontFlipVertical = frontFlipVertical;
  self[[LTImageBorderFsh frontFlipVertical]] = @(frontFlipVertical);
}

- (void)setBackFlipHorizontal:(BOOL)backFlipHorizontal {
  _backFlipHorizontal = backFlipHorizontal;
  self[[LTImageBorderFsh backFlipHorizontal]] = @(backFlipHorizontal);
}

- (void)setBackFlipVertical:(BOOL)backFlipVertical {
  _backFlipVertical = backFlipVertical;
  self[[LTImageBorderFsh backFlipVertical]] = @(backFlipVertical);
}

@end
