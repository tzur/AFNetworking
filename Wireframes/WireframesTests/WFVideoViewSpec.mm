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
  videoView = [[WFVideoView alloc] initWithVideoProgressIntervalTime:0.1 playInLoop:NO];
  delegate = [[WFFakeVideoViewDelegate alloc] init];
  videoView.delegate = delegate;

  zeroLengthVideoURL = [[NSBundle bundleForClass:self.class] URLForResource:@"ZeroLengthTestVideo"
                                                              withExtension:@"mp4"];
  halfSecondVideoURL = [[NSBundle bundleForClass:self.class] URLForResource:@"HalfSecondTestVideo"
                                                              withExtension:@"mp4"];
});

afterEach(^{
  videoView = nil;
  delegate = nil;
});

it(@"should raise when initializing with a non positive progress time interval", ^{
  expect(^{
    WFVideoView __unused *videoView =
        [[WFVideoView alloc] initWithVideoProgressIntervalTime:0 playInLoop:YES];
  }).to.raise(NSInvalidArgumentException);

  expect(^{
    WFVideoView __unused *videoView =
        [[WFVideoView alloc] initWithVideoProgressIntervalTime:-1 playInLoop:YES];
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

  xit(@"should call progress in delegate as expected", ^{
    videoView.videoURL = halfSecondVideoURL;
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

    [videoView play];

    expect(recorder.values.count).will.beGreaterThanOrEqualTo(5);
  });

  it(@"should dealloc the delegate despite a video is being loaded from URL", ^{
    __weak WFFakeVideoViewDelegate *weakDelegate;
    @autoreleasepool {
      WFVideoView *view = [[WFVideoView alloc] initWithVideoProgressIntervalTime:0.1
                                                                      playInLoop:YES];
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
      WFVideoView *view = [[WFVideoView alloc] initWithVideoProgressIntervalTime:0.1
                                                                      playInLoop:YES];
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
      WFVideoView *view = [[WFVideoView alloc] initWithVideoProgressIntervalTime:0.1
                                                                      playInLoop:YES];
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
