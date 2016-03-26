// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTFloatSet.h"

NS_ASSUME_NONNULL_BEGIN

/// Object representing an \c LTFloatSet adhering to a periodic pattern of a finite sequence of
/// equidistant discrete values, followed by a gap. Visually, the pattern has the form
/// \c xxxx-xxxx-xxxx- (and so on), where \c xxxx represents a sequence of equidistant discrete
/// values, and \c - represents the gap between two sequences. Mathematically, the set is defined as
/// \c {p + k * d + m * s | p in R, k in {0, 1, ..., n - 1}, d in R^+, m in Z, e in R^+,
/// s > (n - 1) * d}, where \c n is the number of values per sequence.
@interface LTPeriodicFloatSet : NSObject <LTFloatSet>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c pivotValue, \c numberOfValuesPerSequence, \c valueDistance, and
/// \c sequenceDistance. The represented set is
/// \c {\c pivotValue + k * valueDistance + m * ((numberOfValuesPerSequence - 1) * valueDistance +
///     sequenceDistance) | k in {0, 1, ..., numberOfValuesPerSequence - 1}, m in Z}.
///
/// @param \c pivotValue determines the first discrete value of an arbitrary sequence.
///
/// @param \c numberOfValuesPerSequence determines the number of values per sequence. Must be a
/// positive number.
///
/// @param \c valueDistance determines the distance between any two consecutive values in any
/// sequence. Must be a positive number.
///
/// @param \c sequenceDistance determines the length of the gap between two consecutive sequences.
/// In other words, it determines the distance between the last discrete value of a sequence and the
/// first discrete value of the next sequence. Must be a positive number.
///
/// Example: A periodic float set of the form (..., -1.5, -0.5, 3.5, 4.5, 8.5, 9.5, 13.5, 14.5, ...)
/// can be specified as follows:
/// \c pivotValue: -1.5 or 3.5 or 8.5 or 13.5 ...
/// \c numberOfValuesPerSequence: 2
/// \c valueDistance: 1
/// \c sequenceDistance: 4
- (instancetype)initWithPivotValue:(CGFloat)pivotValue
         numberOfValuesPerSequence:(NSUInteger)numberOfValuesPerSequence
                     valueDistance:(CGFloat)valueDistance
                  sequenceDistance:(CGFloat)sequenceDistance NS_DESIGNATED_INITIALIZER;

/// First value of an arbitrary sequence.
@property (readonly, nonatomic) CGFloat pivotValue;

/// Number of values inside any sequence.
@property (readonly, nonatomic) NSUInteger numberOfValuesPerSequence;

/// Distance between two discrete values inside any sequence.
@property (readonly, nonatomic) CGFloat valueDistance;

/// Length of the gap between two consecutive sequences. In other words, distance between the last
/// discrete value of a sequence and the first discrete value of the next sequence.
@property (readonly, nonatomic) CGFloat sequenceDistance;

@end

NS_ASSUME_NONNULL_END
