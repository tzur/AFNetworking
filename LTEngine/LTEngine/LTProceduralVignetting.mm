// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTProceduralVignetting.h"
#import "LTProceduralVignetting+Protected.h"

#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTProceduralVignettingFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@implementation LTProceduralVignetting

- (instancetype)initWithOutput:(LTTexture *)output { 
  return [self initWithVertexSource:[LTPassthroughShaderVsh source]
                     fragmentSource:[LTProceduralVignettingFsh source] andOutput:output];
}

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource andOutput:(LTTexture *)output {
  LTTexture *defaultNoise = [self createNeutralNoise];
  NSDictionary *auxiliaryTextures = @{[LTProceduralVignettingFsh noiseTexture]: defaultNoise};
  if (self = [super initWithVertexSource:vertexSource fragmentSource:fragmentSource
                           sourceTexture:output auxiliaryTextures:auxiliaryTextures
                               andOutput:output]) {
    [self resetInputModel];
    self[[LTProceduralVignettingFsh distanceShift]] = $([self computeDistanceShift:output.size]);
  }
  return self;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

- (CGFloat)aspectRatio {
  return self.inputSize.width / self.inputSize.height;
}

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTProceduralVignetting, corner),
      @instanceKeypath(LTProceduralVignetting, spread),
      @instanceKeypath(LTProceduralVignetting, transition),
      @instanceKeypath(LTProceduralVignetting, noise),
      @instanceKeypath(LTProceduralVignetting, noiseChannelMixer),
      @instanceKeypath(LTProceduralVignetting, noiseAmplitude)
    ]];
  });
  
  return properties;
}

+ (BOOL)isPassthroughForDefaultInputModel {
  return NO;
}

- (LTTexture *)defaultNoise {
  return [self createNeutralNoise];
}

- (LTTexture *)createNeutralNoise {
  cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
  return [LTTexture textureWithImage:input];
}

- (LTVector2)computeDistanceShift:(CGSize)size {
  LTVector2 distanceShift;
  if (size.width > size.height) {
    distanceShift = LTVector2(1.0 - size.height / size.width, 0.0);
  } else {
    distanceShift = LTVector2(0.0, 1.0 - size.width / size.height);
  }

  return distanceShift;
}

LTPropertyWithoutSetter(CGFloat, spread, Spread, 0, 100, 100);
- (void)setSpread:(CGFloat)spread {
  [self _verifyAndSetSpread:spread];
  self[[LTProceduralVignettingFsh spread]] = @(spread / 100.0);
}

LTPropertyWithoutSetter(CGFloat, corner, Corner, 2, 16, 2);
- (void)setCorner:(CGFloat)corner {
  [self _verifyAndSetCorner:corner];
  self[[LTProceduralVignettingFsh corner]] = @(corner);
}

LTPropertyWithoutSetter(CGFloat, transition, Transition, 0, 1, 0);
- (void)setTransition:(CGFloat)transition {
  [self _verifyAndSetTransition:transition];
  self[[LTProceduralVignettingFsh transition]] = @(transition * 0.45);
}

- (void)setNoise:(LTTexture *)noise {
  if (!noise) {
    _noise = [self createNeutralNoise];
  } else {
    _noise = noise;
  }
  [self setAuxiliaryTexture:_noise withName:[LTProceduralVignettingFsh noiseTexture]];
}

LTPropertyWithoutSetter(LTVector3, noiseChannelMixer, NoiseChannelMixer,
                        -LTVector3::ones(), LTVector3::ones(), LTVector3(1, 0, 0));
- (void)setNoiseChannelMixer:(LTVector3)noiseChannelMixer {
  [self _verifyAndSetNoiseChannelMixer:noiseChannelMixer];
  // Normalize the input, so mixing doesn't affect amplitude.
  _noiseChannelMixer = noiseChannelMixer / noiseChannelMixer.sum();
  self[[LTProceduralVignettingFsh noiseChannelMixer]] = $(_noiseChannelMixer);
}

LTPropertyWithoutSetter(CGFloat, noiseAmplitude, NoiseAmplitude, 0, 100, 0);
- (void)setNoiseAmplitude:(CGFloat)noiseAmplitude {
  [self _verifyAndSetNoiseAmplitude:noiseAmplitude];
  self[[LTProceduralVignettingFsh noiseAmplitude]] = @(noiseAmplitude);
}

@end
