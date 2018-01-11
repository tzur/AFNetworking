// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFFakeVideoViewDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WFFakeVideoViewDelegate

- (void)videoDidLoad:(WFVideoView __unused *)videoView {
}

- (void)videoDidFinishPlayback:(WFVideoView __unused *)videoView {
}

- (void)videoProgress:(WFVideoView __unused *)videoView
         progressTime:(__unused NSTimeInterval)progressTime
    videoDurationTime:(__unused NSTimeInterval)videoDurationTime {
}

@end

NS_ASSUME_NONNULL_END
