// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFFakeVideoViewDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFFakeVideoViewDelegate ()
@property (readwrite, nonatomic) NSUInteger numberOfVideoLoads;
@property (readwrite, nonatomic) NSUInteger numberOfPlaybacksFinished;
@property (readwrite, nonatomic) NSArray<NSNumber *> *playbackNotificationTimes;
@end

@implementation WFFakeVideoViewDelegate

- (instancetype)init {
  if (self = [super init]) {
    self.playbackNotificationTimes = @[];
  }
  return self;
}

- (void)videoViewDidLoadVideo:(WFVideoView __unused *)videoView {
  ++self.numberOfVideoLoads;
}

- (void)videoViewDidFinishPlayback:(WFVideoView __unused *)videoView {
  ++self.numberOfPlaybacksFinished;
}

- (void)videoView:(WFVideoView __unused *)videoView didPlayVideoAtTime:(NSTimeInterval)time {
  self.playbackNotificationTimes = [self.playbackNotificationTimes arrayByAddingObject:@(time)];
}

- (void)videoView:(WFVideoView __unused *)videoView
    didEncounterVideoError:(NSError __unused *)error {
}

@end

NS_ASSUME_NONNULL_END
