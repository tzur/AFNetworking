// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#pragma mark -
#pragma mark Sampler
#pragma mark -

typedef std::vector<float> Floats;

/// Protocol for a 1D random sampler given a frequency table.
@protocol LTDistributionSampler <NSObject>

/// Initializes with a given \c frequencies, where each element in the array is \c float.
/// The value of each frequency cell is equal to its cell index probability to be returned from
/// the sampling method. The given \c frequencies can be unnormalized, but must not be empty. Each
/// fequency must be non-negative and the sum of frequencies must be positive.
- (instancetype)initWithFrequencies:(const Floats &)frequencies;

/// Returns the given number of samples in the range [0, frequencies.count) from the distribution.
- (NSArray *)sample:(NSUInteger)times;

@end

/// Class for sampling indices at random from any given distribution. User of this class initializes
/// it with a given (possibly non-normalized) 1D frequency table in the form index->frequency.
/// Afterwards, it's possible to generate samples (indices) that behave (at large enough number of
/// samples) as the given distribution.
///
/// @see http://en.wikipedia.org/wiki/Inverse_transform_sampling for more information on this
/// method.
@interface LTInverseTransformSampler : NSObject <LTDistributionSampler>
@end

#pragma mark -
#pragma mark Factory
#pragma mark -

/// Protocol for creating distribution sampler.
@protocol LTDistributionSamplerFactory

/// Returns a sampler initialized with the given \c frequencies.
///
/// @see -[LTDistributionSampler initWithFrequencies:] for more information.
- (id<LTDistributionSampler>)samplerWithFrequencies:(const Floats &)frequencies;

@end

@interface LTInverseTransformSamplerFactory : NSObject <LTDistributionSamplerFactory>
@end
