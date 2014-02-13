// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "ProceduralFrame.h"

#import "LTProgram.h"
#import "LTShaderStorage+ProceduralFrameFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

@interface ProceduralFrame ()
// Aspect ration is equal to width / height of the output texture.
@property (nonatomic) CGFloat aspectRatio;

@end

@implementation ProceduralFrame

static const CGFloat kMinWidth = 0.0;
static const CGFloat kMaxWidth = 25.0;
static const CGFloat kDefaultWidth = 0.0;

static const CGFloat kMinSpread = 0.0;
static const CGFloat kMaxSpread = 25.0;
static const CGFloat kDefaultSpread = 0.0;

static const CGFloat kMinCorner = 0.0;
static const CGFloat kMaxCorner = 32.0;
static const CGFloat kDefaultCorner = 0.0;

- (instancetype)initWithNoise:(LTTexture *)noise output:(LTTexture *)output {
  LTProgram *program =
    [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                             fragmentSource:[ProceduralFrameFsh source]];
  
  NSDictionary *auxiliaryTextures = @{[ProceduralFrameFsh noiseTexture] : noise};

  if (self = [super initWithProgram:program sourceTexture:output auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    self.corner = kDefaultCorner;
    self.width = kDefaultWidth;
    self.spread = kDefaultSpread;
  }
  return self;
}

// TODO: Explain / improve logic.
- (void)updateEdges {
  CGFloat edge0;
  CGFloat edge1;
  CGFloat transitionBoost;
  CGFloat minVal;
  CGFloat maxVal;
  
  if (self.corner == 0.0) {
    edge0 = std::abs(self.width/100.0 - 0.5); // [-0.5 0.5]
    edge1 = std::abs((self.width + self.spread)/100.0 - 0.5);
    
    transitionBoost = 1.0;
    minVal = edge1;
    maxVal = edge0;
  } else {
    edge0 = std::abs(self.width/100.0 - 0.5);
    edge0 = std::pow(edge0, self.corner); // At center y is zero, thus ommited.
    
    edge1 = std::abs((self.width + self.spread)/100.0 - 0.5);
    edge1 = std::pow(edge1, self.corner);
    
    transitionBoost = 1.0/self.corner;
    minVal = std::pow(edge1, transitionBoost);
    maxVal = std::pow(edge0, transitionBoost);
  }
  self[@"edge0"] = @(edge0);
  self[@"edge1"] = @(edge1);
  self[@"transitionBoost"] = @(transitionBoost);
  self[@"minVal"] = @(minVal);
  self[@"maxVal"] = @(maxVal);
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

@end
