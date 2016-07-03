// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Protocol to be implemented by objects able to cancel currently occurring touch event sequences.
@protocol LTTouchEventCancellation <NSObject>

/// Cancels all currently occurring touch event sequences provided by this instance.
- (void)cancelTouchEventSequences;

@end

NS_ASSUME_NONNULL_END
