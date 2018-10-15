// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WFVideoView;

/// Protocol for handling \c WFVideoView events.
@protocol WFVideoViewDelegate <NSObject>

@optional

/// Called after a video is loaded successfully by the video view.
- (void)videoViewDidLoadVideo:(WFVideoView *)videoView;

/// Called after the video playback has ended.
- (void)videoViewDidFinishPlayback:(WFVideoView *)videoView;

/// Called when a video error is encountered by the video view, and the view can no longer play the
/// video. Can be called as a response to loading the video, but also after successful loading in
/// case the error encountered after the loading.
- (void)videoView:(WFVideoView *)videoView didEncounterVideoError:(NSError *)error;

/// Indicates the \c videoView played until \c time of the currently displayed video (in seconds).
/// Called periodically at the interval specified by the property \c progressSamplingInterval of the
/// \c WFVideoView object that this delegate is assigned to, interpreted according to the timeline
/// of the current video. Also called whenever playback starts or stops. If
/// \c progressSamplingInterval corresponds to a very short interval in real time, this method may
/// be called less frequently than requested. Even so, it is called sufficiently often for the
/// client to update indications of the current time appropriately in its end-user interface.
- (void)videoView:(WFVideoView *)videoView didPlayVideoAtTime:(NSTimeInterval)time;

@end

/// Generic view for playing video. Unlike the standard \c MPMoviePlayerController, there is no
/// hard limit on the number of video views playing simultaneously.
@interface WFVideoView : UIView

/// Loads the video from the given \c videoURL asynchronously. Once done notifies the delegate and
/// sets the \c currentItem property (even if failed loading the video). If \c videoURL is \c nil
/// the \c currentItem property will be synchronously set to \c nil and no video will be loaded.
/// Playback will start automatically if after successful loading \c playbackRequested is \c YES.
/// The URL is accessible after loading is done, by casting \c currentItem.asset to AVURLAsset.
- (void)loadVideoFromURL:(nullable NSURL *)videoURL;

/// Loads the video from the given \c playerItem asynchronously. Once done notifies the delegate and
/// sets the \c currentItem property (even if failed loading the video). If \c playerItem is \c nil
/// the \c currentItem property will be synchronously set to \c nil and no video will be loaded.
/// Playback will start automatically if after successful loading \c playbackRequested is \c YES.
- (void)loadVideoWithPlayerItem:(nullable AVPlayerItem *)playerItem;

/// Starts video playback. If this method was called when the video was not yet loaded, the playback
/// starts automatically after loading succeeded (unless calls to \c stop, \c pause, or were done
/// after calling \c play).
- (void)play;

/// Pauses video playback.
- (void)pause;

/// Pauses and resets video playback.
- (void)stop;

/// \c YES if \c play was called and no calls to \c stop or \c pause were done after it.
@property (readonly, nonatomic) BOOL playbackRequested;

/// player item of the current video of this view. This property is not immediately updated after
/// calling the load method but only after the asynchronous load operation was done (even if loading
/// failed). Not KVO compliant.
@property (readonly, nonatomic, nullable) AVPlayerItem *currentItem;

/// Defines how the video is displayed within the view bounds. Default value is
/// \c AVLayerVideoGravityResizeAspect.
@property (strong, nonatomic) AVLayerVideoGravity videoGravity;

/// Requested time interval between each notification of the current video time to the \c delegate.
/// See \c WFVideoViewDelegate documentation for more details. Must be a positive value. Default
/// value is \c 1.0. For best performance don't set to lower value than necessary.
@property (nonatomic) NSTimeInterval progressSamplingInterval;

/// \c YES if the playback should automatically repeat after video ends. Default value is \c NO.
@property (nonatomic) BOOL repeatsOnEnd;

/// Current time of the current video. If \c currentItem is \c nil, \c 0 is returned. This property
/// is not key-value observable. The \c delegate is being notified periodically of changes in this
/// property and can be used for observing it.
@property (readonly, nonatomic) NSTimeInterval currentTime;

/// Current video duration. If \c currentItem is \c nil, \c 0 is returned.
@property (readonly, nonatomic) NSTimeInterval videoDuration;

/// Size of the current video. If \c currentItem is \c nil, \c CGSizeZero is returned.
@property (readonly, nonatomic) CGSize videoSize;

/// Delegate.
@property (weak, nonatomic, nullable) id<WFVideoViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
