// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTNextIterationPlacement.h"

/// Protocol for defining a strategy for processing an input using \c LTImageProcessor. The strategy
/// describes the number of iterations needed to execute until the output is ready, prepares the
/// input for processing and generates the final output of the processor.
@protocol LTProcessingStrategy <NSObject>

/// Notifies that a new call for processing is requested.
- (void)processingWillBegin;

/// If another processing iteration is required, returns \c YES.
- (BOOL)hasMoreIterations;

/// Returns the next iteration placement, or \c nil if \c shouldContinueProcessing is \c NO. Must
/// be called at the beginning of each output iteration.
- (LTNextIterationPlacement *)iterationStarted;

/// Notifies the strategy that an iteration has ended, giving it chance to generate proper output
/// textures. Returns a dictionary with the output textures that has been created in this iteration
/// (which can be empty or \c nil).
- (void)iterationEnded;

/// Retrieves the output textures that were processed so far.
- (id<LTImageProcessorOutput>)processedOutputs;

@end
