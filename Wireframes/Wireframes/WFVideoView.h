// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WFVideoView;

/// Protocol for handling \c WFVideoView events.
@protocol WFVideoViewDelegate <NSObject>

@optional

/// Called after a video is loaded successfully by the video view.
- (void)videoDidLoad:(WFVideoView *)videoView;

/// Called after the video playback has ended.
- (void)videoDidFinishPlayback:(WFVideoView *)videoView;

/// Called when an error is encountered by the video view.
- (void)video:(WFVideoView *)videoView didFailWithError:(NSError *)error;

/// Indicates the \c progressTime of the video (in seconds) out of the \c videoDurationTime
/// (in seconds). Called in constant intervals while the video is playing.
///
/// @note This method is not guaranteed to be called from the main thread.
- (void)videoProgress:(WFVideoView *)videoView progressTime:(CGFloat)progressTime
    videoDurationTime:(CGFloat)videoDurationTime;

@end

/// Generic view for playing video. Unlike the standard \c MPMoviePlayerController, there is no
/// hard limit on the number of video views playing simultaneously.
@interface WFVideoView : UIView

/// Initializes a new video view.
///
/// @param videoProgresssIntervalTime determines the interval time (in seconds) between each call
/// to the <tt>[delgate videoProgressTime:videoDurationTime:]</tt> while the video is playing if
/// the \c delgate implements the method. Must be a positive value in any case.
/// @param playInLoop determines wheter to play the video in a loop.
- (instancetype)initWithVideoProgressIntervalTime:(CGFloat)videoProgresssIntervalTime
                                       playInLoop:(BOOL)playInLoop NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Start video playback.
- (void)play;

/// Pause video playback.
- (void)pause;

/// Pause and reset video playback.
- (void)stop;

/// \c YES if the video should be playing.
@property (readonly, nonatomic) BOOL isPlaying;

/// URL of the video to be played by this view.
@property (strong, nonatomic, nullable) NSURL *videoURL;

/// Defines how the video is displayed within the view bounds. Default is
/// \c AVLayerVideoGravityResizeAspect.
@property (strong, nonatomic) AVLayerVideoGravity videoGravity;

/// Current time of the current displayed video. If \c videoURL is \c nil, \c 0 is returned.
@property (readonly, nonatomic) NSTimeInterval currentTime;

/// Current displayed video duration. If \c videoURL is \c nil, \c 0 is returned.
@property (readonly, nonatomic) NSTimeInterval videoDuration;

/// Size of the current displayed video. If \c videoURL is \c nil, \c CGSizeZero is returned.
@property (readonly, nonatomic) CGSize videoSize;

/// Delegate.
@property (weak, nonatomic, nullable) id<WFVideoViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
