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
});

it(@"should return correct video size", ^{
  [videoView loadVideoFromURL:zeroLengthVideoURL];
  expect(videoView.videoSize).will.equal(CGSizeMake(20, 16));

  [videoView loadVideoFromURL:halfSecondVideoURL];
  expect(videoView.videoSize).will.equal(CGSizeMake(640, 360));
});

it(@"should proxy video gravity to layer", ^{
  auto layer = (AVPlayerLayer *)videoView.layer;
  videoView.videoGravity = AVLayerVideoGravityResizeAspectFill;
  expect(layer.videoGravity).to.equal(AVLayerVideoGravityResizeAspectFill);

  videoView.videoGravity = AVLayerVideoGravityResizeAspect;
  expect(layer.videoGravity).to.equal(AVLayerVideoGravityResizeAspect);
});

context(@"delegate", ^{
  it(@"should call delegate when video loads", ^{
    [videoView loadVideoFromURL:zeroLengthVideoURL];
    auto videoDidLoadSignal = [[delegate rac_signalForSelector:@selector(videoViewDidLoadVideo:)]
        reduceEach:(id)^WFVideoView *(WFVideoView *videoView) {
          return videoView;
        }];
    expect(videoDidLoadSignal).will.sendValues(@[videoView]);
  });

  it(@"should call delegate when video playback ends", ^{
    [videoView loadVideoFromURL:zeroLengthVideoURL];
    auto videoDidFinishPlaybackSignal = [[delegate
        rac_signalForSelector:@selector(videoViewDidFinishPlayback:)]
        reduceEach:(id)^WFVideoView *(WFVideoView *videoView) {
          return videoView;
        }];
    [videoView play];

    expect(videoDidFinishPlaybackSignal).will.sendValues(@[videoView]);
  });

  it(@"should call progress in delegate as expected", ^{
    [videoView loadVideoFromURL:halfSecondVideoURL];
    videoView.progressSamplingInterval = 0.1;
    auto recorder = [[[[delegate
        rac_signalForSelector:@selector(videoView:didPlayVideoAtTime:)]
        combinePreviousWithStart:RACTuplePack(videoView, @0)
                          reduce:^RACTuple *(RACTuple *previous, RACTuple *current) {
          return RACTuplePack(previous, current);
        }]
        doNext:^(RACTuple *tuple) {
          RACTupleUnpack(RACTuple *previous, RACTuple *current) = tuple;

          expect(current.first).to.equal(videoView);
          expect(current.second).to.beGreaterThanOrEqualTo(previous.second);
        }]
        testRecorder];

    [videoView play];

    expect(recorder.values.count).will.beGreaterThanOrEqualTo(5);
  });

  it(@"should continue playing when loading a URL while playback", ^{
    // Start playback.
    videoView.repeatsOnEnd = YES;
    auto videoDidLoadSignal = [[delegate rac_signalForSelector:@selector(videoViewDidLoadVideo:)]
        reduceEach:(id)^WFVideoView *(WFVideoView *videoView) {
          return videoView;
    }];
    [videoView loadVideoFromURL:halfSecondVideoURL];
    expect(videoDidLoadSignal).will.sendValues(@[videoView]);
    [videoView play];

    // Load URL while playback.
    [videoView loadVideoFromURL:halfSecondVideoURL];
    expect(videoDidLoadSignal).will.sendValues(@[videoView]);

    // Expect video is playing (in loop) after setting URL, and thus will raise playback finished.
    auto videoDidFinishPlaybackSignal = [[delegate
        rac_signalForSelector:@selector(videoViewDidFinishPlayback:)]
        reduceEach:(id)^WFVideoView *(WFVideoView *videoView) {
          return videoView;
    }];
    expect(videoDidFinishPlaybackSignal).will.sendValues(@[videoView]);
  });

  it(@"should dealloc the delegate despite a video is being loaded from URL", ^{
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

  it(@"should dealloc the view despite a video is being played", ^{
    __weak WFVideoView *weakView;
    @autoreleasepool {
      auto view = [[WFVideoView alloc] initWithFrame:CGRectZero];
      view.repeatsOnEnd = YES;
      view.delegate = delegate;
      [view loadVideoFromURL:halfSecondVideoURL];

      [[[delegate rac_signalForSelector:@selector(videoViewDidLoadVideo:)]
          take:1]
          asynchronouslyWaitUntilCompleted:NULL];

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

      [[[delegate rac_signalForSelector:@selector(videoViewDidLoadVideo:)]
          take:1]
          asynchronouslyWaitUntilCompleted:NULL];

      [view play];

      weakDelegate = delegate;
    }
    expect(weakDelegate).to.beNil();
  });
});

SpecEnd
