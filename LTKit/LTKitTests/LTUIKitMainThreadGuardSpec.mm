// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTUIKitMainThreadGuard.h"

@interface LTUIKitView : UIView
@end

@implementation LTUIKitView
@end

SpecBegin(LTUIKitMainThreadGuard)

__block BOOL called;
__block BOOL installed;

beforeAll(^{
  installed = LTInstallUIKitMainThreadGuard(^{
    called = YES;
  });
});

__block dispatch_queue_t queue;

beforeEach(^{
  queue = dispatch_queue_create("com.lightricks.LTKit.NonMainThread", NULL);
});

it(@"should successfully install the guard", ^{
  expect(installed).to.beTruthy();
});

context(@"UIView class", ^{
  __block UIView *view;

  beforeEach(^{
    called = NO;

    view = [[UIView alloc] initWithFrame:CGRectZero];
    [[UIApplication sharedApplication].keyWindow addSubview:view];
  });

  afterEach(^{
    [view removeFromSuperview];
    view = nil;
  });

  it(@"should call block on setNeedsDisplay when called not from the main thread", ^{
    waitUntil(^(DoneCallback done) {
      dispatch_async(queue, ^{
        [view setNeedsDisplay];
        done();
      });
    });

    expect(called).to.beTruthy();
  });

  it(@"should call block on setNeedsLayout when called not from the main thread", ^{
    waitUntil(^(DoneCallback done) {
      dispatch_async(queue, ^{
        [view setNeedsLayout];
        done();
      });
    });

    expect(called).to.beTruthy();
  });

  it(@"should call block on setNeedsDisplayInRect: when called not from the main thread", ^{
    waitUntil(^(DoneCallback done) {
      dispatch_async(queue, ^{
        [view setNeedsDisplayInRect:CGRectZero];
        done();
      });
    });

    expect(called).to.beTruthy();
  });
});

context(@"UIView subclass", ^{
  __block LTUIKitView *view;

  beforeEach(^{
    called = NO;

    view = [[LTUIKitView alloc] initWithFrame:CGRectZero];
    [[UIApplication sharedApplication].keyWindow addSubview:view];
  });

  afterEach(^{
    [view removeFromSuperview];
    view = nil;
  });

  it(@"should call block on setNeedsDisplay when called not from the main thread", ^{
    waitUntil(^(DoneCallback done) {
      dispatch_async(queue, ^{
        [view setNeedsDisplay];
        done();
      });
    });

    expect(called).to.beTruthy();
  });

  it(@"should call block on setNeedsLayout when called not from the main thread", ^{
    waitUntil(^(DoneCallback done) {
      dispatch_async(queue, ^{
        [view setNeedsLayout];
        done();
      });
    });

    expect(called).to.beTruthy();
  });

  it(@"should call block on setNeedsDisplayInRect: when called not from the main thread", ^{
    waitUntil(^(DoneCallback done) {
      dispatch_async(queue, ^{
        [view setNeedsDisplayInRect:CGRectZero];
        done();
      });
    });

    expect(called).to.beTruthy();
  });
});

it(@"should return NO when installing twice", ^{
  auto installed = LTInstallUIKitMainThreadGuard(^{});
  expect(installed).to.beFalsy();
});

SpecEnd
