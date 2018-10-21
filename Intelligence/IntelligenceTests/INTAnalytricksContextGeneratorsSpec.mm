// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksContextGenerators.h"

#import <Intelligence/INTAnalytricksContext.h>
#import <Intelligence/INTAppRunCountUpdatedEvent.h>
#import <Intelligence/INTAppWillEnterForegroundEvent.h>
#import <Intelligence/INTProjectLoadedEvent.h>
#import <Intelligence/INTProjectUnloadedEvent.h>
#import <Intelligence/INTScreenDisplayedEvent.h>
#import <LTKit/NSArray+Functional.h>

#import "INTDeviceInfo.h"
#import "INTDeviceInfoLoadedEvent.h"
#import "INTEventMetadata.h"

static NSArray<INTAppContext *> *INTGenerateContexts(INTAppContextGeneratorBlock contextGenerator,
                                                     NSArray *events,
                                                     INTAppContext *startContext = @{}) {
  NSMutableArray *generatedContexts = [NSMutableArray array];
  auto currentContext = startContext;
  for (id event in events) {
    currentContext = contextGenerator(currentContext, INTCreateEventMetadata(), event);
    [generatedContexts addObject:currentContext];
  }
  return generatedContexts;
}

SpecBegin(INTAnalytricksContextGenerators)

context(@"analytricks context generator", ^{
  __block INTAppContextGeneratorBlock contextGenerator;

  beforeEach(^{
    contextGenerator = [INTAnalytricksContextGenerators analytricksContextGenerator];
  });

  it(@"should create a new analytricks context on first event that is processed", ^{
    auto context = contextGenerator(@{}, INTCreateEventMetadata(), @"foo");
    INTAnalytricksContext *analytricksContext = context[kINTAppContextAnalytricksContextKey];

    expect(analytricksContext).to.beKindOf(INTAnalytricksContext.class);
    expect(analytricksContext.runID).toNot.beNil();
  });

  it(@"should set new session id on foreground", ^{
    auto foregroundEvents = @[
      [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:NO],
      [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:YES],
      [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:NO]
    ];

    auto generatedContexts = INTGenerateContexts(contextGenerator, foregroundEvents);

    auto sessionIDs =
        [NSSet setWithArray:[generatedContexts lt_map:^NSUUID *(INTAppContext *context) {
          return [context[kINTAppContextAnalytricksContextKey] sessionID];
        }]];

    expect(sessionIDs).to.haveCount(3);
  });

  it(@"should set new screen usage id on screen display", ^{
    auto screenOpenedEvents = @[
      [[INTScreenDisplayedEvent alloc] initWithScreenName:@"foo"],
      [[INTScreenDisplayedEvent alloc] initWithScreenName:@"bar"],
      [[INTScreenDisplayedEvent alloc] initWithScreenName:@"baz"]
    ];

    auto generatedContexts = INTGenerateContexts(contextGenerator, screenOpenedEvents);

    auto screenUsageIDs =
        [NSSet setWithArray:[generatedContexts lt_map:^NSUUID *(INTAppContext *context) {
          return [context[kINTAppContextAnalytricksContextKey] screenUsageID];
        }]];

    expect(screenUsageIDs).to.haveCount(3);
  });

  it(@"should set current screen name when a screen is displayed", ^{
    auto screenOpenedEvents = @[
      [[INTScreenDisplayedEvent alloc] initWithScreenName:@"foo"],
      [[INTScreenDisplayedEvent alloc] initWithScreenName:@"bar"],
      [[INTScreenDisplayedEvent alloc] initWithScreenName:@"baz"]
    ];

    auto generatedContexts = INTGenerateContexts(contextGenerator, screenOpenedEvents);

    auto screenNames = [generatedContexts lt_map:^NSString *(INTAppContext *context) {
      return [context[kINTAppContextAnalytricksContextKey] screenName];
    }];

    expect(screenNames).to.equal(@[@"foo", @"bar", @"baz"]);
  });

  it(@"should set current project id according to the opened project", ^{
    auto projectLoadedEvents = @[
      [[INTProjectLoadedEvent alloc] initWithProjectID:[NSUUID UUID] isNew:NO],
      [[INTProjectLoadedEvent alloc] initWithProjectID:[NSUUID UUID] isNew:NO],
      [[INTProjectLoadedEvent alloc] initWithProjectID:[NSUUID UUID] isNew:NO]
    ];

    auto generatedContexts = INTGenerateContexts(contextGenerator, projectLoadedEvents);

    auto openProjectIDs = [generatedContexts lt_map:^id (INTAppContext *context) {
      return [context[kINTAppContextAnalytricksContextKey] openProjectID];
    }];

    auto expectedIDs = [projectLoadedEvents lt_map:^id (INTProjectLoadedEvent *event) {
      return event.projectID;
    }];

    expect(openProjectIDs).to.equal(expectedIDs);
  });
});

context(@"device info context generator", ^{
  __block INTAppContext *contextAfterDeviceInfoLoadedEvent;
  __block NSUUID *idfv;
  __block NSUUID *deviceInfoRevisionID;

  beforeEach(^{
    auto contextGenerator = [INTAnalytricksContextGenerators deviceInfoContextGenerator];
    idfv = [NSUUID UUID];
    deviceInfoRevisionID = [NSUUID UUID];

    auto deviceInfo =
        [[INTDeviceInfo alloc]
         initWithIdentifierForVendor:idfv advertisingID:[NSUUID UUID]
         advertisingTrackingEnabled:YES deviceModel:@"foo" deviceKind:@"foo" iosVersion:@"foo"
         appVersion:@"foo" appVersionShort:@"foo" timeZone:@"foo" country:nil preferredLanguage:nil
         currentAppLanguage:nil purchaseReceipt:nil appStoreCountry:nil inLowPowerMode:nil
         firmwareID:nil usageEventsDisabled:nil];

    auto deviceInfoLoadedEvent =
        [[INTDeviceInfoLoadedEvent alloc] initWithDeviceInfo:deviceInfo
                                        deviceInfoRevisionID:deviceInfoRevisionID isNewRevision:NO];

    contextAfterDeviceInfoLoadedEvent =
        contextGenerator(@{}, INTCreateEventMetadata(), deviceInfoLoadedEvent);
  });

  it(@"should set device id to identifier for vendor on launch", ^{
    expect(contextAfterDeviceInfoLoadedEvent[kINTAppContextDeviceIDKey]).to.equal(idfv);
  });

  it(@"should set device info id to identifier for vendor on launch", ^{
    expect(contextAfterDeviceInfoLoadedEvent[kINTAppContextDeviceInfoIDKey]).to
        .equal(deviceInfoRevisionID);
  });
});

context(@"app run count context generator", ^{
  __block INTAppContextGeneratorBlock contextGenerator;

  beforeEach(^{
    contextGenerator = [INTAnalytricksContextGenerators appRunCountContextGenerator];
  });

  it(@"should set run count to the run count of the observed event", ^{
    auto appRunCountUpdatedEvent = [[INTAppRunCountUpdatedEvent alloc] initWithRunCount:@4];
    auto updatedContext = contextGenerator(@{}, INTCreateEventMetadata(), appRunCountUpdatedEvent);

    expect(updatedContext[kINTAppContextAppRunCountKey]).to.equal(@4);
  });
});

SpecEnd
