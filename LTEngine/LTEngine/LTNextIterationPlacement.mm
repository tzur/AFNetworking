// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTNextIterationPlacement.h"

#import "LTFbo.h"
#import "LTTexture.h"

@implementation LTNextIterationPlacement

- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture andTargetFbo:(LTFbo *)targetFbo {
  if (self = [super init]) {
    _sourceTexture = sourceTexture;
    _targetFbo = targetFbo;
  }
  return self;
}

@end
