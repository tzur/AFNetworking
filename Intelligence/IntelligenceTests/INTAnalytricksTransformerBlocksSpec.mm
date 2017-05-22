// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksTransformerBlocks.h"

#import <Intelligence/INTAnalytricksAppBackgrounded.h>
#import <Intelligence/INTAnalytricksAppForegrounded.h>
#import <Intelligence/INTAnalytricksContext.h>
#import <Intelligence/INTAnalytricksDeepLinkOpened.h>
#import <Intelligence/INTAnalytricksMediaExported.h>
#import <Intelligence/INTAnalytricksMediaImported.h>
#import <Intelligence/INTAnalytricksMetadata.h>
#import <Intelligence/INTAnalytricksPushNotificationOpened.h>
#import <Intelligence/INTAnalytricksScreenVisited.h>
#import <Intelligence/INTAppBackgroundedEvent.h>
#import <Intelligence/INTAppBecameActiveEvent.h>
#import <Intelligence/INTAppWillEnterForegroundEvent.h>
#import <Intelligence/INTDeepLinkOpenedEvent.h>
#import <Intelligence/INTMediaExportEndedEvent.h>
#import <Intelligence/INTMediaExportStartedEvent.h>
#import <Intelligence/INTMediaImportedEvent.h>
#import <Intelligence/INTPushNotificationOpenedEvent.h>
#import <Intelligence/INTScreenDismissedEvent.h>
#import <Intelligence/INTScreenDisplayedEvent.h>
#import <LTKit/NSArray+Functional.h>

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

context(@"analytricks deep link opened event transformer", ^{
  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksDeepLinkOpened alloc] initWithDeepLink:@"http://foo.bar"],
      [[INTAnalytricksDeepLinkOpened alloc] initWithDeepLink:@"http://baz.foo"]
    ];

    return @{
      kINTAnalytricksBaseUsageTransformerBlock: [INTAnalytricksBaseUsageTransformerBlocks
                                                 deepLinkOpenedEventTransformer],
      kINTAnalytricksEventTransformerArgumentsSequence: @[
        INTEventTransformerArgs([[INTDeepLinkOpenedEvent alloc] initWithDeepLink:@"http://foo.bar"],
                                INTCreateEventMetadata()),
        INTEventTransformerArgs([[INTDeepLinkOpenedEvent alloc] initWithDeepLink:@"http://baz.foo"],
                                INTCreateEventMetadata()),
      ],
      kINTExpectedAnalytricksBaseUsageDataProviders: dataProviders
    };
  });
});

context(@"analytricks push notification received event transformer", ^{
  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksPushNotificationOpened alloc] initWithPushID:@"foo" deepLink:nil],
      [[INTAnalytricksPushNotificationOpened alloc] initWithPushID:@"bar" deepLink:@"http://foo"]
    ];

    return @{
      kINTAnalytricksBaseUsageTransformerBlock: [INTAnalytricksBaseUsageTransformerBlocks
                                                 pushNotificationOpenedEventTransformer],
      kINTAnalytricksEventTransformerArgumentsSequence: @[
        INTEventTransformerArgs([[INTPushNotificationOpenedEvent alloc]
                                 initWithPushID:@"foo" deepLink:nil],
                                INTCreateEventMetadata()),
        INTEventTransformerArgs([[INTPushNotificationOpenedEvent alloc]
                                 initWithPushID:@"bar" deepLink:@"http://foo"],
                                INTCreateEventMetadata()),
      ],
      kINTExpectedAnalytricksBaseUsageDataProviders: dataProviders
    };
  });
});

context(@"analytricks media imported event transformer", ^{
  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksMediaImported alloc]
       initWithAssetType:@"image" format:@"png" assetWidth:345 assetHeight:32 assetDuration:nil
       importSource:@"Camera Roll" assetID:@"foo.bar.baz" isFromBundle:@YES],
      [[INTAnalytricksMediaImported alloc]
       initWithAssetType:@"video" format:@"mp4" assetWidth:345 assetHeight:24 assetDuration:@3
       importSource:@"Camera Roll" assetID:@"foo.bar.baz.thud" isFromBundle:@NO],
    ];

    auto args = [@[
      [[INTMediaImportedEvent alloc]
       initWithAssetType:@"image" format:@"png" assetWidth:345 assetHeight:32 assetDuration:nil
       importSource:@"Camera Roll" assetID:@"foo.bar.baz" isFromBundle:@YES],
      [[INTMediaImportedEvent alloc]
       initWithAssetType:@"video" format:@"mp4" assetWidth:345 assetHeight:24 assetDuration:@3
       importSource:@"Camera Roll" assetID:@"foo.bar.baz.thud" isFromBundle:@NO],
    ] lt_map:^(INTMediaImportedEvent *event) {
      return INTEventTransformerArgs(event, INTCreateEventMetadata());
    }];

    return @{
      kINTAnalytricksBaseUsageTransformerBlock: [INTAnalytricksBaseUsageTransformerBlocks
                                                 mediaImportedEventTransformer],
      kINTAnalytricksEventTransformerArgumentsSequence: args,
      kINTExpectedAnalytricksBaseUsageDataProviders: dataProviders
    };
  });
});

