// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFVideoView.h"

#import "WFFakeVideoViewDelegate.h"

SpecBegin(WFVideoView)

__block WFVideoView *videoView;
__block WFFakeVideoViewDelegate *delegate;
__block NSURL *zeroLengthVideoURL;
__block NSURL *fiveSecondVideoURL;

beforeEach(^{
  videoView = [[WFVideoView alloc] initWithVideoProgressIntervalTime:0.1 playInLoop:NO];
  delegate = [[WFFakeVideoViewDelegate alloc] init];
  videoView.delegate = delegate;

  zeroLengthVideoURL = [[NSBundle bundleForClass:self.class] URLForResource:@"BlankVideo64x64"
                                                              withExtension:@"mp4"];
  fiveSecondVideoURL =
      [[NSBundle bundleForClass:self.class] URLForResource:@"BlankVideo1080x1920Rotation0"
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
  expect(videoView.videoSize).will.equal(CGSizeMake(64, 64));

  videoView.videoURL = fiveSecondVideoURL;
  expect(videoView.videoSize).will.equal(CGSizeMake(1080, 1920));
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
    videoView.videoURL = fiveSecondVideoURL;
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
      view.videoURL = fiveSecondVideoURL;
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
      view.videoURL = fiveSecondVideoURL;

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
      view.videoURL = fiveSecondVideoURL;

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
