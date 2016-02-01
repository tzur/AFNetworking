// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

/// Represents the internal state of the random generator. Reseting the generator to a given state
/// will yield the same sequence of random numbers (assuming the same sequence of methods are
/// called).
@interface LTRandomState : NSObject
@end

/// A random number generator class that can be shared between mutiple places, allowing generating
/// random sequences independent of other calls to random number generators throughout the system.
/// This is important since this class can be used to replay a random sequence by calling reset or
/// initializing with a specific seed.
///
/// @note This class should be used to create pseudo random numbers and does not gurantee anything
/// about the strength of randomness of the generated numbers. Its purpose is for creating a
/// randomly-looking behavior, and should not be used for any cryptographic or security-related
/// purpose.
@interface LTRandom : NSObject

/// Initializes the random generator with a randomly generated state.
- (instancetype)init;

/// Initializes the random generator with a state generated using the given \c seed.
- (instancetype)initWithSeed:(NSUInteger)seed;

/// Initializes the random generator with the given state.
- (instancetype)initWithState:(LTRandomState *)state NS_DESIGNATED_INITIALIZER;

/// Resets the random generator to its initial state.
- (void)reset;

/// Resets the random generator to the given state.
- (void)resetToState:(LTRandomState *)state;

/// Returns a uniformly distributed random double in range [0,1].
- (double)randomDouble;

/// Returns a uniformly distributed random double in range [min,max].
- (double)randomDoubleBetweenMin:(double)min max:(double)max;

/// Returns a uniformly distributed \c NSInteger in range [min,max].
- (int)randomIntegerBetweenMin:(int)min max:(int)max;

/// Returns a uniformly distributed \c NSUInteger in range [0,max-1].
- (uint)randomUnsignedIntegerBelow:(uint)max;

/// Initial state of the random generator.
@property (readonly, nonatomic) LTRandomState *initialState;

/// Returns the internal state of the random generator.
@property (readonly, nonatomic) LTRandomState *engineState;

@end

NS_ASSUME_NONNULL_END
