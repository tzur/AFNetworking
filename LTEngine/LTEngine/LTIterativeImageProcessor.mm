// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIterativeImageProcessor.h"

#import "LTIterativeProcessingStrategy.h"
#import "LTProgramFactory.h"
#import "LTRectDrawer.h"
#import "LTTexture.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) LTIterativeProcessingStrategy *strategy;
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTIterativeImageProcessor ()

/// Input texture of the processor.
@property (readwrite, nonatomic) LTTexture *inputTexture;

/// Output textures of the processor.
@property (readwrite, nonatomic) NSArray *outputTextures;

@end

@implementation LTIterativeImageProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                             outputs:(NSArray *)outputs {
  return [self initWithVertexSource:vertexSource
                     fragmentSource:fragmentSource
                      sourceTexture:sourceTexture
                  auxiliaryTextures:nil
                            outputs:outputs];
}

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                   auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                             outputs:(NSArray *)outputs {
  LTParameterAssert([self outputTexturesAreSimilar:outputs],
                    @"Output textures doesn't have the same precision or number of channels");

  LTProgram *program = [[[self class] programFactory] programWithVertexSource:vertexSource
                                                               fragmentSource:fragmentSource];
  LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithProgram:program
                                                     sourceTexture:sourceTexture];
  id<LTProcessingStrategy> strategy = [self createStrategyWithSourceTexture:sourceTexture
                                                                 andOutputs:outputs];
  if (self = [super initWithDrawer:rectDrawer strategy:strategy
              andAuxiliaryTextures:auxiliaryTextures]) {
    self.inputTexture = sourceTexture;
    self.outputTextures = outputs;
    self.iterationsPerOutput = [self defaultIterationsPerOutputWithCount:outputs.count];
  }
  return self;
}

- (id<LTProcessingStrategy>)createStrategyWithSourceTexture:(LTTexture *)sourceTexture
                                                 andOutputs:(NSArray *)outputs {
  LTIterativeProcessingStrategy *strategy = [[LTIterativeProcessingStrategy alloc]
                                             initWithInput:sourceTexture andOutputs:outputs];
  @weakify(self);
  strategy.iterationStartedBlock = ^(NSUInteger iteration) {
    @strongify(self);
    [self iterationStarted:iteration];
  };

  return strategy;
}

- (BOOL)outputTexturesAreSimilar:(NSArray *)outputs {
  LTTexture *firstOutput = [outputs firstObject];

  for (NSUInteger i = 1; i < outputs.count; ++i) {
    LTTexture *output = outputs[i];
    if (output.precision != firstOutput.precision ||
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

- (void)setIterationsPerOutput:(NSArray *)iterationsPerOutput {
  self.strategy.iterationsPerOutput = iterationsPerOutput;
}

- (NSArray *)iterationsPerOutput {
  return self.strategy.iterationsPerOutput;
}

- (void)iterationStarted:(NSUInteger __unused)iteration {
  // This method should be overridden by subclasses.
}

@end
