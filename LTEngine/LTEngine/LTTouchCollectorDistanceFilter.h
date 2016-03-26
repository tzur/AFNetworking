// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTouchCollectorFilter.h"

/// Possible distance metrics supported by the \c LTTouchCollectorDistanceFilter.
typedef NS_ENUM(NSUInteger, LTTouchCollectorDistanceType) {
  LTTouchCollectorDistanceScreen = 0,
  LTTouchCollectorDistanceContent
};

/// Filters incoming \c LTPainterPoints according to the distance between them (in either screen or
/// content coordinate system).
@interface LTTouchCollectorDistanceFilter : NSObject <LTTouchCollectorFilter>

/// Creates a distance filter accepting points with screen distance above the given threshold.
///
/// @param distance must be a non-negative value.
+ (instancetype)filterWithMinimalScreenDistance:(CGFloat)distance;

/// Creates a distance filter accepting points with content distance above the given threshold.
///
/// @param distance must be a non-negative value.
+ (instancetype)filterWithMinimalContentDistance:(CGFloat)distance;

/// Initializes the filter with the given type and threshold distance.
///
/// @param distance must be a non-negative value.
- (instancetype)initWithType:(LTTouchCollectorDistanceType)type minimalDistance:(CGFloat)distance;

@end
