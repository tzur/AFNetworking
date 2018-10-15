// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFVideoView.h"

#import "WFFakeVideoViewDelegate.h"

SpecBegin(WFVideoView)

__block WFVideoView *videoView;
__block WFFakeVideoViewDelegate *delegate;
__block NSURL *zeroLengthVideoURL;
__block NSURL *halfSecondVideoURL;
__block NSTimeInterval defaultTimeout;

beforeAll(^{
  defaultTimeout = Expecta.asynchronousTestTimeout;
  // The asynchronous tests in this file are integration tests with the inner AVPlayer. Because
  // loading videos and starting playback by AVPlayer are long asynchronous operations that caused
  // flakiness of the tests in this file, the timeout is being dramatically increased.
  Expecta.asynchronousTestTimeout = 30;
});

afterAll(^{
  Expecta.asynchronousTestTimeout = defaultTimeout;
});

beforeEach(^{
  videoView = [[WFVideoView alloc] initWithFrame:CGRectZero];
  delegate = [[WFFakeVideoViewDelegate alloc] init];
  videoView.delegate = delegate;

  zeroLengthVideoURL = [NSBundle.lt_testBundle URLForResource:@"ZeroLengthTestVideo"
                                                withExtension:@"mp4"];
  halfSecondVideoURL = [NSBundle.lt_testBundle URLForResource:@"HalfSecondTestVideo"
                                                withExtension:@"mp4"];
});

afterEach(^{
  videoView = nil;
  delegate = nil;
});

it(@"should raise when setting a non positive progress sampling interval", ^{
  expect(^{
    videoView.progressSamplingInterval = 0;
  }).to.raise(NSInvalidArgumentException);

  expect(^{
    videoView.progressSamplingInterval = -1;
  }).to.raise(NSInvalidArgumentException);
});

it(@"should initialize properties correctly before video was loaded", ^{
  expect(videoView.videoDuration).to.equal(0);
  expect(videoView.currentTime).to.equal(0);
  expect(videoView.videoSize).to.equal(CGSizeZero);
  expect(videoView.currentItem).to.beNil();
});

it(@"should return correct video size when loading with URL", ^{
  [videoView loadVideoFromURL:zeroLengthVideoURL];
  expect(videoView.videoSize).will.equal(CGSizeMake(20, 16));

  [videoView loadVideoFromURL:halfSecondVideoURL];
  expect(videoView.videoSize).will.equal(CGSizeMake(640, 360));

  [videoView loadVideoFromURL:nil];
  expect(videoView.videoSize).will.equal(CGSizeZero);
});

it(@"should return correct video size when loading with player item", ^ {
  auto playerItem = [[AVPlayerItem alloc] initWithURL:zeroLengthVideoURL];
  [videoView loadVideoWithPlayerItem:playerItem];
  expect(videoView.videoSize).will.equal(CGSizeMake(20, 16));

  playerItem = [[AVPlayerItem alloc] initWithURL:halfSecondVideoURL];
  [videoView loadVideoWithPlayerItem:playerItem];
  expect(videoView.videoSize).will.equal(CGSizeMake(640, 360));

  [videoView loadVideoWithPlayerItem:nil];
  expect(videoView.videoSize).will.equal(CGSizeZero);
});

it(@"should set currentItem to playerItem with URL the video was loaded with", ^{
  [videoView loadVideoFromURL:zeroLengthVideoURL];

  expect(videoView.currentItem).willNot.beNil();
  expect(videoView.currentItem.asset).to.beKindOf(AVURLAsset.class);
  expect(((AVURLAsset *)videoView.currentItem.asset).URL).will.equal(zeroLengthVideoURL);
});

it(@"should set currentItem to playerItem the video loaded with", ^{
  auto playerItem = [[AVPlayerItem alloc] initWithURL:zeroLengthVideoURL];

  [videoView loadVideoWithPlayerItem:playerItem];

  expect(videoView.currentItem).will.equal(playerItem);
});

it(@"should proxy video gravity to layer", ^{
  auto layer = (AVPlayerLayer *)videoView.layer;
  videoView.videoGravity = AVLayerVideoGravityResizeAspectFill;
  expect(layer.videoGravity).to.equal(AVLayerVideoGravityResizeAspectFill);

  videoView.videoGravity = AVLayerVideoGravityResizeAspect;
  expect(layer.videoGravity).to.equal(AVLayerVideoGravityResizeAspect);
});

