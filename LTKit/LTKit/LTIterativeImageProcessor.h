// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUImageProcessor.h"

/// @class LTIterativeImageProcessor
///
/// Processor that can run the processing phase more than once. Users of this class can define the
/// number of iterations per output, and a configuration step prior to each iteration.
@interface LTIterativeImageProcessor : LTGPUImageProcessor

/// Initializes with a program, a source texture and an array of outputs.
- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)sourceTexture
                        outputs:(NSArray *)outputs;

/// Initializes with a program, a source texture, auxiliary textures to assist processing and an
/// array of outputs.
- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)sourceTexture
              auxiliaryTextures:(NSDictionary *)auxiliaryTextures outputs:(NSArray *)outputs;

/// Method to be called before each drawing iteration. Override this in subclasses in order to
/// prepare the processor correctly before processing.
- (void)iterationStarted:(NSUInteger)iteration;

/// Number of iterations needed to produce each output of the processor, corresponding to their
/// ordering in \c outputs. The size of the array must be similar to the number of the processor's
/// outputs, each value must be greater than 0 and the values must be weakly monotonically
/// increasing. The default value is \c 1 times the number of outputs.
@property (strong, nonatomic) NSArray *iterationsPerOutput;

@end
