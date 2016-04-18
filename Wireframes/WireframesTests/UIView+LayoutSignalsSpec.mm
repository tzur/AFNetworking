// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "UIView+LayoutSignals.h"

SpecBegin(UIView_LayoutSignals)

__block UIView *view;

beforeEach(^{
  view = [[UIView alloc] initWithFrame:CGRectZero];
});

context(@"layoutSignal", ^{
  it(@"should send bounds after layoutSubviews", ^{
    LLSignalTestRecorder *recorder = [view.wf_layoutSubviewsSignal testRecorder];
    [view setNeedsLayout];
    [view layoutIfNeeded];
    expect(recorder).to.sendValues(@[$(CGRectZero)]);
  });

  it(@"should deliver on the same thread", ^{
    __block BOOL delivered = NO;
    RACScheduler *scheduler = [RACScheduler currentScheduler];
    [view.wf_layoutSubviewsSignal subscribeNext:^(id) {
      expect([RACScheduler currentScheduler]).to.equal(scheduler);
      delivered = YES;
    }];

    [view setNeedsLayout];
    [view layoutIfNeeded];
    expect(delivered).to.beTruthy();
  });

  it(@"should complete on dealloc", ^{
    LLSignalTestRecorder *recorder;
    __weak UIView *weakView;
    @autoreleasepool {
      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      recorder = [view.wf_layoutSubviewsSignal testRecorder];
      weakView = view;
    }
    expect(recorder).to.complete();
    expect(weakView).to.beNil();
  });
});

context(@"boundsSignal", ^{
  it(@"should send current bounds on subscription", ^{
    expect(view.wf_boundsSignal).will.sendValues(@[$(CGRectZero)]);
    view.bounds = CGRectMake(0, 1, 10, 5);
    [view layoutIfNeeded];
    expect(view.wf_boundsSignal).will.sendValues(@[$(CGRectMake(0, 1, 10, 5))]);
  });

  it(@"should send bounds after a change", ^{
    LLSignalTestRecorder *recorder = [view.wf_boundsSignal testRecorder];
    view.bounds = CGRectMake(0, 1, 10, 5);
    [view layoutIfNeeded];
    expect(recorder).to.sendValues(@[$(CGRectZero), $(CGRectMake(0, 1, 10, 5))]);
  });

  it(@"should complete on dealloc", ^{
    LLSignalTestRecorder *recorder;
    __weak UIView *weakView;
    @autoreleasepool {
      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      recorder = [view.wf_boundsSignal testRecorder];
      weakView = view;
    }
    expect(recorder).to.complete();
    expect(weakView).to.beNil();
  });
});

context(@"sizeSignal", ^{
  it(@"should send view size", ^{
    LLSignalTestRecorder *recorder = [view.wf_sizeSignal testRecorder];
    view.bounds = CGRectMake(0, 1, 10, 5);
    [view layoutIfNeeded];
    expect(recorder).to.sendValues(@[$(CGSizeZero), $(CGSizeMake(10, 5))]);
  });

  it(@"should complete on dealloc", ^{
    LLSignalTestRecorder *recorder;
    __weak UIView *weakView;
    @autoreleasepool {
      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      recorder = [view.wf_sizeSignal testRecorder];
      weakView = view;
    }
    expect(recorder).to.complete();
    expect(weakView).to.beNil();
  });
});

context(@"positiveSizeSignal", ^{
  it(@"should send view size ignoring non positive values", ^{
    LLSignalTestRecorder *recorder = [view.wf_positiveSizeSignal testRecorder];
    view.bounds = CGRectMake(0, 1, 10, 5);
    [view layoutIfNeeded];
    view.bounds = CGRectMake(10, 20, 0, 5);
    [view layoutIfNeeded];
    view.bounds = CGRectMake(10, 20, 5, 0);
    [view layoutIfNeeded];
    view.bounds = CGRectMake(0, 0, 1, 2);
    [view layoutIfNeeded];
    expect(recorder).to.sendValues(@[$(CGSizeMake(10, 5)), $(CGSizeMake(1, 2))]);
  });

  it(@"should complete on dealloc", ^{
    LLSignalTestRecorder *recorder;
    __weak UIView *weakView;
    @autoreleasepool {
      UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
      recorder = [view.wf_positiveSizeSignal testRecorder];
      weakView = view;
    }
    expect(recorder).to.complete();
    expect(weakView).to.beNil();
  });
});

SpecEnd
