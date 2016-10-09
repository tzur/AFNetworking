// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUITimerMenuViewModel.h"

#import "CUIFakeTimerContainer.h"
#import "CUITimerModeViewModel.h"

SpecBegin(CUITimerMenuViewModel)

__block id<CAMTimerContainer> timerContainer;
__block NSArray<CUITimerModeViewModel *> *timerModes;
__block CUITimerMenuViewModel *timerViewModel;

beforeEach(^{
  timerContainer = [[CUIFakeTimerContainer alloc] init];

  CUITimerModeViewModel *mode1 =
      [[CUITimerModeViewModel alloc] initWithTimerContainer:timerContainer
                                                   interval:3
                                                  precision:0.1
                                                      title:@"1"
                                                    iconURL:[NSURL URLWithString:@"icon://1"]];
  CUITimerModeViewModel *mode2 =
      [[CUITimerModeViewModel alloc] initWithTimerContainer:timerContainer
                                                   interval:5
                                                  precision:0.1
                                                      title:@"2"
                                                    iconURL:[NSURL URLWithString:@"icon://2"]];
  CUITimerModeViewModel *mode3 =
      [[CUITimerModeViewModel alloc] initWithTimerContainer:timerContainer
                                                   interval:3
                                                  precision:0.05
                                                      title:@"3"
                                                    iconURL:[NSURL URLWithString:@"icon://3"]];
  timerModes = @[mode1, mode2, mode3];
  timerViewModel = [[CUITimerMenuViewModel alloc] initWithTimerContainer:timerContainer
                                                              timerModes:timerModes];
});

context(@"initialization", ^{
  it(@"should set default values", ^{
    expect(timerViewModel.selected).to.beFalsy();
    expect(timerViewModel.hidden).to.beFalsy();
    expect(timerViewModel.enabled).to.beTruthy();
  });

  it(@"should set values from initializer", ^{
    expect(timerViewModel.subitems).to.equal(timerModes);
  });
});

context(@"title", ^{
  it(@"should match the current interval's title", ^{
    timerContainer.interval = timerModes[0].interval;
    expect(timerViewModel.title).to.equal(timerModes[0].title);
    timerContainer.interval = timerModes[1].interval;
    expect(timerViewModel.title).to.equal(timerModes[1].title);
  });

  it(@"should be nil if current interval doesn't match any submenu item", ^{
    timerContainer.interval = 13;
    expect(timerViewModel.title).to.beNil();
  });

  it(@"should be first match when there is more than one match", ^{
    expect(timerModes[0].interval).to.beCloseTo(timerModes[2].interval);
    timerContainer.interval = timerModes[2].interval;
    expect(timerViewModel.title).to.equal(timerModes[0].title);
  });
});

context(@"iconURL", ^{
  it(@"should match the current interval's icon URL", ^{
    timerContainer.interval = timerModes[0].interval;
    expect(timerViewModel.iconURL).to.equal(timerModes[0].iconURL);
    timerContainer.interval = timerModes[1].interval;
    expect(timerViewModel.iconURL).to.equal(timerModes[1].iconURL);
  });

  it(@"should be nil if current interval doesn't match any submenu item", ^{
    timerContainer.interval = 13;
    expect(timerViewModel.iconURL).to.beNil();
  });

  it(@"should be first match when there is more than one match", ^{
    expect(timerModes[0].interval).to.beCloseTo(timerModes[2].interval);
    timerContainer.interval = timerModes[2].interval;
    expect(timerViewModel.iconURL).to.equal(timerModes[0].iconURL);
  });
});

context(@"enabledSignal", ^{
  it(@"should update the enabled property", ^{
    RACSubject *enabledSignal = [[RACSubject alloc] init];
    timerViewModel.enabledSignal = enabledSignal;
    expect(timerViewModel.enabled).to.beTruthy();

    [enabledSignal sendNext:@NO];
    expect(timerViewModel.enabled).will.beFalsy();

    [enabledSignal sendNext:@YES];
    expect(timerViewModel.enabled).will.beTruthy();
  });
});

SpecEnd