context(@"analytricks media imported event transformer", ^{
  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksMediaImported alloc]
       initWithAssetType:@"image" format:@"png" assetWidth:345 assetHeight:32 assetDuration:nil
       importSource:@"Camera Roll" assetID:@"foo.bar.baz" isFromBundle:@YES],
      [[INTAnalytricksMediaImported alloc]
       initWithAssetType:@"video" format:@"mp4" assetWidth:345 assetHeight:24 assetDuration:@3
       importSource:@"Camera Roll" assetID:@"foo.bar.baz.thud" isFromBundle:@NO],
    ];

    auto args = [@[
      [[INTMediaImportedEvent alloc]
       initWithAssetType:@"image" format:@"png" assetWidth:345 assetHeight:32 assetDuration:nil
       importSource:@"Camera Roll" assetID:@"foo.bar.baz" isFromBundle:@YES],
      [[INTMediaImportedEvent alloc]
       initWithAssetType:@"video" format:@"mp4" assetWidth:345 assetHeight:24 assetDuration:@3
       importSource:@"Camera Roll" assetID:@"foo.bar.baz.thud" isFromBundle:@NO]
    ] lt_map:^(INTMediaImportedEvent *event) {
      return INTEventTransformerArgs(event, INTCreateEventMetadata());
    }];

    return @{
      kINTAnalytricksBaseUsageTransformerBlock: [INTAnalytricksBaseUsageTransformerBlocks
                                                 mediaImportedEventTransformer],
      kINTAnalytricksEventTransformerArgumentsSequence: args,
      kINTExpectedAnalytricksBaseUsageDataProviders: dataProviders
    };
  });
});

context(@"analytricks media exported event transformer", ^{
  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto exportID1 = [NSUUID UUID];
    auto exportID2 = [NSUUID UUID];
    auto projectID = [NSUUID UUID];
    auto dataProviders = @[
      [[INTAnalytricksMediaExported alloc]
       initWithExportID:exportID1 assetType:@"image" format:@"png" assetWidth:234 assetHeight:443
       assetDuration:@34 exportTarget:@"Facebook" assetID:@"foo.bar" projectID:projectID
       isSuccessful:YES],
      [[INTAnalytricksMediaExported alloc]
       initWithExportID:exportID1 assetType:@"image" format:@"png" assetWidth:234 assetHeight:44
       assetDuration:@34 exportTarget:@"Facebook" assetID:@"foo.bar1" projectID:projectID
       isSuccessful:YES],
      [[INTAnalytricksMediaExported alloc]
       initWithExportID:exportID2 assetType:@"video" format:@"mp4" assetWidth:234 assetHeight:443
       assetDuration:@34 exportTarget:@"Camera Roll" assetID:@"foo.bar" projectID:projectID
       isSuccessful:NO]
    ];

    auto args = [@[
      [[INTMediaExportStartedEvent alloc]
       initWithExportID:exportID1 assetType:@"image" format:@"png" assetWidth:234 assetHeight:443
       assetDuration:@34 exportTarget:@"Facebook" assetID:@"foo.bar" projectID:projectID],
      [[INTMediaExportStartedEvent alloc]
       initWithExportID:exportID1 assetType:@"image" format:@"png" assetWidth:234 assetHeight:44
       assetDuration:@34 exportTarget:@"Facebook" assetID:@"foo.bar1" projectID:projectID],
      [[INTMediaExportEndedEvent alloc] initWithExportID:exportID1 isSuccessful:YES],
      [[INTMediaExportStartedEvent alloc]
       initWithExportID:exportID2 assetType:@"video" format:@"mp4" assetWidth:234 assetHeight:443
       assetDuration:@34 exportTarget:@"Camera Roll" assetID:@"foo.bar" projectID:projectID],
      [[INTMediaExportEndedEvent alloc] initWithExportID:exportID2 isSuccessful:NO],
      [[INTMediaExportEndedEvent alloc] initWithExportID:exportID2 isSuccessful:NO],
      [[INTMediaExportEndedEvent alloc] initWithExportID:exportID1 isSuccessful:YES]
    ] lt_map:^(INTMediaImportedEvent *event) {
      return INTEventTransformerArgs(event, INTCreateEventMetadata(5));
    }];

    return @{
      kINTAnalytricksBaseUsageTransformerBlock: [INTAnalytricksBaseUsageTransformerBlocks
                                                 mediaExportedEventTransformer],
      kINTAnalytricksEventTransformerArgumentsSequence: args,
      kINTExpectedAnalytricksBaseUsageDataProviders: dataProviders
    };
  });

  itShouldBehaveLike(kINTAnalytricksBaseUsageTransformerBlockExamples, ^{
    auto projectID = [NSUUID UUID];

    auto args = [@[
      [[INTMediaExportStartedEvent alloc]
       initWithExportID:[NSUUID UUID] assetType:@"image" format:@"png" assetWidth:234
       assetHeight:443 assetDuration:@34 exportTarget:@"Facebook" assetID:@"foo.bar"
       projectID:projectID],
      [[INTMediaExportEndedEvent alloc] initWithExportID:[NSUUID UUID] isSuccessful:YES],
    ] lt_map:^(INTMediaImportedEvent *event) {
      return INTEventTransformerArgs(event, INTCreateEventMetadata(5));
    }];

    return @{
      kINTAnalytricksBaseUsageTransformerBlock: [INTAnalytricksBaseUsageTransformerBlocks
                                                 mediaExportedEventTransformer],
      kINTAnalytricksEventTransformerArgumentsSequence: args,
      kINTExpectedAnalytricksBaseUsageDataProviders: @[]
    };
  });
});

SpecEnd
