// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessorOutput.h"

/// Protocol for generic image processing mechanism. The mechanism accepts a varying number of
/// inputs, including textures and an input model, and produces a varying number of outputs. Once
/// constructed, the processor has fixed inputs and outputs, but its input model can be changed.
@protocol LTImageProcessor <NSObject>

/// Generates a new output based on the current image processor inputs. This method blocks until a
/// result is available.
- (id<LTImageProcessorOutput>)process;

/// Sets a processor's input model object value for the given \c key.
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

/// Returns the input model object for the given \c key.
- (id)objectForKeyedSubscript:(NSString *)key;

@end
