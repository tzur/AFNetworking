// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for object that provides the current time.
@protocol BZRTimeProvider <NSObject>

/// Returns a signal that sends the current time as \c NSDate and completes. The time can be the
/// time on another computer/device. The signal errs if there was an error getting the current time.
///
/// @return <tt>RACSignal<NSDate></tt>
- (RACSignal *)currentTime;

@end

/// Default implementation that provides the current time on the currently running device.
@interface BZRTimeProvider : NSObject <BZRTimeProvider>
@end

NS_ASSUME_NONNULL_END
