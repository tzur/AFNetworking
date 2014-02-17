// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterPoint.h"

/// This protocol is used by the \c LTTouchCollector to filter incoming \c LTPainterPoints.
@protocol LTTouchCollectorFilter <NSObject>

/// returns \c YES if the new point should be accpeted, \c NO otherwise.
- (BOOL)acceptNewPoint:(LTPainterPoint *)newPoint withOldPoint:(LTPainterPoint *)oldPoint;

@end

/// Abstract class for complex filters composed from multiple filters.
@interface LTTouchCollectorMultiFilter : NSObject <LTTouchCollectorFilter>

/// Initializes the complex filter with the list of sub-filters.
- (instancetype)initWithFilters:(NSArray *)filters;

@end

/// \c AND filter, which accepts if all its filters accept the new point, or if it has no filters.
@interface LTTouchCollectorAndFilter : LTTouchCollectorMultiFilter

@end

/// \c OR filter, which accepts if any of its filters accept the new point, or if it has no filters.
@interface LTTouchCollectorOrFilter : LTTouchCollectorMultiFilter

@end