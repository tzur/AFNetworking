// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

NS_ASSUME_NONNULL_BEGIN

@class LTSplineControlPoint;

/// Stateful object constituting a FIFO queue buffering \c LTSplineControlPoint objects based on
/// their \c timestamp and their speed.
///
/// Incoming control points are buffered as long as the period of time which passed between their
/// \c timestamp and the \c timestamp of the last processed control point is smaller than a certain
/// threshold.
///
/// The aforementioned threshold is dynamically computed as follows: the speed of a processed
/// control point is converted into a factor between \c 0 and \c 1, by dividing it by the value of
/// the \c maxSpeed property of the used class instance and clamping it. The factor is then used to
/// compute the time interval allowed between the \c timestamp of the discussed control point and
/// the last buffered control point. The range of time intervals is determined by the
/// \c timeInterval property.
///
/// Objects of this class provide a \c flush method which returns all buffered control points.
///
/// @note It is guaranteed that the control points are always returned in the order in which they
/// have been inserted into the buffer.
@interface LTSpeedBasedSplineControlPointBuffer : NSObject

/// Initializes with \c maxSpeed equalling \c 5000 and \c timeIntervals equalling
/// <tt>[1.0 / 120, 1.0 / 20]</tt>.
- (instancetype)init;

/// Initializes with the given \c maxSpeed and \c timeIntervals. The given \c maxSpeed must be
/// positive.
- (instancetype)initWithMaxSpeed:(CGFloat)maxSpeed
                   timeIntervals:(lt::Interval<NSTimeInterval>)timeIntervals
    NS_DESIGNATED_INITIALIZER;

/// Returns a subset of the given \c controlPoints, potentially in conjunction with control points
/// which have previously been buffered. If \c flush is \c YES, all buffered control points
/// concatenated with the given \c controlPoints are returned.
///
/// @important The method assumes that the \c timestamp values of the given \c controlPoints are
/// strictly monotonically increasing, also across different method calls.
- (NSArray<LTSplineControlPoint *> *)
    processAndPossiblyBufferControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints
    flush:(BOOL)flush;

/// Control points currently buffered by this instance.
@property (readonly, nonatomic) NSArray<LTSplineControlPoint *> *bufferedControlPoints;

/// Maximum speed used for determining whether an incoming control point is buffered. Is
/// non-negative.
@property (nonatomic) CGFloat maxSpeed;

/// Interval of time intervals used for determining how long an incoming control point is buffered.
/// A control point with speed \c 0 (\c maxSpeed) is returned once the difference between the
/// \c timestamp of the last processed control point and its \c timestamp is greater than
/// \c timeIntervals.min() (\c timeIntervals.max()).
@property (nonatomic) lt::Interval<NSTimeInterval> timeIntervals;

@end

NS_ASSUME_NONNULL_END
