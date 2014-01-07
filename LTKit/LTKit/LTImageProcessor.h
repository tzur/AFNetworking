// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessorOutput.h"

/// @class LTImageProcessor
///
/// Abstract class for image processing mechanism. The mechanism accepts a varying number of inputs,
/// including textures and model values, and produces a varying number of outputs. Once constructed,
/// the processor has fixed inputs and outputs, but its model values can be changed.
@interface LTImageProcessor : NSObject

/// Initializes with an arrays of input and output textures.
///
/// @param inputs array of \c LTTexture objects, which correspond to the input images to process.
/// The array cannot be empty.
/// @param outputs array of \c LTTexture objects, which correspond to existing texture to write the
/// output data to. The array cannot be empty.
- (instancetype)initWithInputs:(NSArray *)inputs outputs:(NSArray *)outputs;

/// Generates a new output based on the current image processor inputs. This method blocks until a
/// result is available.
- (id<LTImageProcessorOutput>)process;

/// Sets a processor's input model object value for the given \c key.
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

/// Returns the input model object for the given \c key.
- (id)objectForKeyedSubscript:(NSString *)key;

/// Input array of \c LTTexture objects.
@property (readonly, nonatomic) NSArray *inputs;

/// Output array of \c LTTexture objects.
@property (readonly, nonatomic) NSArray *outputs;

@end
