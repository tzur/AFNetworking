// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksTransformerBlocks.h"

#import <Intelligence/INTAnalytricksAppBackgrounded.h>
#import <Intelligence/INTAnalytricksAppForegrounded.h>
#import <Intelligence/INTAnalytricksContext.h>
#import <Intelligence/INTAnalytricksMetadata.h>
#import <Intelligence/INTAnalytricksScreenVisited.h>
#import <Intelligence/INTAppBackgroundedEvent.h>
#import <Intelligence/INTAppBecameActiveEvent.h>
#import <Intelligence/INTAppWillEnterForegroundEvent.h>
#import <Intelligence/INTDeepLinkOpenedEvent.h>
#import <Intelligence/INTPushNotificationOpenedEvent.h>
#import <Intelligence/INTScreenDismissedEvent.h>
#import <Intelligence/INTScreenDisplayedEvent.h>

#import "INTAnalytricksTransformerBlockExamples.h"
#import "INTCycleTransformerBlockBuilder.h"
#import "INTEventMetadata.h"
#import "INTEventTransformationExecutor.h"

SpecBegin(INTAnalytricksTransformerBlocks)

context(@"analytricks foreground event transformer", ^{
  __block INTAppWillEnterForegroundEvent *appWillForegroundEvent;
  __block INTAppBecameActiveEvent *appBecameActiveEvent;
  __block NSDictionary *sharedExampleDict;

  beforeEach(^{
    appWillForegroundEvent = [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:YES];
    appBecameActiveEvent = [[INTAppBecameActiveEvent alloc] init];
    auto block = [INTAnalytricksBaseUsageTransformerBlocks foregroundEventTransformer];
    sharedExampleDict = @{
      kINTAnalytricksBaseUsageTransformerBlock: block,
      kINTShouldUseStartContext: @YES,
      kINTShouldUseStartMetadata: @YES
    };
  });

  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto dataProvider = [[INTAnalytricksAppForegrounded alloc]
                         initWithSource:@"app_launcher" isLaunch:YES];
    NSMutableDictionary *exampleData = [sharedExampleDict mutableCopy];
    [exampleData addEntriesFromDictionary:@{
      kINTAnalytricksEventTransformerArgumentsSequence: @[
        INTEventTransformerArgs(appWillForegroundEvent, INTCreateEventMetadata()),
        INTEventTransformerArgs(appBecameActiveEvent, INTCreateEventMetadata(2))
      ],
      kINTExpectedAnalytricksBaseUsageDataProviders: @[dataProvider]
    }];

    return [exampleData copy];
  });

  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto pushNotificationEvent = [[INTPushNotificationOpenedEvent alloc]
                                  initWithPushID:@"foo" deepLink:nil];

    auto dataProvider = [[INTAnalytricksAppForegrounded alloc]
                         initWithSource:@"push_notification" isLaunch:YES];
    NSMutableDictionary *exampleData = [sharedExampleDict mutableCopy];
    [exampleData addEntriesFromDictionary:@{
      kINTAnalytricksEventTransformerArgumentsSequence: @[
        INTEventTransformerArgs(appWillForegroundEvent, INTCreateEventMetadata()),
        INTEventTransformerArgs(pushNotificationEvent, INTCreateEventMetadata(1)),
        INTEventTransformerArgs(appBecameActiveEvent, INTCreateEventMetadata(2))
      ],
      kINTExpectedAnalytricksBaseUsageDataProviders: @[dataProvider]
    }];

    return [exampleData copy];
  });

  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto deepLinkEvent = [[INTDeepLinkOpenedEvent alloc] initWithDeepLink:@"foo://bar.com"];

    auto dataProvider = [[INTAnalytricksAppForegrounded alloc]
                         initWithSource:@"deep_link" isLaunch:YES];
    NSMutableDictionary *exampleData = [sharedExampleDict mutableCopy];
    [exampleData addEntriesFromDictionary:@{
      kINTAnalytricksEventTransformerArgumentsSequence: @[
        INTEventTransformerArgs(appWillForegroundEvent, INTCreateEventMetadata()),
        INTEventTransformerArgs(deepLinkEvent, INTCreateEventMetadata(1)),
        INTEventTransformerArgs(appBecameActiveEvent, INTCreateEventMetadata(2))
      ],
      kINTExpectedAnalytricksBaseUsageDataProviders: @[dataProvider]
    }];

    return [exampleData copy];
  });
});

