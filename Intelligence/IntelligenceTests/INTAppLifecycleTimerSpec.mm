// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAppLifecycleTimer.h"

#import <LTKit/LTTimer.h>

@interface INTFakeTimeProvider : NSObject <LTTimeIntervalProvider>
@property (nonatomic) CFTimeInterval currentTime;
@end

@implementation INTFakeTimeProvider
@end

SpecBegin(INTAppLifecycleTimer)

__block INTFakeTimeProvider *timeProvider;
__block INTAppLifecycleTimer *timer;

beforeEach(^{
  timeProvider = [[INTFakeTimeProvider alloc] init];
  timer = [[INTAppLifecycleTimer alloc] initWithTimeProvider:timeProvider];
});

context(@"inactive active timer", ^{
  it(@"should not measure total run time", ^{
    expect([timer appRunTimes].totalRunTime).to.equal(0);
    timeProvider.currentTime++;
    expect([timer appRunTimes].totalRunTime).to.equal(0);
    timeProvider.currentTime++;
    expect([timer appRunTimes].totalRunTime).to.equal(0);
  });

  it(@"should not measure foreground run time", ^{
    expect([timer appRunTimes].foregroundRunTime).to.equal(0);
    timeProvider.currentTime++;
    expect([timer appRunTimes].foregroundRunTime).to.equal(0);
    timeProvider.currentTime++;
    expect([timer appRunTimes].foregroundRunTime).to.equal(0);
  });
});

context(@"active timer", ^{
  beforeEach(^{
    [timer start];
  });

  it(@"should measure total run time correctly between queries", ^{
    expect([timer appRunTimes].totalRunTime).to.equal(0);
    timeProvider.currentTime++;
    expect([timer appRunTimes].totalRunTime).to.equal(1);
    timeProvider.currentTime++;
    expect([timer appRunTimes].totalRunTime).to.equal(2);
  });

  it(@"should measure foreground run time correctly between queries", ^{
    expect([timer appRunTimes].foregroundRunTime).to.equal(0);
    timeProvider.currentTime++;
    expect([timer appRunTimes].foregroundRunTime).to.equal(1);
    timeProvider.currentTime++;
    expect([timer appRunTimes].foregroundRunTime).to.equal(2);
  });

  it(@"should not increase foreground run time if application is in background", ^{
    timeProvider.currentTime++;

    [[NSNotificationCenter defaultCenter]
     postNotificationName:UIApplicationDidEnterBackgroundNotification
     object:self];

    timeProvider.currentTime++;
    expect([timer appRunTimes].foregroundRunTime).to.equal(1);
    timeProvider.currentTime++;
    expect([timer appRunTimes].foregroundRunTime).to.equal(1);
  });

  it(@"should increase foreground run time if application is back to foreground", ^{
    timeProvider.currentTime++;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:UIApplicationDidEnterBackgroundNotification
     object:self];

    timeProvider.currentTime++;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:UIApplicationWillEnterForegroundNotification
     object:self];

    expect([timer appRunTimes].foregroundRunTime).to.equal(1);
    timeProvider.currentTime++;
    expect([timer appRunTimes].foregroundRunTime).to.equal(2);
  });

  it(@"should increase foreground run time after foregound and background transitions", ^{
    timeProvider.currentTime++;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:UIApplicationDidEnterBackgroundNotification
     object:self];

    timeProvider.currentTime++;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:UIApplicationWillEnterForegroundNotification
     object:self];

    timeProvider.currentTime++;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:UIApplicationDidEnterBackgroundNotification
     object:self];

    timeProvider.currentTime++;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:UIApplicationWillEnterForegroundNotification
     object:self];

    expect([timer appRunTimes].foregroundRunTime).to.equal(2);
    timeProvider.currentTime++;
    expect([timer appRunTimes].foregroundRunTime).to.equal(3);
  });
});

SpecEnd
