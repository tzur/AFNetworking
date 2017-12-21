// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFVideoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFVideoView ()

/// Video player for playing the video.
@property (strong, nonatomic, nullable) AVPlayer *player;

/// \c YES if the video should be playing.
@property (readwrite, nonatomic) BOOL isPlaying;

/// \c YES if the playback should automatically restart after video ends.
@property (readonly, nonatomic) BOOL playInLoop;

/// The queue on which the video player is created.
@property (readonly, nonatomic) dispatch_queue_t playerCreationQueue;

/// Time interval (in seconds) between each call to the
/// <tt>[delgate videoProgressTime:videoDurationTime:]</tt> while the video is playing if the
/// \c delgate implements the method.
@property (readonly, nonatomic) CGFloat videoProgresssIntervalTime;

/// The queue on which the video progress updates are being sent.
@property (readonly, nonatomic) dispatch_queue_t videoProgressQueue;

/// Tuple of <tt>(AVPlayer *, id)</tt> with the player that currently has a video progress
/// observation along with an observer token. Set to \c nil when no video progress observation is
/// taking place.
///
/// @see <tt>[AVPlayer addPeriodicTimeObserverForInterval:queue:usingBlock:]</tt> for more
/// information on the token's role.
@property (readonly, nonatomic, nullable) RACTuple *playerToProgressObserverToken;

/// Size of the current displayed video. If \c videoURL is \c nil, \c CGSizeZero is returned.
@property (readwrite, nonatomic) CGSize videoSize;

/// View's layer.
@property (readonly, nonatomic) AVPlayerLayer *layer;

@end

@implementation WFVideoView

@dynamic layer;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithVideoProgressIntervalTime:(CGFloat)videoProgresssIntervalTime
                                       playInLoop:(BOOL)playInLoop {
  LTParameterAssert(videoProgresssIntervalTime > 0, @"videoProgresssIntervalTime (%g) must be "
                    "positive", videoProgresssIntervalTime);

  if (self = [super initWithFrame:CGRectZero]) {
    _videoProgresssIntervalTime = videoProgresssIntervalTime;
    _playerCreationQueue =
        dispatch_queue_create("com.lightricks.Wireframes.VideoView.PlayerCreation",
                              DISPATCH_QUEUE_SERIAL);
    _videoProgressQueue =
        dispatch_queue_create("com.lightricks.Wireframes.VideoView.VideoProgress",
                              DISPATCH_QUEUE_SERIAL);
    _playInLoop = playInLoop;

    [self bindDelegateToVideoProgress];
    [self observePlayerStatus];
    [self observeAppActiveState];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (AVPlayer *)createPlayerForURL:(NSURL *)videoURL {
  AVPlayer *player = [AVPlayer playerWithURL:videoURL];
  return player;
}

- (void)observePlayerStatus {
  @weakify(self)
  [RACObserve(self, player.status) subscribeNext:^(NSNumber * _Nullable status) {
    if (!status) {
      return;
    }
    AVPlayerItemStatus playerStatus = (AVPlayerItemStatus)status.unsignedIntegerValue;
    @strongify(self)
    if (playerStatus == AVPlayerItemStatusReadyToPlay) {
      [self playerItemReady];
    } else if (playerStatus == AVPlayerItemStatusFailed) {
      [self playerError];
    }
  }];
}

- (void)bindDelegateToVideoProgress {
  @weakify(self);

  RAC(self, playerToProgressObserverToken) = [[[RACObserve(self, delegate)
      map:^RACSignal *(id<WFVideoViewDelegate> _Nullable delegate) {
        if (![delegate respondsToSelector:
             @selector(videoProgress:progressTime:videoDurationTime:)]) {
          return [RACSignal return:nil];
        }

        @strongify(self);
        RACSignal *playerSignal = RACObserve(self, player);

        @weakify(delegate);
        return [playerSignal
            map:^RACTuple * _Nullable(AVPlayer * _Nullable player) {
              @strongify(self);

              if (!player) {
                return nil;
              }

              CGFloat videoDurationTime = CMTimeGetSeconds(player.currentItem.asset.duration);
              CMTime progressInterval = CMTimeMakeWithSeconds(self.videoProgresssIntervalTime,
                                                              NSEC_PER_SEC);
              dispatch_queue_t videoProgressQueue = self.videoProgressQueue;

              id observerToken = [player addPeriodicTimeObserverForInterval:progressInterval
                                                                      queue:videoProgressQueue
                                                                 usingBlock:^(CMTime time) {
                @strongify(self);
                @strongify(delegate);
                [delegate videoProgress:self progressTime:CMTimeGetSeconds(time)
                      videoDurationTime:videoDurationTime];
              }];
              return RACTuplePack(player, observerToken);
            }];
      }]
      switchToLatest]
      combinePreviousWithStart:nil reduce:^RACTuple * __nullable(RACTuple * __nullable previous,
                                                                 RACTuple * __nullable current) {
        if (previous) {
          RACTupleUnpack(AVPlayer *previousPlayer, id previousObserverToken) = previous;
          [previousPlayer removeTimeObserver:previousObserverToken];
        }
        return current;
      }];
}

- (void)observeAppActiveState {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationDidBecomeActive)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(applicationWillResignActive)
                                               name:UIApplicationWillResignActiveNotification
                                             object:nil];
}

