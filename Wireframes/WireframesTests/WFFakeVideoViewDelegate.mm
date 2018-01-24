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

@end

NS_ASSUME_NONNULL_END
