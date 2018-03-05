// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFVideoView.h"

NS_ASSUME_NONNULL_BEGIN

/// Mocking class for the \c WFVideoViewDelegate protocol.
@interface WFFakeVideoViewDelegate : NSObject <WFVideoViewDelegate>

/// Number of times this delegate was called to notify a video was loaded.
@property (readonly, nonatomic) NSUInteger numberOfVideoLoads;

/// Number of times this delegate was called to notify a playback was finished.
@property (readonly, nonatomic) NSUInteger numberOfPlaybacksFinished;

/// Array with an entry for each time this delegate was called to notify that a video is playing.
/// The order of entries is the order of the calls to the delegate. Each entry contains the time
/// that was passed to the delegate as a parameter of the call.
@property (readonly, nonatomic) NSArray<NSNumber *> *playbackNotificationTimes;

@end

NS_ASSUME_NONNULL_END
