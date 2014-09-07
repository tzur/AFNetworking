// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIterativeProcessingStrategy.h"

#import "LTFbo.h"
#import "LTTexture+Factory.h"

@interface LTIterativeProcessingStrategy ()

/// Current iteration number.
@property (nonatomic) NSUInteger currentIteration;

/// Input texture to read from.
@property (strong, nonatomic) LTTexture *input;

/// Output textures to write to.
@property (strong, nonatomic) NSArray *outputs;

/// Intermediate texture for processing more than a single iteration.
@property (strong, nonatomic) LTTexture *intermediateTexture;

/// Intermediate framebuffer for processing more than a single iteration.
@property (strong, nonatomic) LTFbo *intermediateFbo;

/// Current output framebuffer.
@property (strong, nonatomic) LTFbo *outputFbo;

/// Source texture to read data from while processing.
@property (strong, nonatomic) LTTexture *sourceTexture;

/// Target framebuffer to write processed data to.
@property (strong, nonatomic) LTFbo *targetFbo;

/// Previous texture that was set as a target.
@property (strong, nonatomic) LTTexture *previousTargetTexture;

/// Next index of output texture to generate.
@property (nonatomic) NSUInteger nextOutputIndex;

/// Total number of iterations to execute in order to produce all outputs.
@property (readonly, nonatomic) NSUInteger totalNumberOfIterations;

/// Number of iterations required to produce the next output.
@property (readonly, nonatomic) NSUInteger iterationsForNextOutput;

@end

@implementation LTIterativeProcessingStrategy

@synthesize iterationsPerOutput = _iterationsPerOutput;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input andOutputs:(NSArray *)outputs {
  LTParameterAssert(input);
  LTParameterAssert(outputs);

  if (self = [super init]) {
    self.input = input;
    self.outputs = outputs;
  }
  return self;
}

#pragma mark -
#pragma mark LTProcessingStrategy
#pragma mark -

- (void)processingWillBegin {
  [self resetState];
  [self prepareNextOutput];
}

- (BOOL)hasMoreIterations {
  return self.currentIteration < self.totalNumberOfIterations;
}

- (LTNextIterationPlacement *)iterationStarted {
  LTAssert([self hasMoreIterations], @"Tried to start iteration while no iterations are left");

  [self setSourceTextureAndTargetFboForIteration:self.currentIteration];

  if (self.iterationStartedBlock) {
    self.iterationStartedBlock(self.currentIteration);
  }

  return [[LTNextIterationPlacement alloc] initWithSourceTexture:self.sourceTexture
                                                    andTargetFbo:self.targetFbo];
}

- (void)iterationEnded {
  LTAssert([self hasMoreIterations], @"Tried to end iteration while no iterations are left");

  if ([self shouldProduceOutputs]) {
    [self produceOutputs];
  }

  ++self.currentIteration;
}

#pragma mark -
#pragma mark LTProcessingStrategy utilities
#pragma mark -

- (NSUInteger)totalNumberOfIterations {
  return [[self.iterationsPerOutput lastObject] unsignedIntegerValue];
}

- (void)prepareNextOutput {
  LTTexture *outputTexture = self.outputs[self.nextOutputIndex];
  self.outputFbo = [[LTFbo alloc] initWithTexture:outputTexture];
}

- (void)setSourceTextureAndTargetFboForIteration:(NSUInteger)iteration {
  self.previousTargetTexture = self.targetFbo.texture ?: self.input;

  // Toggle between source -> itermediate, intermediate -> output and output -> intermediate.
  if (iteration == 0) {
    if (self.totalNumberOfIterations > 1 && ![self shouldProduceOutputs]) {
      self.targetFbo = self.intermediateFbo;
    } else {
      // For a single iteration, no intermediate texture or framebuffer are needed.
      self.targetFbo = self.outputFbo;
    }
  } else if (iteration % 2 || [self shouldProduceOutputs]) {
    self.targetFbo = self.outputFbo;
  } else {
    self.targetFbo = self.intermediateFbo;
  }

  self.sourceTexture = self.previousTargetTexture;
}

- (BOOL)shouldProduceOutputs {
  return (self.currentIteration + 1) == self.iterationsForNextOutput;
}

- (void)produceOutputs {
  // If the intermediate buffer was the current target, it needs to be cloned to the output.
  // Otherwise, the output already contains the desired result.
  if (self.targetFbo == self.intermediateFbo) {
    [self.intermediateTexture cloneTo:self.outputFbo.texture];
  }
  ++self.nextOutputIndex;

  // Clone to all output textures that has the same iteration count.
  while (self.nextOutputIndex < self.outputs.count &&
         (self.currentIteration + 1) == self.iterationsForNextOutput) {
    [self.outputFbo.texture cloneTo:self.outputs[self.nextOutputIndex]];
    ++self.nextOutputIndex;
  }

  if (self.nextOutputIndex < self.outputs.count) {
    [self prepareNextOutput];
  }
}

- (NSUInteger)iterationsForNextOutput {
  return [self.iterationsPerOutput[self.nextOutputIndex] unsignedIntegerValue];
}

- (void)resetState {
  self.nextOutputIndex = 0;
  self.intermediateTexture = nil;
  self.intermediateFbo = nil;
  self.outputFbo = nil;
  self.sourceTexture = nil;
  self.targetFbo = nil;
  self.previousTargetTexture = nil;
}

#pragma mark -
#pragma mark Intermediate buffers
#pragma mark -

- (LTFbo *)intermediateFbo {
  if (!_intermediateFbo || _intermediateFbo.size != [self.outputs[self.nextOutputIndex] size]) {
    self.intermediateTexture = [LTTexture
                                textureWithPropertiesOf:self.outputs[self.nextOutputIndex]];
    _intermediateFbo = [[LTFbo alloc] initWithTexture:self.intermediateTexture];
  }
  return _intermediateFbo;
}

#pragma mark -
#pragma mark Public properties
#pragma mark -

- (void)setIterationsPerOutput:(NSArray *)iterationsPerOutput {
  LTParameterAssert(iterationsPerOutput.count == self.outputs.count,
                    @"Number of iterations elements must be equal to the number of outputs");

  __block NSUInteger previousIterations = 0;
  for (NSNumber *number in iterationsPerOutput) {
    NSUInteger iterations = [number unsignedIntegerValue];

    LTParameterAssert(iterations > 0, @"Number of iterations cannot be zero");
    LTParameterAssert(iterations >= previousIterations, @"Iterations list must be weakly "
                      "monotonically increasing");

    previousIterations = iterations;
  };

  _iterationsPerOutput = iterationsPerOutput;
}

- (NSArray *)iterationsPerOutput {
  if (!_iterationsPerOutput) {
    NSMutableArray *iterations = [NSMutableArray array];
    for (NSUInteger i = 0; i < self.outputs.count; ++i) {
      [iterations addObject:@(1)];
    }
    _iterationsPerOutput = [iterations copy];
  }
  return _iterationsPerOutput;
}

@end
