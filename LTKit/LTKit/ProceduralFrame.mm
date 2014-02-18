// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "ProceduralFrame.h"

#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+ProceduralFrameFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@implementation ProceduralFrame

static const CGFloat kMinWidth = 0.0;
static const CGFloat kMaxWidth = 25.0;
static const CGFloat kDefaultWidth = 0.0;

static const CGFloat kMinSpread = 0.0;
static const CGFloat kMaxSpread = 50.0;
static const CGFloat kDefaultSpread = 0.0;

static const CGFloat kMinCorner = 0.0;
static const CGFloat kMaxCorner = 32.0;
static const CGFloat kDefaultCorner = 0.0;

static const CGFloat kMinTransitionExponent = 0.0;
static const CGFloat kMaxTransitionExponent = 1.0;
static const CGFloat kDefaultTransitionExponent = 1.0;

static const CGFloat kMinNoiseAmplitude = 0.0;
static const CGFloat kMaxNoiseAmplitude = 100.0;
static const CGFloat kDefaultNoiseAmplitude = 1.0;

static const GLKVector3 kDefaultColor = GLKVector3Make(1.0, 1.0, 1.0);
static const GLKVector3 kDefaultNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);

- (instancetype)initWithNoise:(LTTexture *)noise output:(LTTexture *)output {
  LTProgram *program =
    [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                             fragmentSource:[ProceduralFrameFsh source]];
  
  NSDictionary *auxiliaryTextures = @{[ProceduralFrameFsh noiseTexture] : noise};

  if (self = [super initWithProgram:program sourceTexture:output auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    // Set default parameters.
    self.corner = kDefaultCorner;
    self.width = kDefaultWidth;
    self.spread = kDefaultSpread;
    self.transitionExponent = kDefaultTransitionExponent;
    self.noiseAmplitude = kDefaultNoiseAmplitude;
    self.noiseChannelMixer = kDefaultNoiseChannelMixer;
    self.color = kDefaultColor;
    
    // Precompute the distance shift that is used to correct aspect ratio in the shader.
    // Aspect ratio is corrected by zeroing the longer dimension near the center, so non-zero part
    // of both dimensions is equal. Such strategy (instead of simple scaling) is needed in order to
    // preserve the correct transition behaviour.
    GLKVector2 distanceShift;
    if (output.size.width > output.size.height) {
      distanceShift = GLKVector2Make(1.0 - output.size.height / output.size.width, 0.0);
    }
    else {
      distanceShift = GLKVector2Make(0.0, 1.0 - output.size.width / output.size.height);
    }
    self[@"distanceShift"] = $(distanceShift);
  }
  return self;
}

// Width, spread and corner type of the frame determine the edges(edge0 and edge1) of the distance
// field that is beuild in the shader. Changing either width, spread or corner requires to
// recompute the edges.
- (void)updateEdges {
  // Distance field value on the edge between the foreground and the transition.
  CGFloat edge0 = std::abs((self.width/100.0 - 0.5) * 2.0); // [-1, 1]
  // Distance field value on the edge between the transition and the background.
  CGFloat edge1 = std::abs(((self.width + self.spread)/100.0 - 0.5) * 2.0); // [-1, 1];
  
  // For max semi-norm, no further precomputation is needed. Continue if corner corresponds to
  // p-norm.
  if (self.corner > 0.0) {
    edge0 = std::abs((self.width/100.0 - 0.5) * 2.0);
    edge0 = std::pow(edge0, self.corner); // At center y is zero, thus ommited.
    
    edge1 = std::abs(((self.width + self.spread)/100.0 - 0.5) * 2.0);
    edge1 = std::pow(edge1, self.corner);
  }
  self[@"edge0"] = @(edge0);
  self[@"edge1"] = @(edge1);
}

- (void)setWidth:(CGFloat)width {
  LTParameterAssert(width >= kMinWidth, @"Width is lower than minimum value");
  LTParameterAssert(width <= kMaxWidth, @"Width is higher than maximum value");
  
  _width = width;
  [self updateEdges];
}

- (void)setSpread:(CGFloat)spread {
  LTParameterAssert(spread >= kMinSpread, @"Spread is lower than minimum value");
  LTParameterAssert(spread <= kMaxSpread, @"Spread is higher than maximum value");
  
  _spread = spread;
  [self updateEdges];
}

- (void)setCorner:(CGFloat)corner {
  LTParameterAssert(corner >= kMinCorner, @"Corner is lower than minimum value");
  LTParameterAssert(corner <= kMaxCorner, @"Corner is higher than maximum value");
  
  _corner = corner;
  self[@"corner"] = @(corner);
  [self updateEdges];
}

- (void)setTransitionExponent:(CGFloat)transitionExponent {
  LTParameterAssert(transitionExponent >= kMinTransitionExponent,
                    @"Transition exponent is lower than minimum value");
  LTParameterAssert(transitionExponent <= kMaxTransitionExponent,
                    @"Transition exponent is higher than maximum value");
  
  _transitionExponent = transitionExponent;
  self[@"transitionExponent"] = @(transitionExponent);
}

- (void)setNoiseAmplitude:(CGFloat)noiseAmplitude {
  LTParameterAssert(noiseAmplitude >= kMinNoiseAmplitude,
                    @"Noise amplitude is lower than minimum value");
  LTParameterAssert(noiseAmplitude <= kMaxNoiseAmplitude,
                    @"Noise amplitude is higher than maximum value");
  
  _noiseAmplitude = noiseAmplitude;
  self[@"noiseAmplitude"] = @(noiseAmplitude);
}

- (void)setColor:(GLKVector3)color {
  LTParameterAssert(GLKVectorInRange(color, 0.0, 1.0),
                    @"Frame color components should be in [0, 1] range");
  _color = color;
  self[@"color"] = $(color);
}

- (void)setNoiseChannelMixer:(GLKVector3)noiseChannelMixer {
  // Normalize the input, so mixing doesn't affect amplitude.
  _noiseChannelMixer = noiseChannelMixer / std::sum(noiseChannelMixer);
  self[@"noiseChannelMixer"] = $(_noiseChannelMixer);
}

@end
