// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMVolumeButtonsController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CAMVolumeButtonsController ()

/// Parent view for \c volumeView.
@property (readonly, nonatomic) UIView *targetView;

/// Replacement view for iOS's built-in volume view.
@property (readonly, nonatomic) MPVolumeView *volumeView;

/// \c YES while the receiver is intercepting volume button presses.
@property (readwrite, nonatomic) BOOL started;

/// Volume level to set after every volume button press.
@property (nonatomic) float volumeToResetOnChange;

/// Volume level to set when stopping.
@property (nonatomic) float volumeToResetOnStop;

/// If \c YES, the next volume change will not be intercepted. Used so programmatically setting the
/// volume won't send on \c volumePressed.
@property (nonatomic) BOOL ignoreNextVolumeChange;

@end

@implementation CAMVolumeButtonsController

- (instancetype)initWithTargetView:(UIView *)targetView {
  if (self = [super init]) {
    _targetView = targetView;
    _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(CGFLOAT_MAX, CGFLOAT_MAX, 0, 0)];
    _volumePressed = [[self rac_signalForSelector:@selector(didPressVolumeButton)]
        mapReplace:[RACUnit defaultUnit]];
  }
  return self;
}

- (void)dealloc {
  [self stop];
}

#pragma mark -
#pragma mark Lifecycle
#pragma mark -

- (void)start {
  if (self.started) {
    return;
  }
  self.started = YES;

  [self addVolumeView];

  // There's a bit of delay between adding a MPVolumeView and until iOS disables the built-in view.
  // Calling startAudioSession without delay will show system volume view.
  [self setupWithDelay:0.5];
}

- (void)setupWithDelay:(NSTimeInterval)delay {
  @weakify(self);
  [[[[RACSignal return:[RACUnit defaultUnit]]
      delay:delay]
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(id) {
        @strongify(self);
        [self startVolumeListener];
        [self startAudioSession];
      }];
}

- (void)stop {
  if (!self.started) {
    return;
  }
  self.started = NO;

  [self stopVolumeListener];
  [self stopAudioSession];
  [self removeVolumeView];
}

#pragma mark -
#pragma mark Volume view
#pragma mark -

- (void)addVolumeView {
  [self.targetView addSubview:self.volumeView];
}

- (void)removeVolumeView {
  [self.volumeView removeFromSuperview];
}

#pragma mark -
#pragma mark Audio session
#pragma mark -

- (void)startAudioSession {
  static const float kMinVolume = 0.0001;
  static const float kMaxVolume = 0.9999;

  NSError *error;
  AVAudioSession *session = [AVAudioSession sharedInstance];
  BOOL success = [session setActive:YES error:&error];
  if (!success) {
    LogError(@"Error when activating audio session: %@", error);
  }

  self.volumeToResetOnStop = session.outputVolume;
  self.volumeToResetOnChange = self.volumeToResetOnStop;

  if (session.outputVolume < kMinVolume) {
    [self setVolume:kMinVolume];
    self.volumeToResetOnChange = kMinVolume;
  } else if (session.outputVolume > kMaxVolume) {
    [self setVolume:kMaxVolume];
    self.volumeToResetOnChange = kMaxVolume;
  }
}

- (void)stopAudioSession {
  [self setVolume:self.volumeToResetOnStop];

  NSError *error;
  BOOL success = [[AVAudioSession sharedInstance] setActive:NO error:&error];
  if (!success) {
    LogError(@"Error when deactivating audio session: %@", error);
  }
}

#pragma mark -
#pragma mark Volume listener
#pragma mark -

- (void)startVolumeListener {
  @weakify(self);

  AVAudioSession *session = [AVAudioSession sharedInstance];
  [[[[[RACObserve(session, outputVolume)
      skip:1]
      deliverOnMainThread]
      takeUntil:[self rac_signalForSelector:@selector(stopVolumeListener)]]
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(id) {
        @strongify(self);

        if (self.ignoreNextVolumeChange) {
          self.ignoreNextVolumeChange = NO;
          return;
        }

        [self didPressVolumeButton];
        [self setVolume:self.volumeToResetOnChange];
      }];

  [[[[[[[NSNotificationCenter defaultCenter]
      rac_addObserverForName:AVAudioSessionInterruptionNotification object:nil]
      deliverOnMainThread]
      takeUntil:[self rac_signalForSelector:@selector(stopVolumeListener)]]
      takeUntil:[self rac_willDeallocSignal]]
      filter:^BOOL(NSNotification *notification) {
        AVAudioSessionInterruptionType interruptionType = (AVAudioSessionInterruptionType)
            [notification.userInfo[AVAudioSessionInterruptionTypeKey] integerValue];
        return interruptionType == AVAudioSessionInterruptionTypeEnded;
      }]
      subscribeNext:^(id) {
        @strongify(self);
        [self startAudioSession];
      }];
}

- (void)stopVolumeListener {
}

- (void)didPressVolumeButton {
}

- (void)setVolume:(float)volume {
  MPMusicPlayerController *player = [MPMusicPlayerController applicationMusicPlayer];
  if ([player respondsToSelector:@selector(setVolume:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    player.volume = volume;
#pragma clang diagnostic pop
    self.ignoreNextVolumeChange = YES;
  } else {
    LogError(@"MPMusicPlayerController does not respond to selector setVolume:");
  }
}

@end

NS_ASSUME_NONNULL_END
