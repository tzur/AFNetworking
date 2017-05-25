// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksContextGenerators.h"

#import <Intelligence/INTAnalytricksContext.h>
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

  context(@"after launch event", ^{
    __block INTAppContext *contextAfterLaunch;

    beforeEach(^{
      auto launchEvent = [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:YES];
      contextAfterLaunch = contextGenerator(@{}, INTCreateEventMetadata(), launchEvent);
    });

    it(@"should create a new analytricks context on launch", ^{
      expect(contextAfterLaunch[kINTAppContextAnalytricksContextKey])
          .to.beKindOf(INTAnalytricksContext.class);
    });

    it(@"should set new session id on foreground", ^{
      auto foregroundEvents = @[
        [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:NO],
        [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:NO],
        [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:NO]
      ];

      auto generatedContexts =
          INTGenerateContexts(contextGenerator, foregroundEvents, contextAfterLaunch);

      auto sessionIDs =
          [NSSet setWithArray:[generatedContexts lt_map:^NSUUID *(INTAppContext *context) {
            return [context[kINTAppContextAnalytricksContextKey] sessionID];
          }]];

      expect(generatedContexts).to.haveCount(sessionIDs.count);
    });

    it(@"should set new screen usage id on screen display", ^{
      auto screenOpenedEvents = @[
        [[INTScreenDisplayedEvent alloc] initWithScreenName:@"foo"],
        [[INTScreenDisplayedEvent alloc] initWithScreenName:@"bar"],
        [[INTScreenDisplayedEvent alloc] initWithScreenName:@"baz"]
      ];

      auto generatedContexts =
          INTGenerateContexts(contextGenerator, screenOpenedEvents, contextAfterLaunch);

      auto screenUsageIDs =
          [NSSet setWithArray:[generatedContexts lt_map:^NSUUID *(INTAppContext *context) {
            return [context[kINTAppContextAnalytricksContextKey] screenUsageID];
          }]];

      expect(generatedContexts).to.haveCount(screenUsageIDs.count);
    });

    it(@"should set current screen name when a screen is displayed", ^{
      auto screenOpenedEvents = @[
        [[INTScreenDisplayedEvent alloc] initWithScreenName:@"foo"],
        [[INTScreenDisplayedEvent alloc] initWithScreenName:@"bar"],
        [[INTScreenDisplayedEvent alloc] initWithScreenName:@"baz"]
      ];

      auto generatedContexts =
          INTGenerateContexts(contextGenerator, screenOpenedEvents, contextAfterLaunch);

      auto screenNames = [generatedContexts lt_map:^NSString *(INTAppContext *context) {
        return [context[kINTAppContextAnalytricksContextKey] screenName] ;
      }];

      expect(screenNames).to.haveCount(@[@"foo", @"bar", @"baz"].count);
    });

    it(@"should set current project id according to the opened project", ^{
      auto projectLoadedEvents = @[
        [[INTProjectLoadedEvent alloc] initWithProjectID:@"foo" isNew:NO],
        [[INTProjectLoadedEvent alloc] initWithProjectID:@"foo.bar" isNew:NO],
        [[INTProjectLoadedEvent alloc] initWithProjectID:@"foo.bar.bar" isNew:NO]
      ];

      auto generatedContexts =
          INTGenerateContexts(contextGenerator, projectLoadedEvents, contextAfterLaunch);

      auto openProjectIDs = [generatedContexts lt_map:^id (INTAppContext *context) {
        return [context[kINTAppContextAnalytricksContextKey] openProjectID];
      }];

      auto expectedIDs = [projectLoadedEvents lt_map:^id (INTProjectLoadedEvent *event) {
        return event.projectID;
      }];

      expect(openProjectIDs).to.equal(expectedIDs);
    });
  });

  context(@"before launch event", ^{
    __block INTAppContext *startContext;

    beforeEach(^{
      startContext = @{@"foo": @"bar"};
    });

    it(@"should not update context on events other than launch", ^{
      auto foregroundEvents = @[
        [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:NO],
        [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:NO],
        [[INTProjectLoadedEvent alloc] initWithProjectID:@"foo" isNew:NO],
        [[INTProjectLoadedEvent alloc] initWithProjectID:@"foo.bar" isNew:NO],
        [[INTProjectUnloadedEvent alloc] initWithProjectID:@"foo" diskSpaceOnUnload:nil],
        [[INTProjectUnloadedEvent alloc] initWithProjectID:@"foo.bar" diskSpaceOnUnload:nil],
        [[INTScreenDisplayedEvent alloc] initWithScreenName:@"foo"],
        [[INTScreenDisplayedEvent alloc] initWithScreenName:@"bar"]
      ];

      auto generatedContexts =
          [NSSet setWithArray:INTGenerateContexts(contextGenerator, foregroundEvents,
                                                  startContext)];
      expect(generatedContexts).to.equal([NSSet setWithObject:startContext]);
    });
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
         advertisingTrackingEnabled:YES deviceKind:@"foo" iosVersion:@"foo" appVersion:@"foo"
         appVersionShort:@"foo" timeZone:@"foo" country:nil preferredLanguage:nil
         currentAppLanguage:nil purchaseReceipt:nil appStoreCountry:nil];

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

SpecEnd
