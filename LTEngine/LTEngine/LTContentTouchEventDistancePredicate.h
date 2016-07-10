// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventPredicate.h"

NS_ASSUME_NONNULL_BEGIN

/// Possible distance metrics supported by the \c LTContentTouchEventDistancePredicate.
typedef NS_ENUM(NSUInteger, LTContentTouchEventDistancePredicateType) {
  /// Distance is measured between the \c viewLocation properties of the events.
  LTContentTouchEventDistancePredicateTypeView = 0,
  /// Distance is measured between the \c contentLocation properties of the events.
  LTContentTouchEventDistancePredicateTypeContent
};

/// Immutable object predicating \c id<LTContentTouchEvents> objects according to the Euclidean
/// distance between their \c contentLocation or \c viewLocation values.
@interface LTContentTouchEventDistancePredicate : NSObject <LTContentTouchEventPredicate>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given type and threshold distance.
- (instancetype)initWithType:(LTContentTouchEventDistancePredicateType)type
             minimumDistance:(CGFloat)distance NS_DESIGNATED_INITIALIZER;

/// Returns a distance predicate accepting events with view distance above the given threshold.
+ (instancetype)predicateWithMinimumViewDistance:(CGFloat)distance;

/// Returns a distance predicate accepting events with content distance above the given threshold.
+ (instancetype)predicateWithMinimumContentDistance:(CGFloat)distance;

/// Type of distance metric used by the predicate, see \c LTContentTouchEventDistancePredicateType
/// for more details.
@property (readonly, nonatomic) LTContentTouchEventDistancePredicateType type;

/// Distance threshold for accepting events. An event is considered valid if the distance between
/// its \c contentLocation (or \c viewLocation, respectively) and the \c contentLocation
/// (\c viewLocation) of the \c baseEvent is greater than this threshold.
@property (readonly, nonatomic) CGFloat minimumDistance;

@end

NS_ASSUME_NONNULL_END
