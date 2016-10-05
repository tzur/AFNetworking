// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "UIViewController+LifecycleSignals.h"

#import "CUIFakeNSNotificationCenter.h"

SpecBegin(UIViewController_LifecycleSignals)

__block CUIFakeNSNotificationCenter *notificationCenterFake;
__block LLSignalTestRecorder *recorder;

beforeEach(^{
  notificationCenterFake = [[CUIFakeNSNotificationCenter alloc] init];
  recorder = nil;
});

context(@"send values", ^{
  __block UIViewController *viewController;

  beforeEach(^{
    viewController = [[UIViewController alloc] init];
    recorder =
        [[viewController cui_isVisibleWithNotificationCenter:notificationCenterFake] testRecorder];
  });

  it(@"should update appearing and disappearing", ^{
    [viewController viewDidAppear:NO];
    expect(recorder).to.sendValues(@[@YES]);
    [viewController viewWillDisappear:NO];
    expect(recorder).to.sendValues(@[@YES, @NO]);
    [viewController viewDidAppear:NO];
    expect(recorder).to.sendValues(@[@YES, @NO, @YES]);
  });

  it(@"should not be affected by animation", ^{
    [viewController viewDidAppear:YES];
    expect(recorder).to.sendValues(@[@YES]);
    [viewController viewWillDisappear:YES];
    expect(recorder).to.sendValues(@[@YES, @NO]);
    [viewController viewDidAppear:YES];
    expect(recorder).to.sendValues(@[@YES, @NO, @YES]);
  });

  it(@"should update app going to background and back", ^{
    [notificationCenterFake postNotificationName:UIApplicationDidBecomeActiveNotification
                                          object:nil];
    expect(recorder).to.sendValues(@[@YES]);
    [notificationCenterFake postNotificationName:UIApplicationWillResignActiveNotification
                                          object:nil];
    expect(recorder).to.sendValues(@[@YES, @NO]);
    [notificationCenterFake postNotificationName:UIApplicationDidBecomeActiveNotification
                                          object:nil];
    expect(recorder).to.sendValues(@[@YES, @NO, @YES]);
  });

  it(@"should update appearing going to background and back", ^{
    [viewController viewDidAppear:NO];
    expect(recorder).to.sendValues(@[@YES]);
    [notificationCenterFake postNotificationName:UIApplicationWillResignActiveNotification
                                          object:nil];
    expect(recorder).to.sendValues(@[@YES, @NO]);
    [notificationCenterFake postNotificationName:UIApplicationDidBecomeActiveNotification
                                          object:nil];
    expect(recorder).to.sendValues(@[@YES, @NO, @YES]);
  });

  it(@"should update without duplicates", ^{
    [notificationCenterFake postNotificationName:UIApplicationDidBecomeActiveNotification
                                          object:nil];
    [notificationCenterFake postNotificationName:UIApplicationDidBecomeActiveNotification
                                          object:nil];
    expect(recorder).to.sendValues(@[@YES]);
  });

  it(@"should update without duplicates for mixed sources", ^{
    [notificationCenterFake postNotificationName:UIApplicationWillResignActiveNotification
                                          object:nil];
    [viewController viewWillDisappear:NO];
    expect(recorder).to.sendValues(@[@NO]);
  });
});

it(@"should complete", ^{
  __weak id weakViewController;
  @autoreleasepool {
    UIViewController *viewController = [[UIViewController alloc] init];
    weakViewController = viewController;
    recorder =
        [[viewController cui_isVisibleWithNotificationCenter:notificationCenterFake] testRecorder];
  }
  expect(weakViewController).to.beNil();
  expect(recorder).to.complete();
});

it(@"should remove notification center observers", ^{
  @autoreleasepool {
    UIViewController *viewController = [[UIViewController alloc] init];
    expect(notificationCenterFake.currentlyConnectedObserverCount).to.equal(0);
    recorder =
        [[viewController cui_isVisibleWithNotificationCenter:notificationCenterFake] testRecorder];
    expect(notificationCenterFake.currentlyConnectedObserverCount).toNot.equal(0);
  }
  expect(notificationCenterFake.currentlyConnectedObserverCount).to.equal(0);
});

SpecEnd
