// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for controlling the time interval of a timer.
@protocol CAMTimerContainer <NSObject>

/// Time interval of the timer.
@property (nonatomic) NSTimeInterval interval;

@end

NS_ASSUME_NONNULL_END
