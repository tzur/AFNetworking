// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTJSONSerializationAdapter.h"
#import "LTKeyPathCoding.h"

/// Abstract class for generic image processing mechanism. The mechanism accepts a varying number of
/// inputs, including textures and an input model, and produces a varying number of outputs. Once
/// constructed, the processor has fixed inputs and outputs, but its input model can be changed.
///
/// The class supports serialization and deserialization of the input model in a form of a
/// dictionary. To support this feature, subclasses should override the \c modelInputProperties
/// getter and return a set of properties which comprise the input model.
@interface LTImageProcessor : NSObject <LTJSONSerializing>

#pragma mark -
#pragma mark Processing
#pragma mark -

/// Overriding point for classes that wish to execute code prior to processing. This method will be
/// called by processing methods. The default implementation has no effect.
- (void)preprocess;

/// Generates a new output based on the current image processor inputs. This method blocks until a
/// result is available. This is an abstract method that must be overridden by subclasses.
- (void)process;

#pragma mark -
#pragma mark Input model
#pragma mark -

/// Keys of the model input properties of this object that are part of the model to load and save.
/// The default implementation returns \c nil, therefore no properties are part of the input model.
+ (NSSet *)inputModelPropertyKeys;

/// Sets the given input model to the object. Keys set of the \c model must be equal to the
/// \c modelProperties.
- (void)setInputModel:(NSDictionary *)model;

/// Returns the input model properties defined in \c modelProperties to a dictionary, where each key
/// is the property name and the value is the property's value.
- (NSDictionary *)inputModel;

/// Default input model of the processor. The initial state for each input model property is defined
/// by the value returned from \c -default<property name>. If such selector does not exist, an
/// assert will be thrown.
- (NSDictionary *)defaultInputModel;

/// Returns the default value for a given input model key, or \c nil if the \c key is not one of the
/// input model's keys. If no default value exists for a valid property key, an assert will be
/// thrown.
- (id)defaultValueForKey:(NSString *)key;

/// Resets the input model to its initial state. The initial state for each input model property is
/// defined by the value returned from \c -default<property name>. If such selector does not exist,
/// an assert will be thrown.
- (void)resetInputModel;

/// Resets the input model, as defined in \c resetInputModel, but doesn't set the keys given in \c
/// keys.
- (void)resetInputModelExceptKeys:(NSSet *)keys;

/// Resets the input model key specified by \c key to it's default value. If \c key is not one of
/// the input model's keys nothing is done. If no default value has been found for \c key an assert
/// will be thrown.
- (void)resetValueForKey:(NSString *)key;

/// \c YES if the processor, while the input model is the default input model, copies the input
/// directly to the output (e.g. passthrough mode) without no change. The default value is \c YES.
+ (BOOL)isPassthroughForDefaultInputModel;

@end
