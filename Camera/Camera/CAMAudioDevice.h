// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device capable of sending a stream of audio frames.
@protocol CAMAudioDevice <NSObject>

/// Signal that sends \c NSValues containing \c CMSampleBufferRefs with audio samples. The signal
/// completes when the receiver is deallocated or errs if there is a problem capturing audio. All
/// events are sent on an arbitrary thread.
@property (readonly, nonatomic) RACSignal *audioFrames;

@end

NS_ASSUME_NONNULL_END
