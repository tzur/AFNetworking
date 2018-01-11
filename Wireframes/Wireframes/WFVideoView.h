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
- (void)videoProgress:(WFVideoView *)videoView progressTime:(NSTimeInterval)progressTime
    videoDurationTime:(NSTimeInterval)videoDurationTime;

@end

/// Generic view for playing video. Unlike the standard \c MPMoviePlayerController, there is no
/// hard limit on the number of video views playing simultaneously.
@interface WFVideoView : UIView

/// Start video playback.
- (void)play;

/// Pause video playback.
- (void)pause;

/// Pause and reset video playback.
- (void)stop;

/// \c YES if \c play was called and no calls to \c stop, \c pause, or \c setVideoURL were done
/// after it.
@property (readonly, nonatomic) BOOL playbackRequested;

/// URL of the video to be played by this view.
@property (strong, nonatomic, nullable) NSURL *videoURL;

/// Defines how the video is displayed within the view bounds. Default is
/// \c AVLayerVideoGravityResizeAspect.
@property (strong, nonatomic) AVLayerVideoGravity videoGravity;

/// Time Interval between each call to the <tt>[delgate videoProgressTime:videoDurationTime:]</tt>
/// while the video is playing if the \c delgate implements the method. Must be a positive value in
/// any case. Default value is \c 1.0.
@property (nonatomic) NSTimeInterval progressSamplingInterval;

/// \c YES if the playback should automatically repeat after video ends. Default is \c NO.
@property (nonatomic) BOOL repeat;

/// Current time of the current displayed video. If \c videoURL is \c nil, \c 0 is returned. This
/// property is not key-value observable. The delegate's method
/// \c videoProgress:progressTime:videoDurationTime: can be used for observing this property.
@property (readonly, nonatomic) NSTimeInterval currentTime;

/// Current displayed video duration. If \c videoURL is \c nil, \c 0 is returned.
@property (readonly, nonatomic) NSTimeInterval videoDuration;

/// Size of the current displayed video. If \c videoURL is \c nil, \c CGSizeZero is returned.
@property (readonly, nonatomic) CGSize videoSize;

/// Delegate.
@property (weak, nonatomic, nullable) id<WFVideoViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
