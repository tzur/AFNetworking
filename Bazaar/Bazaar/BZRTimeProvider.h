// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Wrapper for returning current time.
@interface BZRTimeProvider : NSObject

/// Returns the default implementation of \c BZRTimeProvider.
+ (BZRTimeProvider *)defaultTimeProvider;

/// Returns the current time.
- (NSDate *)currentTime;

@end

NS_ASSUME_NONNULL_END
