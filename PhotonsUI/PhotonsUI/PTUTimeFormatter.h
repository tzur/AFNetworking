// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Zur Tene.

#import <CoreMedia/CMTime.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol for time formatter.
@protocol PTUTimeFormatter <NSObject>

/// Returns formatted \c NSString of the given \c time.
- (NSString *)timeStringForTime:(CMTime)time;

/// Returns formatted \c NSString of the given \c timeInterval.
- (NSString *)timeStringForTimeInterval:(NSTimeInterval)timeInterval;

@end

/// Concrete implementation of \c PTUTimeFormatter.
@interface PTUTimeFormatter : NSObject <PTUTimeFormatter>
@end

NS_ASSUME_NONNULL_END