context(@"analytricks foreground event transformer", ^{
  __block INTAppWillEnterForegroundEvent *appWillForegroundEvent;
  __block INTAppBackgroundedEvent *appBackgroundedEvent;
  __block NSDictionary *sharedExampleDict;

  beforeEach(^{
    appWillForegroundEvent = [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:YES];
    appBackgroundedEvent = [[INTAppBackgroundedEvent alloc] init];
    auto block = [INTAnalytricksBaseUsageTransformerBlocks backgroundEventTransformer];
    sharedExampleDict = @{kINTAnalytricksBaseUsageTransformerBlock: block};
  });

  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksAppBackgrounded alloc] initWithForegroundDuration:@2],
      [[INTAnalytricksAppBackgrounded alloc] initWithForegroundDuration:@83]
    ];
    NSMutableDictionary *exampleData = [sharedExampleDict mutableCopy];
    [exampleData addEntriesFromDictionary:@{
      kINTAnalytricksEventTransformerArgumentsSequence: @[
        INTEventTransformerArgs(appWillForegroundEvent, INTCreateEventMetadata()),
        INTEventTransformerArgs(appBackgroundedEvent, INTCreateEventMetadata(2)),
        INTEventTransformerArgs(appBackgroundedEvent, INTCreateEventMetadata(5)),
        INTEventTransformerArgs(appWillForegroundEvent, INTCreateEventMetadata(7)),
        INTEventTransformerArgs(appBackgroundedEvent, INTCreateEventMetadata(90))
      ],
      kINTCycleStartIndices: @[@0, @3],
      kINTExpectedAnalytricksBaseUsageDataProviders: dataProviders
    }];

    return [exampleData copy];
  });
});

context(@"analytricks screen visited event transformer", ^{
  __block INTScreenDisplayedEvent *screenDisplayedEvent;
  __block INTScreenDismissedEvent *screenDismissedEvent;
  __block NSDictionary *sharedExampleDict;

  beforeEach(^{
    screenDisplayedEvent = [[INTScreenDisplayedEvent alloc] initWithScreenName:@"foo"];
    screenDismissedEvent = [[INTScreenDismissedEvent alloc] initWithScreenName:@"foo"
                                                                 dismissAction:@"baz"];
    auto block = [INTAnalytricksBaseUsageTransformerBlocks screenVisitedEventTransformer];
    sharedExampleDict = @{
      kINTAnalytricksBaseUsageTransformerBlock: block
    };
  });

  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksScreenVisited alloc] initWithScreenDuration:@2 dismissAction:@"baz"],
      [[INTAnalytricksScreenVisited alloc] initWithScreenDuration:@43 dismissAction:@"baz"]
    ];
    NSMutableDictionary *exampleData = [sharedExampleDict mutableCopy];
    [exampleData addEntriesFromDictionary:@{
      kINTAnalytricksEventTransformerArgumentsSequence: @[
        INTEventTransformerArgs(screenDisplayedEvent, INTCreateEventMetadata()),
        INTEventTransformerArgs(screenDismissedEvent, INTCreateEventMetadata(2)),
        INTEventTransformerArgs(screenDismissedEvent, INTCreateEventMetadata(6)),
        INTEventTransformerArgs(screenDisplayedEvent, INTCreateEventMetadata(7)),
        INTEventTransformerArgs(screenDismissedEvent, INTCreateEventMetadata(50))
      ],
      kINTCycleStartIndices: @[@0, @3],
      kINTExpectedAnalytricksBaseUsageDataProviders: dataProviders
    }];

    return [exampleData copy];
  });
});

SpecEnd
