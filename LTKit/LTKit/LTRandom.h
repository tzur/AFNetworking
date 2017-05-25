// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

/// Object representing the internal state of a random generator. Resetting a generator to a given
/// state will yield the same sequence of random numbers (assuming the same sequence of methods is
/// called).
///
/// @note This class is thread-safe.
@interface LTRandomState : NSObject
@end

/// A random number generator class that can be shared between mutiple places, allowing generating
/// random sequences independent of other calls to random number generators throughout the system.
/// This is important since this class can be used to replay a random sequence by calling reset or
/// initializing with a specific seed.
///
/// @warning This class should be used to create pseudo random numbers and does not guarantee
/// anything regarding the strength of randomness of the generated numbers. Its sole purpose is to
/// create a randomly-looking behavior, and should not be used for any cryptographic or
/// security-related purpose.
///
/// @warning This class is not thread-safe.
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

/// Returns an uint in the range <tt>[0, \c weights.count - 1]</tt>, where the probability for a
/// number \c i to be returned is <tt>weights(i) / sum(weights)</tt>.
///
/// For example, for the \c weights vector <tt>{1, 3 ,4}</tt>, the probability that 0 will be
/// returned is 0.125 (1/(1+3+4)) and the probability 1 will be returned is 0.375 (3/(1+3+4)), the
/// probability 2 will be returned is 0.5 (4/(1+3+4)).
///
/// If all the \c weights elements are equal to the same value, the input distribution is the
/// uniform distribution and the result is equal to the call
/// <tt>randomUnsignedIntegerBelow:weights.count - 1</tt>.
///
/// @note The \c weights vector must not contain negative values, and must contain at least one
/// positive value.
- (uint)randomUnsignedIntegerWithWeights:(const std::vector<double> &)weights;

/// Initial state of the random generator.
@property (readonly, nonatomic) LTRandomState *initialState;

/// Current state of the random generator.
@property (readonly, nonatomic) LTRandomState *engineState;

@end

NS_ASSUME_NONNULL_END
