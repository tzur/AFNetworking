// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIterativeImageProcessor.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLTexture.h"
#import "LTRectDrawer.h"

@interface LTIterativeImageProcessor ()

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

@implementation LTIterativeImageProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProgram:(LTProgram *)program inputs:(NSArray *)inputs
                        outputs:(NSArray *)outputs {
  if (self = [super initWithProgram:program inputs:inputs outputs:outputs]) {
    LTParameterAssert([self outputTexturesAreSimilar], @"Output textures doesn't have the same "
                      "size, precision or number of channels");
    self.iterationsPerOutput = [self defaultIterationsPerOutputWithCount:outputs.count];
  }
  return self;
}

- (BOOL)outputTexturesAreSimilar {
  LTTexture *firstOutput = [self.outputs firstObject];

  for (NSUInteger i = 1; i < self.outputs.count; ++i) {
    LTTexture *output = self.outputs[i];
    if (output.size != firstOutput.size ||
        output.precision != firstOutput.precision ||
        output.channels != firstOutput.channels) {
      return NO;
    }
  }

  return YES;
}

- (NSArray *)defaultIterationsPerOutputWithCount:(NSUInteger)count {
  NSMutableArray *iterations = [NSMutableArray array];
  for (NSUInteger i = 0; i < count; ++i) {
    [iterations addObject:@1];
  }
  return iterations;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (NSArray *)drawToOutput {
  [self prepareNextOutput];

  for (NSUInteger i = 0; i < self.totalNumberOfIterations; ++i) {
    if (self.iterationStartedBlock) {
      self.iterationStartedBlock(i);
    }

    [self setSourceTextureAndTargetFboForIteration:i];
    [self drawToTarget];

    if ([self shouldProduceOutputAfterIteration:i]) {
      [self produceOutputAfterIteration:i];
    }
  }

  [self resetState];

  return self.outputs;
}

- (void)prepareNextOutput {
  LTTexture *outputTexture = self.outputs[self.nextOutputIndex];
  self.outputFbo = [[LTFbo alloc] initWithTexture:outputTexture];
}

- (NSUInteger)totalNumberOfIterations {
  return [[self.iterationsPerOutput lastObject] unsignedIntegerValue];
}

- (void)setSourceTextureAndTargetFboForIteration:(NSUInteger)iteration {
  self.previousTargetTexture = self.targetFbo.texture ?: [self.inputs firstObject];

  // Toggle between source -> itermediate, intermediate -> output and output -> intermediate.
  if (iteration == 0) {
    if (self.totalNumberOfIterations > 1) {
      self.targetFbo = self.intermediateFbo;
    } else {
      // For a single iteration, no intermediate texture or framebuffer are needed.
      self.targetFbo = self.outputFbo;
    }
  } else if (iteration % 2) {
    self.targetFbo = self.outputFbo;
  } else {
    self.targetFbo = self.intermediateFbo;
  }

  self.sourceTexture = self.previousTargetTexture;
}

- (void)drawToTarget {
  CGRect rect = CGRectFromOriginAndSize(CGPointZero, self.sourceTexture.size);
  [self.rectDrawer setSourceTexture:self.sourceTexture];
  [self.rectDrawer drawRect:rect inFramebuffer:self.targetFbo fromRect:rect];
}

- (BOOL)shouldProduceOutputAfterIteration:(NSUInteger)iteration {
  return (iteration + 1) == self.iterationsForNextOutput;
}

- (void)produceOutputAfterIteration:(NSUInteger)iteration {
  // If the intermediate buffer was the current target, it needs to be cloned to the output.
  // Otherwise, the output already contains the desired result.
  if (self.targetFbo == self.intermediateFbo) {
    [self.intermediateTexture cloneTo:self.outputFbo.texture];
  }
  ++self.nextOutputIndex;

  // Clone to all output textures that has the same iteration count.
  while (self.nextOutputIndex < self.outputs.count &&
         (iteration + 1) == self.iterationsForNextOutput) {
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

- (LTTexture *)intermediateTexture {
  if (!_intermediateTexture) {
    LTTexture *similar = [self.outputs lastObject];
    _intermediateTexture = [[LTGLTexture alloc] initWithSize:similar.size
                                                   precision:similar.precision
                                                    channels:similar.channels
                                              allocateMemory:YES];
  }
  return _intermediateTexture;
}

- (LTFbo *)intermediateFbo {
  if (!_intermediateFbo) {
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

@end
