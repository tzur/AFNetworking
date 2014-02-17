// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTouchCollectorFilter.h"

/// Filters incoming \c LTPainterPoints according to the time interval passed between them,
/// accepting new points if enough time has passed between them.
@interface LTTouchCollectorTimeIntervalFilter : NSObject <LTTouchCollectorFilter>

/// Creates a filter accepting points if more than the given time interval has passed between them.
+ (instancetype)filterWithMinimalTimeInterval:(CFTimeInterval)interval;

/// Initializes a filter with the given threshold.
- (instancetype)initWithMinimalTimeInterval:(CFTimeInterval)interval;

@end