- (void)applicationDidBecomeActive {
  if (self.isPlaying) {
    [self.player play];
  }
}

- (void)applicationWillResignActive {
  [self.player pause];
}

#pragma mark -
#pragma mark UIView
#pragma mark -

+ (Class)layerClass {
  return [AVPlayerLayer class];
}

#pragma mark -
#pragma mark Playback
#pragma mark -

- (void)setPlayer:(nullable AVPlayer *)player {
  [[NSNotificationCenter defaultCenter]
   removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

  _player = player;

  [self.layer setPlayer:player];
}

#pragma mark -
#pragma mark Public
#pragma mark -

- (void)setVideoURL:(nullable NSURL *)videoURL {
  [self stop];

  _videoURL = videoURL;

  if (!videoURL) {
    self.player = nil;
    return;
  }

  @weakify(self);
  dispatch_async(self.playerCreationQueue, ^{
    @strongify(self);
    if (!self) {
      return;
    }

    AVPlayer *player = [self createPlayerForURL:videoURL];
    CGSize videoSize = [self.class videoSizeWithPlayer:player];

    dispatch_async(dispatch_get_main_queue(), ^{
      @strongify(self);
      if (![self.videoURL isEqual:videoURL]) {
        return;
      }

      self.player = player;
      self.videoSize = videoSize;
      if (self.isPlaying) {
        [self.player play];
      } else {
        [self.player pause];
      }
    });
  });
}

+ (CGSize)videoSizeWithPlayer:(nullable AVPlayer *)player {
  if (!player) {
    return CGSizeZero;
  }

  AVAssetTrack *videoTrack =
      [player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
  if (!videoTrack) {
    return CGSizeZero;
  }
  return CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
}

- (void)play {
  self.isPlaying = YES;
  [self.player play];
}

- (void)pause {
  self.isPlaying = NO;
  [self.player pause];
}

- (void)stop {
  self.isPlaying = NO;
  [self.player pause];
}

#pragma mark -
#pragma mark Video Handling
#pragma mark -

- (void)playerItemReady {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEnd:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:self.player.currentItem];

  if ([self.delegate respondsToSelector:@selector(videoDidLoad:)]) {
    [self.delegate videoDidLoad:self];
  }
}

- (void)playerError {
  if ([self.delegate respondsToSelector:@selector(video:didFailWithError:)]) {
    [self.delegate video:self didFailWithError:self.player.error];
  }
}

- (void)playerItemDidPlayToEnd:(NSNotification __unused *)notification {
  if ([self.delegate respondsToSelector:@selector(videoDidFinishPlayback:)]) {
    [self.delegate videoDidFinishPlayback:self];
  }

  if (self.playInLoop) {
    [self.player seekToTime:CMTimeMake(0, 1)];

    if (self.isPlaying) {
      [self.player play];
    }
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSTimeInterval)currentTime {
  return self.player ? CMTimeGetSeconds(self.player.currentTime) : 0;
}

- (NSTimeInterval)videoDuration {
  return self.player ? CMTimeGetSeconds(self.player.currentItem.asset.duration) : 0;
}

- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity {
  self.layer.videoGravity = videoGravity;
}

- (AVLayerVideoGravity)videoGravity {
  return self.layer.videoGravity;
}

@end

NS_ASSUME_NONNULL_END
