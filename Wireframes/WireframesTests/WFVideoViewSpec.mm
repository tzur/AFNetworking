// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFVideoView.h"

#import "WFFakeVideoViewDelegate.h"

SpecBegin(WFVideoView)

__block WFVideoView *videoView;
__block WFFakeVideoViewDelegate *delegate;
__block NSURL *zeroLengthVideoURL;
__block NSURL *halfSecondVideoURL;

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

it(@"should set properties correctly when video is empty", ^{
  videoView.videoURL = nil;
  expect(videoView.videoDuration).to.equal(0);
  expect(videoView.currentTime).to.equal(0);
  expect(videoView.videoSize).to.equal(CGSizeZero);
});

it(@"should return correct video size", ^{
  videoView.videoURL = zeroLengthVideoURL;
  expect(videoView.videoSize).will.equal(CGSizeMake(20, 16));

  videoView.videoURL = halfSecondVideoURL;
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
    videoView.videoURL = zeroLengthVideoURL;
    RACSignal *videoDidLoadSignal = [[delegate rac_signalForSelector:@selector(videoDidLoad:)]
        reduceEach:(id)^WFVideoView *(WFVideoView *videoView) {
          return videoView;
        }];
    expect(videoDidLoadSignal).will.sendValues(@[videoView]);
  });

  it(@"should call delegate when video playback ends", ^{
    videoView.videoURL = zeroLengthVideoURL;
    RACSignal *videoDidFinishPlaybackSignal = [[delegate
        rac_signalForSelector:@selector(videoDidFinishPlayback:)]
        reduceEach:(id)^WFVideoView *(WFVideoView *videoView) {
          return videoView;
        }];
    [videoView play];

    expect(videoDidFinishPlaybackSignal).will.sendValues(@[videoView]);
  });

  it(@"should call progress in delegate as expected", ^{
    videoView.videoURL = halfSecondVideoURL;
    videoView.progressSamplingInterval = 0.1;
    LLSignalTestRecorder *recorder = [[[[[delegate
        rac_signalForSelector:@selector(videoProgress:progressTime:videoDurationTime:)]
        deliverOnMainThread]
        combinePreviousWithStart:RACTuplePack(videoView, @0, @0.5)
                          reduce:^RACTuple *(RACTuple *previous, RACTuple *current) {
          return RACTuplePack(previous, current);
        }]
        doNext:^(RACTuple *tuple) {
          RACTupleUnpack(RACTuple *previous, RACTuple *current) = tuple;

          expect(current.first).to.equal(videoView);
          expect(current.second).to.beGreaterThanOrEqualTo(previous.second);
          expect(current.third).to.beCloseToWithin(0.5, 0.1);
        }]
        testRecorder];

    RACSignal *videoDidLoadSignal = [[delegate rac_signalForSelector:@selector(videoDidLoad:)]
                                     reduceEach:(id)^WFVideoView *(WFVideoView *videoView) {
                                       return videoView;
                                     }];
    expect(videoDidLoadSignal).will.sendValues(@[videoView]);
    [videoView play];
    expect(recorder.values.count).after(3).beGreaterThanOrEqualTo(5);
  });

  it(@"should dealloc the delegate despite a video is being loaded from URL", ^{
    __weak WFFakeVideoViewDelegate *weakDelegate;
    @autoreleasepool {
      WFVideoView *view = [[WFVideoView alloc] initWithFrame:CGRectZero];
      WFFakeVideoViewDelegate *delegate = [[WFFakeVideoViewDelegate alloc] init];
      view.delegate = delegate;
      view.videoURL = halfSecondVideoURL;
      weakDelegate = delegate;
    }
    expect(weakDelegate).to.beNil();
  });

  it(@"should dealloc the view despite a video is being played", ^{
    __weak WFVideoView *weakView;
    @autoreleasepool {
      WFVideoView *view = [[WFVideoView alloc] initWithFrame:CGRectZero];
      view.repeat = YES;
      view.delegate = delegate;
      view.videoURL = halfSecondVideoURL;

      [[[delegate rac_signalForSelector:@selector(videoDidLoad:)]
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
      WFVideoView *view = [[WFVideoView alloc] initWithFrame:CGRectZero];
      view.repeat = YES;
      WFFakeVideoViewDelegate *delegate = [[WFFakeVideoViewDelegate alloc] init];
      view.delegate = delegate;
      view.videoURL = halfSecondVideoURL;

      [[[delegate rac_signalForSelector:@selector(videoDidLoad:)]
          take:1]
          asynchronouslyWaitUntilCompleted:NULL];

      [view play];

      weakDelegate = delegate;
    }
    expect(weakDelegate).to.beNil();
  });
});

SpecEnd
