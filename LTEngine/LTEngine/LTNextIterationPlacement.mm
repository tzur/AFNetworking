// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTNextIterationPlacement.h"

#import "LTFbo.h"
#import "LTTexture.h"

@interface LTNextIterationPlacement ()
@property (strong, nonatomic) LTTexture *sourceTexture;
@property (strong, nonatomic) LTFbo *targetFbo;
@end

@implementation LTNextIterationPlacement

- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture andTargetFbo:(LTFbo *)targetFbo {
  if (self = [super init]) {
    self.sourceTexture = sourceTexture;
    self.targetFbo = targetFbo;
  }
  return self;
}

@end
