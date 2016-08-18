// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Contains functions used to convert between time units.
@interface BZRTimeConversion : NSObject

/// Returns the number of seconds in \c days.
+ (NSTimeInterval)numberOfSecondsInDays:(NSUInteger)days;

@end

NS_ASSUME_NONNULL_END
