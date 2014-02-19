// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTNoisyVignetting.h"

#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTNoisyVignettingFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@implementation LTNoisyVignetting

static const CGFloat kMinSpread = 0.0;
static const CGFloat kMaxSpread = 100.0;
static const CGFloat kDefaultSpread = kMaxSpread;

static const CGFloat kMinCorner = 2.0;
static const CGFloat kMaxCorner = 16.0;
static const CGFloat kDefaultCorner = kMinCorner;

static const CGFloat kMinNoiseAmplitude = 0.0;
static const CGFloat kMaxNoiseAmplitude = 100.0;
static const CGFloat kDefaultNoiseAmplitude = 1.0;

static const GLKVector3 kDefaultNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);

- (instancetype)initWithNoise:(LTTexture *)noise output:(LTTexture *)output {
  LTProgram *program =
      [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                               fragmentSource:[LTNoisyVignettingFsh source]];
  
  NSDictionary *auxiliaryTextures = @{[LTNoisyVignettingFsh noiseTexture]: noise};
  
  if (self = [super initWithProgram:program sourceTexture:output auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    [self setDefaultValues];
    [self precomputeDistanceShift:output.size];
  }
  return self;
}

- (void)setDefaultValues {
  self.corner = kDefaultCorner;
  self.spread = kDefaultSpread;
  self.noiseAmplitude = kDefaultNoiseAmplitude;
  self.noiseChannelMixer = kDefaultNoiseChannelMixer;
}

// Precompute the distance shift that is used to correct aspect ratio in the shader.
// Aspect ratio is corrected by zeroing the longer dimension near the center, so non-zero part
// of both dimensions is equal. Such strategy (instead of simple scaling) is needed in order to
// preserve the correct transition behaviour.
- (void)precomputeDistanceShift:(CGSize)size {
  GLKVector2 distanceShift;
  if (size.width > size.height) {
    distanceShift = GLKVector2Make(1.0 - size.height / size.width, 0.0);
  } else {
    distanceShift = GLKVector2Make(0.0, 1.0 - size.width / size.height);
  }
  self[@"distanceShift"] = $(distanceShift);
}

- (void)setSpread:(CGFloat)spread {
  LTParameterAssert(spread >= kMinSpread, @"Spread is lower than minimum value");
  LTParameterAssert(spread <= kMaxSpread, @"Spread is higher than maximum value");
  
  _spread = spread;
  self[@"spread"] = @(spread / 100.0);
}

- (void)setCorner:(CGFloat)corner {
  LTParameterAssert(corner >= kMinCorner, @"Corner is lower than minimum value");
  LTParameterAssert(corner <= kMaxCorner, @"Corner is higher than maximum value");
  
  _corner = corner;
  self[@"corner"] = @(corner);
}

- (void)setNoiseAmplitude:(CGFloat)noiseAmplitude {
  LTParameterAssert(noiseAmplitude >= kMinNoiseAmplitude,
                    @"Noise amplitude is lower than minimum value");
  LTParameterAssert(noiseAmplitude <= kMaxNoiseAmplitude,
                    @"Noise amplitude is higher than maximum value");
  
  _noiseAmplitude = noiseAmplitude;
  self[@"noiseAmplitude"] = @(noiseAmplitude);
}

- (void)setNoiseChannelMixer:(GLKVector3)noiseChannelMixer {
  // Normalize the input, so mixing doesn't affect amplitude.
  _noiseChannelMixer = noiseChannelMixer / std::sum(noiseChannelMixer);
  self[@"noiseChannelMixer"] = $(_noiseChannelMixer);
}

@end