context(@"delegate", ^{
  it(@"should call delegate when video loads with URL", ^{
    [videoView loadVideoFromURL:zeroLengthVideoURL];

    expect(delegate.numberOfVideoLoads).will.equal(1);
  });

  it(@"should call delegate when video loads with player item", ^{
    auto playerItem = [[AVPlayerItem alloc] initWithURL:zeroLengthVideoURL];

    [videoView loadVideoWithPlayerItem:playerItem];

    expect(delegate.numberOfVideoLoads).will.equal(1);
  });

  it(@"should call delegate when video playback ends", ^{
    [videoView loadVideoFromURL:zeroLengthVideoURL];
    [videoView play];

    expect(delegate.numberOfPlaybacksFinished).will.equal(1);
  });

  it(@"should call progress in delegate as expected", ^{
    videoView.progressSamplingInterval = 0.1;
    [videoView loadVideoFromURL:halfSecondVideoURL];
    [videoView play];

    expect(delegate.playbackNotificationTimes).will.haveACountOf(5);
    for (NSUInteger i = 1; i < delegate.playbackNotificationTimes.count; ++i) {
      auto current = delegate.playbackNotificationTimes[i];
      auto previous = delegate.playbackNotificationTimes[i - 1];
      expect(current).to.beGreaterThanOrEqualTo(previous);
    }
  });

  it(@"should continue playing when loading a URL while playback", ^{
    // Start playback.
    videoView.repeatsOnEnd = YES;
    [videoView loadVideoFromURL:halfSecondVideoURL];
    expect(delegate.numberOfVideoLoads).will.equal(1);
    [videoView play];

    // Load URL while playback.
    [videoView loadVideoFromURL:halfSecondVideoURL];
    expect(delegate.numberOfVideoLoads).will.equal(2);

    // Expect video is playing (in loop) after setting URL, and thus will raise playback finished.
    auto playbacksFinished = delegate.numberOfPlaybacksFinished;

    expect(delegate.numberOfPlaybacksFinished).will.beGreaterThan(playbacksFinished);
  });

  it(@"should dealloc the delegate despite a video is being loaded with URL", ^{
    __weak WFFakeVideoViewDelegate *weakDelegate;
    @autoreleasepool {
      auto view = [[WFVideoView alloc] initWithFrame:CGRectZero];
      auto delegate = [[WFFakeVideoViewDelegate alloc] init];
      view.delegate = delegate;
      [view loadVideoFromURL:halfSecondVideoURL];
      weakDelegate = delegate;
    }
    expect(weakDelegate).to.beNil();
  });

  it(@"should dealloc the delegate despite a video is being loaded with player item", ^{
    __weak WFFakeVideoViewDelegate *weakDelegate;
    @autoreleasepool {
      auto view = [[WFVideoView alloc] initWithFrame:CGRectZero];
      auto delegate = [[WFFakeVideoViewDelegate alloc] init];
      view.delegate = delegate;
      auto playerItem = [[AVPlayerItem alloc] initWithURL:zeroLengthVideoURL];
      [view loadVideoWithPlayerItem:playerItem];
      weakDelegate = delegate;
    }
    expect(weakDelegate).to.beNil();
  });

  it(@"should dealloc the view despite a video is being played", ^{
    __weak WFVideoView *weakView;
    @autoreleasepool {
      auto view = [[WFVideoView alloc] initWithFrame:CGRectZero];
      view.repeatsOnEnd = YES;
      view.delegate = delegate;
      [view loadVideoFromURL:halfSecondVideoURL];
      expect(delegate.numberOfVideoLoads).will.equal(1);
      [view play];

      weakView = view;
    }
    expect(weakView).to.beNil();
  });

  it(@"should dealloc the delegate despite a video is being played", ^{
    __weak WFFakeVideoViewDelegate *weakDelegate;
    @autoreleasepool {
      auto view = [[WFVideoView alloc] initWithFrame:CGRectZero];
      view.repeatsOnEnd = YES;
      auto delegate = [[WFFakeVideoViewDelegate alloc] init];
      view.delegate = delegate;
      [view loadVideoFromURL:halfSecondVideoURL];
      expect(delegate.numberOfVideoLoads).will.equal(1);
      [view play];

      weakDelegate = delegate;
    }
    expect(weakDelegate).to.beNil();
  });
});

SpecEnd
