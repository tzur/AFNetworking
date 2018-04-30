// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for object that provides the current time.
@protocol BZRTimeProvider <NSObject>

/// Returns a signal that sends the current time as \c NSDate and completes. The time can be the
/// time on another computer/device. The signal cannot err.
- (RACSignal<NSDate *> *)currentTime;

@end

/// Default implementation that provides the current time on the currently running device.
@interface BZRTimeProvider : NSObject <BZRTimeProvider>

/// Returns the default implementation of \c BZRTimeProvider.
+ (BZRTimeProvider *)defaultTimeProvider;

@end

NS_ASSUME_NONNULL_END
