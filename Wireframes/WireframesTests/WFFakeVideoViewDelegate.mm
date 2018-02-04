// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFFakeVideoViewDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WFFakeVideoViewDelegate

- (void)videoViewDidLoadVideo:(WFVideoView __unused *)videoView {
}

- (void)videoViewDidFinishPlayback:(WFVideoView __unused *)videoView {
}

- (void)videoView:(WFVideoView __unused *)videoView
    didPlayVideoAtTime:(__unused NSTimeInterval)time {
}

- (void)videoView:(WFVideoView __unused *)videoView
    didEncounterVideoError:(NSError *)error {
  // Fail the test. Flakiness of playback tests in CI has been observed. It is probably because at
  // some conditions an error is reported from the player. This (temporary) assertion is in order to
  // get the details of this error from CI and understand what causes it and how to fix this
  // flakiness.
  LTAssert(NO, @"Video view did encounter video error: %@", error);
}

@end

NS_ASSUME_NONNULL_END
