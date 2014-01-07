// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectImageProcessor.h"

/// Callback for indicating a beginning of a new processing iteration.
///
/// @param iteration iteration number.
typedef void (^LTIterativeImageProcessorIterationStartedBlock)(NSUInteger iteration);

/// @class LTIterativeImageProcessor
///
/// Processor that can run the processing phase more than once. Users of this class can define the
/// number of iterations per output, and a configuration step prior to each iteration.
@interface LTIterativeImageProcessor : LTRectImageProcessor

/// Initializes with the program and arrays of input and output textures.
///
/// @param program the program used to process the input textures.
/// @param inputs array of \c LTTexture objects, which correspond to the input images to process.
/// @param output array of \c LTTexture objects, which correspond to the output images to produce.
/// All textures must have the same size, precision and number of channels.
- (instancetype)initWithProgram:(LTProgram *)program inputs:(NSArray *)inputs
                        outputs:(NSArray *)outputs;

/// Number of iterations needed to produce each output of the processor, corresponding to their
/// ordering in \c outputs. The size of the array must be similar to the number of the processor's
/// outputs, each value must be greater than 0 and the values must be weakly monotonically
/// increasing. The default value is \c 1 times the number of outputs.
@property (strong, nonatomic) NSArray *iterationsPerOutput;

/// Block called before each drawing iteration.
@property (copy, nonatomic) LTIterativeImageProcessorIterationStartedBlock iterationStartedBlock;

@end
