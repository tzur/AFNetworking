// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFVideoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFVideoView ()

/// \c YES if \c play was called and no calls to \c stop or \c pause were done after it.
@property (readwrite, nonatomic) BOOL playbackRequested;

/// Video player for playing the video.
@property (strong, nonatomic, nullable) AVPlayer *player;

/// The queue on which the video player is created.
@property (readonly, nonatomic) dispatch_queue_t playerCreationQueue;

/// Progress observation token to be used in order to remove progress observation from player.
/// Set to \c nil when no video progress observation is taking place.
///
/// @see <tt>[AVPlayer addPeriodicTimeObserverForInterval:queue:usingBlock:]</tt> for more
/// information on the token's role.
@property (strong, nonatomic, nullable) id progressObserverToken;

/// Size of the current displayed video. If \c currentItem is \c nil, \c CGSizeZero is returned.
@property (readwrite, nonatomic) CGSize videoSize;

/// View's layer.
@property (readonly, nonatomic) AVPlayerLayer *layer;

@end

@implementation WFVideoView

@dynamic layer;

#pragma mark -
#pragma mark Lifecycle
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
  self.progressSamplingInterval = 1.0;
  _playerCreationQueue = dispatch_queue_create("com.lightricks.Wireframes.VideoView.PlayerCreation",
                                               DISPATCH_QUEUE_SERIAL);
  [self observeAppActiveState];
  [self observePlayerItemStatus];
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
  if (self.playbackRequested) {
    [self.player play];
  }
}

- (void)applicationWillResignActive {
  [self.player pause];
}

- (void)observePlayerItemStatus {
  @weakify(self);
  [[[[RACObserve(self, player.currentItem.status)
      ignore:nil]
      distinctUntilChanged]
      deliverOnMainThread]
      subscribeNext:^(NSNumber *status) {
        auto itemStatus = (AVPlayerItemStatus)status.unsignedIntegerValue;
        @strongify(self);
        if (itemStatus == AVPlayerItemStatusReadyToPlay) {
          [self addPlaybackFinishedObservation];
          [self addProgressObservation];
          [self reportVideoDidLoad];
          [self adjustPlaybackToPlaybackRequested];
        } else if (itemStatus == AVPlayerItemStatusFailed) {
          [self reportVideoError];
        }
      }];
}

- (void)addPlaybackFinishedObservation {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEnd:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:self.player.currentItem];
}

- (void)addProgressObservation {
  if (![self shouldAddProgressObservation]) {
    return;
  }
  CMTime progressInterval = CMTimeMakeWithSeconds(self.progressSamplingInterval, 600);
  @weakify(self);
  self.progressObserverToken = [self.player addPeriodicTimeObserverForInterval:progressInterval
                                                                         queue:nil
                                                                    usingBlock:^(CMTime time) {
    @strongify(self);
    [self.delegate videoView:self didPlayVideoAtTime:CMTimeGetSeconds(time)];
  }];
}

- (BOOL)shouldAddProgressObservation {
  return self.player && [self.delegate respondsToSelector:@selector(videoView:didPlayVideoAtTime:)];
}

- (void)reportVideoDidLoad {
  if ([self.delegate respondsToSelector:@selector(videoViewDidLoadVideo:)]) {
    [self.delegate videoViewDidLoadVideo:self];
  }
}

- (void)adjustPlaybackToPlaybackRequested {
  if (self.playbackRequested) {
    [self.player play];
  } else {
    [self.player pause];
  }
}

- (void)reportVideoError {
  if ([self.delegate respondsToSelector:@selector(videoView:didEncounterVideoError:)]) {
    [self.delegate videoView:self didEncounterVideoError:self.player.currentItem.error];
  }
}

- (void)dealloc {
  [self removeProgressObservation];
}

- (void)removeProgressObservation {
  if (!self.progressObserverToken) {
    return;
  }
  [self.player removeTimeObserver:self.progressObserverToken];
  self.progressObserverToken = nil;
}

#pragma mark -
#pragma mark UIView
#pragma mark -

+ (Class)layerClass {
  return [AVPlayerLayer class];
}

#pragma mark -
#pragma mark Public
#pragma mark -

- (void)loadVideoFromURL:(nullable NSURL *)videoURL {
  auto _Nullable playerItem = videoURL ? [AVPlayerItem playerItemWithURL:videoURL] : nil;
  [self loadVideoWithPlayerItem:playerItem];
}

- (void)loadVideoWithPlayerItem:(nullable AVPlayerItem *)playerItem {
  if (!playerItem) {
    [self setPlayer:nil videoSize:CGSizeZero];
    return;
  }

  @weakify(self);
  dispatch_async(self.playerCreationQueue, ^{
    @strongify(self);
    if (!self) {
      return;
    }

    auto player = [AVPlayer playerWithPlayerItem:nn(playerItem)];
    auto videoSize = [self.class videoSizeWithPlayer:player];

    dispatch_async(dispatch_get_main_queue(), ^{
      @strongify(self);
      [self setPlayer:player videoSize:videoSize];
    });
  });
}

- (void)setPlayer:(nullable AVPlayer *)player videoSize:(CGSize)videoSize {
  self.videoSize = videoSize;
  self.player = player;
}

+ (CGSize)videoSizeWithPlayer:(nullable AVPlayer *)player {
  if (!player) {
    return CGSizeZero;
  }

  auto videoTrack = [player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
  if (!videoTrack) {
    return CGSizeZero;
  }
  return CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
}

- (void)play {
  self.playbackRequested = YES;
  if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
    [self.player play];
  }
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

- (void)playerItemDidPlayToEnd:(NSNotification __unused *)notification {
  @weakify(self);
  [WFVideoView invokeOnMainThread:^{
    @strongify(self)
    if ([self.delegate respondsToSelector:@selector(videoViewDidFinishPlayback:)]) {
      [self.delegate videoViewDidFinishPlayback:self];
    }
    if (self.repeatsOnEnd) {
      [self.player seekToTime:kCMTimeZero];
      if (self.playbackRequested) {
        [self.player play];
      }
    }
  }];
}

+ (void)invokeOnMainThread:(void (^)())block {
  if ([NSThread isMainThread]) {
    block();
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      block();
    });
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
  [self removeProgressObservation];
  [self addProgressObservation];
}

- (void)setDelegate:(id<WFVideoViewDelegate> _Nullable)delegate {
  // Removing observation before setting delegate so that the new delegate won't get the first
  // progress event at a wrong interval.
  [self removeProgressObservation];
  _delegate = delegate;
  [self addProgressObservation];
}

- (void)setPlayer:(nullable AVPlayer *)player {
  [self removePlaybackFinishedObservation];
  [self removeProgressObservation];
  self.layer.player = player;
}

- (void)removePlaybackFinishedObservation {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:AVPlayerItemDidPlayToEndTimeNotification
                                                object:self.player.currentItem];
}

- (nullable AVPlayer *)player {
  return self.layer.player;
}

- (nullable AVPlayerItem *)currentItem {
  return self.player ? self.player.currentItem : nil;
}

@end

NS_ASSUME_NONNULL_END
