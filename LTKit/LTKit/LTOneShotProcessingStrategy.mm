// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotProcessingStrategy.h"

#import "LTFbo.h"

@interface LTOneShotProcessingStrategy ()

/// Set to \c YES if the processor already processed the input.
@property (nonatomic) BOOL didProcess;

/// Input texture to read from.
@property (strong, nonatomic) LTTexture *input;

/// Output textures to write to.
@property (strong, nonatomic) LTTexture *output;

@end

@implementation LTOneShotProcessingStrategy

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input andOutput:(LTTexture *)output {
  if (self = [super init]) {
    self.input = input;
    self.output = output;
  }
  return self;
}

#pragma mark -
#pragma mark LTProcessingStrategy
#pragma mark -

- (void)processingWillBegin {
  self.didProcess = NO;
}

- (BOOL)hasMoreIterations {
  return !self.didProcess;
}

- (LTNextIterationPlacement *)iterationStarted {
  LTFbo *fbo = [[LTFbo alloc] initWithTexture:self.output];
  return [[LTNextIterationPlacement alloc] initWithSourceTexture:self.input andTargetFbo:fbo];
}

- (void)iterationEnded {
  self.didProcess = YES;
}

@end
