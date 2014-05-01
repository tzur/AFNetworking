// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTProceduralFrame.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTMathUtils.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTProceduralFrameVsh.h"
#import "LTShaderStorage+LTProceduralFrameFsh.h"
#import "LTTexture+Factory.h"

@implementation LTProceduralFrame

static const GLKVector3 kDefaultNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);

- (instancetype)initWithOutput:(LTTexture *)output {
  LTProgram *program =
    [[LTProgram alloc] initWithVertexSource:[LTProceduralFrameVsh source]
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
  self.corner = self.defaultCorner;
  self.width = self.defaultWidth;
  self.spread = self.defaultSpread;
  self.color = self.defaultColor;
  _noise = self.auxiliaryTextures[[LTProceduralFrameFsh noiseTexture]];
  self.noiseAmplitude = self.defaultNoiseAmplitude;
  self.noiseChannelMixer = kDefaultNoiseChannelMixer;
  self.noiseMapping = LTProceduralFrameNoiseMappingStretch;
  self.noiseCoordinatesOffset = self.defaultNoiseCoordinatesOffset;
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
  self[[LTProceduralFrameFsh distanceShift]] = $(distanceShift);
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
  
  self[[LTProceduralFrameFsh edge0]] = @(edge0);
  self[[LTProceduralFrameFsh edge1]] = @(edge1);
}

#pragma mark -
#pragma mark Basic Properties
#pragma mark -

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, width, Width, 0, 25, 0, ^{
  _width = width;
  [self updateEdges];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, spread, Spread, 0, 50, 0, ^{
  _spread = spread;
  [self updateEdges];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, corner, Corner, 0, 32, 0, ^{
  _corner = corner;
  self[[LTProceduralFrameFsh corner]] = @(corner);
});

LTBoundedPrimitivePropertyImplementWithoutSetter(GLKVector3, color, Color,
                                                 GLKVector3Make(0, 0, 0),
                                                 GLKVector3Make(1, 1, 1),
                                                 GLKVector3Make(1, 1, 1));

- (void)setColor:(GLKVector3)color {
  LTParameterAssert(GLKVector3AllGreaterThanOrEqualToVector3(color, self.minColor));
  LTParameterAssert(GLKVector3AllGreaterThanOrEqualToVector3(self.maxColor, color));
  _color = color;
  self[[LTProceduralFrameFsh color]] = $(color);
}

#pragma mark -
#pragma mark Noise Properties
#pragma mark -

- (void)setNoise:(LTTexture *)noise {
  LTParameterAssert([self isValidNoiseTexture:noise],
      @"Noise should be either tileable or noiseMapping should be "
       "in LTProceduralFrameNoiseMappingScale mode.");
  _noise = noise;
  [self setAuxiliaryTexture:noise withName:[LTProceduralFrameFsh noiseTexture]];
}

- (BOOL)isValidNoiseTexture:(LTTexture *)texture {
  BOOL isTilable = LTIsPowerOfTwo(texture.size) && (texture.wrap == LTTextureWrapRepeat);
  BOOL inStretchMode = (self.noiseMapping == LTProceduralFrameNoiseMappingStretch);
  return isTilable || inStretchMode;
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, noiseAmplitude, NoiseAmplitude,
                                                    0, 100, 1, ^{
  _noiseAmplitude = noiseAmplitude;
  self[[LTProceduralFrameFsh noiseAmplitude]] = @(noiseAmplitude);
});

- (void)setNoiseMapping:(LTProceduralFrameNoiseMapping)noiseMapping {
  _noiseMapping = noiseMapping;
  switch (noiseMapping) {
    case LTProceduralFrameNoiseMappingStretch:
      self[[LTProceduralFrameVsh grainScaling]] = $(GLKVector2Make(1, 1));
      return;
    case LTProceduralFrameNoiseMappingTile:
      CGFloat xScale = self.outputSize.width / self.noise.size.width;
      CGFloat yScale = self.outputSize.height / self.noise.size.height;
      self[[LTProceduralFrameVsh grainScaling]] = $(GLKVector2Make(xScale, yScale));
      return;
  }
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, noiseCoordinatesOffset,
                                                    NoiseCoordinatesOffset, 0, 1, 0, ^{
  _noiseCoordinatesOffset = noiseCoordinatesOffset;
  self[[LTProceduralFrameVsh grainOffset]] = $(GLKVector2Make(noiseCoordinatesOffset,
                                                              noiseCoordinatesOffset));
});

- (void)setNoiseChannelMixer:(GLKVector3)noiseChannelMixer {
  // Normalize the input, so mixing doesn't affect amplitude.
  _noiseChannelMixer = noiseChannelMixer / std::sum(noiseChannelMixer);
  self[[LTProceduralFrameFsh noiseChannelMixer]] = $(_noiseChannelMixer);
}

@end
