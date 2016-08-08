// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUITimerModeViewModel.h"

#import "CUIFakeTimerContainer.h"

SpecBegin(CUITimerModeViewModel)

__block CUITimerModeViewModel *timerModeViewModel;
__block CUIFakeTimerContainer *timerContainer;
__block NSTimeInterval interval;
__block NSTimeInterval precision;
__block NSString *title;
__block NSURL *iconURL;

beforeEach(^{
  timerContainer = [[CUIFakeTimerContainer alloc] init];
  interval = 3;
  precision = 0.1;
  title = @"Auto";
  iconURL = [NSURL URLWithString:@"http://lightricks.com"];
  timerModeViewModel = [[CUITimerModeViewModel alloc] initWithTimerContainer:timerContainer
                                                                    interval:interval
                                                                   precision:precision
                                                                       title:title
                                                                     iconURL:iconURL];
});

context(@"initialization", ^{
  it(@"should set correct defaults", ^{
    expect(timerModeViewModel.hidden).to.beFalsy();
    expect(timerModeViewModel.enabled).to.beTruthy();
    expect(timerModeViewModel.subitems).to.beNil();
  });

  it(@"should set values from initializer", ^{
    expect(timerModeViewModel.interval).to.equal(interval);
    expect(timerModeViewModel.precision).to.equal(precision);
    expect(timerModeViewModel.title).to.equal(title);
    expect(timerModeViewModel.iconURL).to.equal(iconURL);
  });

  it(@"should not raise exception when initializing with zero interval", ^{
    expect(^{
      CUITimerModeViewModel * __unused viewModel =
        [[CUITimerModeViewModel alloc] initWithTimerContainer:timerContainer
                                                     interval:0
                                                    precision:precision
                                                        title:title
                                                      iconURL:iconURL];
    }).notTo.raiseAny();
  });

  it(@"should raise exception when initializing with zero precision", ^{
    expect(^{
      CUITimerModeViewModel * __unused viewModel =
        [[CUITimerModeViewModel alloc] initWithTimerContainer:timerContainer
                                                     interval:interval
                                                    precision:0
                                                        title:title
                                                      iconURL:iconURL];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise exception when initializing with negative interval", ^{
    expect(^{
      CUITimerModeViewModel * __unused viewModel =
        [[CUITimerModeViewModel alloc] initWithTimerContainer:timerContainer
                                                     interval:-1
                                                    precision:precision
                                                        title:title
                                                      iconURL:iconURL];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise exception when initializing with negative precision", ^{
    expect(^{
      CUITimerModeViewModel * __unused viewModel =
        [[CUITimerModeViewModel alloc] initWithTimerContainer:timerContainer
                                                     interval:interval
                                                    precision:-1
                                                        title:title
                                                      iconURL:iconURL];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize correctly when using class initializer", ^{
    CUITimerModeViewModel *viewModel =
        [[CUITimerModeViewModel alloc] initWithTimerContainer:timerContainer
                                                     interval:interval precision:precision
                                                        title:title iconURL:iconURL];
    expect(viewModel.interval).to.equal(interval);
    expect(viewModel.precision).to.equal(precision);
    expect(viewModel.title).to.equal(title);
    expect(viewModel.iconURL).to.equal(iconURL);
  });
});

context(@"selected", ^{
  it(@"should be selected when matching the container's interval", ^{
    timerContainer.interval = 3.2;
    expect(timerModeViewModel.selected).to.beFalsy();

    timerContainer.interval = 2.95;
    expect(timerModeViewModel.selected).to.beTruthy();
  });
});

context(@"enabledSignal", ^{
  it(@"should update the enabled property", ^{
    RACSubject *enabledSignal = [[RACSubject alloc] init];
    timerModeViewModel.enabledSignal = enabledSignal;
    expect(timerModeViewModel.enabled).to.beTruthy();

    [enabledSignal sendNext:@NO];
    expect(timerModeViewModel.enabled).will.beFalsy();

    [enabledSignal sendNext:@YES];
    expect(timerModeViewModel.enabled).will.beTruthy();
  });
});

context(@"didTap", ^{
  it(@"should set the container's interval", ^{
    timerContainer.interval = 5;
    [timerModeViewModel didTap];
    expect(timerContainer.interval).to.beCloseTo(timerModeViewModel.interval);
  });
});

SpecEnd
