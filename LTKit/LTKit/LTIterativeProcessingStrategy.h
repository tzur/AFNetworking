// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUImageProcessor.h"

/// Callback for indicating a beginning of a new processing iteration.
///
/// @param iteration iteration number.
typedef void (^LTIterationStartedBlock)(NSUInteger iteration);

/// An iterative processing strategy, which produces a set of outputs from a single input using
/// successive refinement. The strategy accepts the number of iterations per output, and is able to
/// call client code at the beginning of each iteration in case a customization is required.
@interface LTIterativeProcessingStrategy : NSObject <LTProcessingStrategy>

/// Initializes with a single input texture and an array of output textures. Additional auxiliary
/// input textures should be configured via the processor itself, and not in this strategy. Given
/// input and outputs should not be \c nil.
- (instancetype)initWithInput:(LTTexture *)input andOutputs:(NSArray *)outputs;

/// Number of iterations needed to produce each output, corresponding to their ordering in \c
/// outputs. The size of the array must be similar to the number of outputs, where each value must
/// be greater than 0 and the values must be weakly monotonically increasing. The default value is
/// \c 1 times the number of outputs.
@property (strong, nonatomic) NSArray *iterationsPerOutput;

/// Called when an iteration has started.
@property (copy, nonatomic) LTIterationStartedBlock iterationStartedBlock;

@end
