// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTProceduralFrame.h"

#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTProceduralFrameFsh.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@implementation LTProceduralFrame

static const CGFloat kMinWidth = 0.0;
static const CGFloat kMaxWidth = 25.0;
static const CGFloat kDefaultWidth = 0.0;

static const CGFloat kMinSpread = 0.0;
static const CGFloat kMaxSpread = 50.0;
static const CGFloat kDefaultSpread = 0.0;

static const CGFloat kMinCorner = 0.0;
static const CGFloat kMaxCorner = 32.0;
static const CGFloat kDefaultCorner = 0.0;

static const CGFloat kMinNoiseAmplitude = 0.0;
static const CGFloat kMaxNoiseAmplitude = 100.0;
static const CGFloat kDefaultNoiseAmplitude = 1.0;

static const GLKVector3 kDefaultColor = GLKVector3Make(1.0, 1.0, 1.0);
static const GLKVector3 kDefaultNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);

- (instancetype)initWithOutput:(LTTexture *)output {
  LTProgram *program =
    [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                             fragmentSource:[LTProceduralFrameFsh source]];
  
  LTTexture *defaultNoise = [self createNeutralNoise];
  NSDictionary *auxiliaryTextures = @{[LTProceduralFrameFsh noiseTexture]: defaultNoise};

  if (self = [super initWithProgram:program sourceTexture:output auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    [self setDefaultValues];
    [self precomputeDistanceShift:output.size];
  }
  return self;
}

- (void)setDefaultValues {
  self.corner = kDefaultCorner;
  self.width = kDefaultWidth;
  self.spread = kDefaultSpread;
  self.noiseAmplitude = kDefaultNoiseAmplitude;
  self.noiseChannelMixer = kDefaultNoiseChannelMixer;
  self.color = kDefaultColor;
  _noise = self.auxiliaryTextures[[LTProceduralFrameFsh noiseTexture]];
}

- (LTTexture *)createNeutralNoise {
  cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
  return [LTTexture textureWithImage:input];
}

// Precompute the distance shift that is used to correct aspect ratio in the shader.
// Aspect ratio is corrected by zeroing the longer dimension near the center, so non-zero part
// of both dimensions is equal. Such strategy (instead of simple scaling) is needed in order to
// preserve the correct transition behaviour.
- (void)precomputeDistanceShift:(CGSize)size {
  GLKVector2 distanceShift;
  if (size.width > size.height) {
    distanceShift = GLKVector2Make(1.0 - size.height / size.width, 0.0);
  }
  else {
    distanceShift = GLKVector2Make(0.0, 1.0 - size.width / size.height);
  }
  self[@"distanceShift"] = $(distanceShift);
}

// Width and spread of the frame determine the edges (edge0 and edge1) of the distance field that
// is constructed in the shader. Changing either width or spread requires to recompute the edges.
// Notice, that the corner (which determines the power of the distance field) is not needed in the
// computation. This is due to the fact that we measure the edges at y==0. So in the case of p-norm
// we get (x^p+y^p)^(1/p)=(x^p+0^p)^(1/p)=(x^p)^(1/p)=x. Trivially holds for max semi-norm.
- (void)updateEdges {
  // Distance field value on the edge between the foreground and the transition.
  CGFloat edge0 = std::abs((self.width / 100.0 - 0.5) * 2.0); // [-1, 1]
  // Distance field value on the edge between the transition and the background.
  CGFloat edge1 = std::abs(((self.width + self.spread) / 100.0 - 0.5) * 2.0); // [-1, 1];
  
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
}

- (void)setNoise:(LTTexture *)noise {
  // Update details LUT texture in auxiliary textures.
  _noise = noise;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTProceduralFrameFsh noiseTexture]] = noise;
  self.auxiliaryTextures = auxiliaryTextures;
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

- (CGFloat)maxWidth {
  return kMaxWidth;
}

@end
