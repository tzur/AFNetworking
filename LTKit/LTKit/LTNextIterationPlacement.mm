// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTNextIterationPlacement.h"

#import "LTTexture.h"
#import "LTTextureFbo.h"

@interface LTNextIterationPlacement ()
@property (strong, nonatomic) LTTexture *sourceTexture;
@property (strong, nonatomic) LTTextureFbo *targetFbo;
@end

@implementation LTNextIterationPlacement

- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                         andTargetFbo:(LTTextureFbo *)targetFbo {
  if (self = [super init]) {
    self.sourceTexture = sourceTexture;
    self.targetFbo = targetFbo;
  }
  return self;
}

@end
