// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFVideoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFVideoView ()

/// \c YES if \c play was called and no calls to \c stop, \c pause, or \c setVideoURL were done
/// after it.
@property (readwrite, nonatomic) BOOL playbackRequested;

/// Video player for playing the video.
@property (strong, nonatomic, nullable) AVPlayer *player;

/// The queue on which the video player is created.
@property (readonly, nonatomic) dispatch_queue_t playerCreationQueue;

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

static const NSTimeInterval kDefaultProgressSamplingInterval = 1.0;

@dynamic layer;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    [self setup];
  }
  return self;
}
- (void)setup {
  self.progressSamplingInterval = kDefaultProgressSamplingInterval;
  _playerCreationQueue = dispatch_queue_create("com.lightricks.Wireframes.VideoView.PlayerCreation",
                                               DISPATCH_QUEUE_SERIAL);
  _videoProgressQueue = dispatch_queue_create("com.lightricks.Wireframes.VideoView.VideoProgress",
                                              DISPATCH_QUEUE_SERIAL);
  [self bindDelegateToVideoProgress];
  [self observePlayerStatus];
  [self observeAppActiveState];
}

- (void)dealloc {
  [self removeAppActiveStateObservation];
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

              NSTimeInterval videoDurationTime =
                  CMTimeGetSeconds(player.currentItem.asset.duration);
              CMTime progressInterval = CMTimeMakeWithSeconds(self.progressSamplingInterval,
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

- (void)removeAppActiveStateObservation {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIApplicationDidBecomeActiveNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIApplicationWillResignActiveNotification
                                                object:nil];
}

- (void)applicationDidBecomeActive {
  if (self.playbackRequested) {
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
  [self pause];

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
      if (self.playbackRequested) {
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
  self.playbackRequested = YES;
  [self.player play];
}

- (void)pause {
  self.playbackRequested = NO;
  [self.player pause];
}

- (void)stop {
  self.playbackRequested = NO;
  [self.player pause];
  [self.player seekToTime:kCMTimeZero];
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

  if (self.repeat) {
    [self.player seekToTime:kCMTimeZero];

    if (self.playbackRequested) {
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

- (void)setProgressSamplingInterval:(NSTimeInterval)progressSamplingInterval {
  LTParameterAssert(progressSamplingInterval > 0, @"progressSamplingInterval (%g) must be positive",
                    progressSamplingInterval);
  _progressSamplingInterval = progressSamplingInterval;
}

@end

NS_ASSUME_NONNULL_END
