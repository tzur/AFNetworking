// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksTransformerBlocks.h"

#import <Intelligence/INTAnalytricksAppBackgrounded.h>
#import <Intelligence/INTAnalytricksAppForegrounded.h>
#import <Intelligence/INTAnalytricksContext.h>
#import <Intelligence/INTAnalytricksDeepLinkOpened.h>
#import <Intelligence/INTAnalytricksDeviceInfoChanged.h>
#import <Intelligence/INTAnalytricksDeviceTokenChanged.h>
#import <Intelligence/INTAnalytricksMediaExported.h>
#import <Intelligence/INTAnalytricksMediaImported.h>
#import <Intelligence/INTAnalytricksMetadata.h>
#import <Intelligence/INTAnalytricksProjectDeleted.h>
#import <Intelligence/INTAnalytricksProjectModified.h>
#import <Intelligence/INTAnalytricksPushNotificationOpened.h>
#import <Intelligence/INTAnalytricksScreenVisited.h>
#import <Intelligence/INTAppBackgroundedEvent.h>
#import <Intelligence/INTAppBecameActiveEvent.h>
#import <Intelligence/INTAppWillEnterForegroundEvent.h>
#import <Intelligence/INTDeepLinkOpenedEvent.h>
#import <Intelligence/INTDeviceTokenChangedEvent.h>
#import <Intelligence/INTMediaExportEndedEvent.h>
#import <Intelligence/INTMediaExportStartedEvent.h>
#import <Intelligence/INTMediaImportedEvent.h>
#import <Intelligence/INTProjectDeletedEvent.h>
#import <Intelligence/INTProjectLoadedEvent.h>
#import <Intelligence/INTProjectUnloadedEvent.h>
#import <Intelligence/INTPushNotificationOpenedEvent.h>
#import <Intelligence/INTScreenDismissedEvent.h>
#import <Intelligence/INTScreenDisplayedEvent.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSDateFormatter+Formatters.h>

#import "INTAnalytricksContextGenerators.h"
#import "INTCycleTransformerBlockBuilder.h"
#import "INTDeviceInfo.h"
#import "INTDeviceInfoLoadedEvent.h"
#import "INTEventMetadata.h"
#import "INTEventTransformationExecutor.h"
#import "INTTransformerBlockExamples.h"
#import "NSDictionary+Merge.h"

SpecBegin(INTAnalytricksTransformerBlocks)

context(@"analytricks context enricher", ^{
  __block INTEventEnrichmentBlock block;

  beforeEach(^{
    block = [INTAnalytricksTransformerBlocks analytricksContextEnrichementBlock];
  });

  it(@"should enrich dictionary events", ^{
    auto runID = [NSUUID UUID];
    auto sessionID = [NSUUID UUID];
    auto screenUsageID = [NSUUID UUID];
    auto openProjectID = [NSUUID UUID];

    auto analytricksContext =
        [[INTAnalytricksContext alloc] initWithRunID:runID sessionID:sessionID
                      screenUsageID:screenUsageID screenName:@"foo" openProjectID:openProjectID];
    auto events = @[@{@"foo": @"bar"}, @{@"foo": @"baz"}];
    auto enrichedEvents = block(events, @{
      kINTAppContextAnalytricksContextKey: analytricksContext
    }, INTCreateEventMetadata());

    auto expectedEnrichment = @{
      @"run_id": runID.UUIDString,
      @"session_id": sessionID.UUIDString,
      @"screen_usage_id": screenUsageID.UUIDString,
      @"screen_name": @"foo",
      @"open_project_id": openProjectID.UUIDString
    };

    auto expectedEvents = [events lt_map:^(NSDictionary *event) {
      return [expectedEnrichment int_dictionaryByAddingEntriesFromDictionary:event];
    }];

    expect(enrichedEvents).to.equal(expectedEvents);
  });

  it(@"should prioritize event keys when enriching", ^{
    auto analytricksContext1 =
        [[INTAnalytricksContext alloc] initWithRunID:[NSUUID UUID] sessionID:[NSUUID UUID]
                                       screenUsageID:[NSUUID UUID] screenName:@"foo"
                                       openProjectID:[NSUUID UUID]];
    auto analytricksContext2 =
        [[INTAnalytricksContext alloc] initWithRunID:[NSUUID UUID] sessionID:[NSUUID UUID]
                                       screenUsageID:[NSUUID UUID] screenName:@"bar"
                                       openProjectID:[NSUUID UUID]];
    auto events = @[analytricksContext1.properties];
    auto enrichedEvents = block(events, @{
      kINTAppContextAnalytricksContextKey: analytricksContext2
    }, INTCreateEventMetadata());

    expect(enrichedEvents).to.equal(events);
  });

  it(@"should not enrich dictionary events if analytricks context is missing", ^{
    auto events = @[@{@"foo": @"bar"}, @{@"foo": @"baz"}];
    auto enrichedEvents = block(events, @{}, INTCreateEventMetadata());

    expect(enrichedEvents).to.equal(events);
  });

  it(@"should not enrich non dictionary events", ^{
    auto analytricksContext =
        [[INTAnalytricksContext alloc] initWithRunID:[NSUUID UUID] sessionID:[NSUUID UUID]
                                       screenUsageID:[NSUUID UUID] screenName:@"foo"
                                       openProjectID:[NSUUID UUID]];
    auto events = @[@"foo", @{}];
    auto enrichedEvents = block(events, @{
      kINTAppContextAnalytricksContextKey: analytricksContext
    }, INTCreateEventMetadata());

    expect(enrichedEvents).to.equal(@[@"foo", analytricksContext.properties]);
  });
});

context(@"analytricks metadata enricher", ^{
  __block INTEventEnrichmentBlock block;

  beforeEach(^{
    block = [INTAnalytricksTransformerBlocks analytricksMetadataEnrichementBlock];
  });

  it(@"should enrich dictionary events", ^{
    auto deviceID = [NSUUID UUID];
    auto deviceInfoID = [NSUUID UUID];
    auto metadata = INTCreateEventMetadata(3);

    auto events = @[@{@"foo": @"bar"}, @{@"foo": @"baz"}];
    auto enrichedEvents = block(events, @{
      kINTAppContextDeviceIDKey: deviceID,
      kINTAppContextDeviceInfoIDKey: deviceInfoID
    }, metadata);
    expect(enrichedEvents).to.haveCount(2);

    auto expectedEvents = [NSMutableArray array];
    [events enumerateObjectsUsingBlock:^(NSDictionary *event, NSUInteger idx, BOOL *) {
      expectedEvents[idx] = [event int_mergeUpdates:@{
        @"device_timestamp": [[NSDateFormatter lt_UTCDateFormatter]
                              stringFromDate:metadata.deviceTimestamp],
        @"app_total_run_time": @(3),
        @"lt_device_id": deviceID.UUIDString,
        @"device_info_id": deviceInfoID.UUIDString,
        @"event_id": enrichedEvents[idx][@"event_id"]
      }];
    }];

    expect(enrichedEvents).to.equal(expectedEvents);
  });

  it(@"should create distinct event id for each event", ^{
    auto deviceID = [NSUUID UUID];
    auto deviceInfoID = [NSUUID UUID];
    auto events = @[@{@"foo": @"bar"}, @{@"foo": @"baz"}];
    auto enrichedEvents = block(events, @{
      kINTAppContextDeviceIDKey: deviceID,
      kINTAppContextDeviceInfoIDKey: deviceInfoID
    }, INTCreateEventMetadata());

    auto uuids = [[enrichedEvents lt_map:^NSString *(NSDictionary *event) {
      return event[@"event_id"];
    }] lt_set];

    expect(uuids).to.haveCount(2);
  });

  it(@"should prioritize event keys when enriching", ^{
    auto deviceID = [NSUUID UUID];
    auto deviceInfoID = [NSUUID UUID];
    auto metadata = INTCreateEventMetadata(3);

    auto events = @[@{
      @"event_id": metadata.eventID.UUIDString,
      @"device_timestamp": [[NSDateFormatter lt_UTCDateFormatter]
                            stringFromDate:metadata.deviceTimestamp],
      @"app_total_run_time": @(3),
      @"lt_device_id": deviceID.UUIDString,
      @"device_info_id": deviceInfoID.UUIDString
    }];

    auto enrichedEvents = block(events, @{
      kINTAppContextDeviceIDKey: deviceID,
      kINTAppContextDeviceInfoIDKey: deviceInfoID
    }, metadata);

    expect(enrichedEvents).to.equal(events);
  });

  it(@"should not enrich dictionary events if device ID is missing", ^{
    auto events = @[@{@"foo": @"bar"}, @{@"foo": @"baz"}];
    auto enrichedEvents = block(events, @{
      kINTAppContextDeviceInfoIDKey: [NSUUID UUID]
    }, INTCreateEventMetadata());

    expect(enrichedEvents).to.equal(events);
  });

  it(@"should not enrich dictionary events if device info ID is missing", ^{
    auto events = @[@{@"foo": @"bar"}, @{@"foo": @"baz"}];
    auto enrichedEvents = block(events, @{
      kINTAppContextDeviceInfoIDKey: [NSUUID UUID]
    }, INTCreateEventMetadata());

    expect(enrichedEvents).to.equal(events);
  });

  it(@"should not enrich non dictionary events", ^{
    auto deviceID = [NSUUID UUID];
    auto deviceInfoID = [NSUUID UUID];
    auto metadata = INTCreateEventMetadata(3);

    auto events = @[@"foo", @{}];
    auto enrichedEvents = block(events, @{
      kINTAppContextDeviceIDKey: deviceID,
      kINTAppContextDeviceInfoIDKey: deviceInfoID
    }, metadata);

    auto eventID = [[NSUUID alloc] initWithUUIDString:enrichedEvents[1][@"event_id"]];
    auto analytricksMetadata =
        [[INTAnalytricksMetadata alloc] initWithEventID:eventID
                                        deviceTimestamp:metadata.deviceTimestamp
                                        appTotalRunTime:@(3)
                                             ltDeviceID:deviceID deviceInfoID:deviceInfoID];

    expect(enrichedEvents).to.equal(@[@"foo", analytricksMetadata.properties]);
  });
});

context(@"app run count enricher", ^{
  __block INTEventEnrichmentBlock block;

  beforeEach(^{
    block = [INTAnalytricksTransformerBlocks appRunCountEnrichementBlock];
  });

  it(@"should enrich dictionary events", ^{
    auto events = @[@{@"foo": @"bar"}, @{@"foo": @"baz"}];
    auto enrichedEvents = block(events, @{
      kINTAppContextAppRunCountKey: @3
    }, INTCreateEventMetadata());

    auto expectedEvents = @[
      @{@"foo": @"bar", kINTEnrichmentAppRunCountKey: @3},
      @{@"foo": @"baz", kINTEnrichmentAppRunCountKey: @3}
    ];

    expect(enrichedEvents).to.equal(expectedEvents);
  });

  it(@"should prioritize event keys when enriching", ^{
    auto events = @[@{kINTEnrichmentAppRunCountKey: @2}];
    auto enrichedEvents = block(events, @{
      kINTAppContextAppRunCountKey: @3
    }, INTCreateEventMetadata());

    expect(enrichedEvents).to.equal(events);
  });

  it(@"should not enrich dictionary events if app run count is missing", ^{
    auto events = @[@{@"foo": @"bar"}, @{@"foo": @"baz"}];
    auto enrichedEvents = block(events, @{}, INTCreateEventMetadata());

    expect(enrichedEvents).to.equal(events);
  });

  it(@"should not enrich non dictionary events", ^{
    auto events = @[@"foo", @{}];
    auto enrichedEvents = block(events, @{
      kINTAppContextAppRunCountKey: @3
    }, INTCreateEventMetadata());

    expect(enrichedEvents).to.equal(@[
      @"foo",
      @{kINTEnrichmentAppRunCountKey: @3}
    ]);
  });
});

context(@"analytricks foreground event transformer", ^{
  __block INTAppWillEnterForegroundEvent *appWillForegroundEvent;
  __block INTAppBecameActiveEvent *appBecameActiveEvent;
  __block NSDictionary *sharedExampleDict;

  beforeEach(^{
    appWillForegroundEvent = [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:YES];
    appBecameActiveEvent = [[INTAppBecameActiveEvent alloc] init];
    auto block = [INTAnalytricksTransformerBlocks foregroundEventTransformer];
    sharedExampleDict = @{kINTTransformerBlockExamplesTransformerBlock: block};
  });

  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto expectedEvent = [[INTAnalytricksAppForegrounded alloc]
                         initWithSource:@"app_launcher" isLaunch:YES].properties;

    return [sharedExampleDict int_mergeUpdates:@{
      kINTTransformerBlockExamplesArgumentsSequence: @[
        INTEventTransformerArgs(appWillForegroundEvent, INTCreateEventMetadata()),
        INTEventTransformerArgs(appBecameActiveEvent, INTCreateEventMetadata(2))
      ],
      kINTTransformerBlockExamplesExpectedEvents: @[expectedEvent]
    }];
  });

  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto pushNotificationEvent = [[INTPushNotificationOpenedEvent alloc]
                                  initWithPushID:@"foo" deepLink:nil pushSource:@"bar"];

    auto expectedEvent = [[INTAnalytricksAppForegrounded alloc]
                         initWithSource:@"push_notification" isLaunch:YES].properties;

    return [sharedExampleDict int_mergeUpdates:@{
      kINTTransformerBlockExamplesArgumentsSequence: @[
        INTEventTransformerArgs(appWillForegroundEvent, INTCreateEventMetadata()),
        INTEventTransformerArgs(pushNotificationEvent, INTCreateEventMetadata(1)),
        INTEventTransformerArgs(appBecameActiveEvent, INTCreateEventMetadata(2))
      ],
      kINTTransformerBlockExamplesExpectedEvents: @[expectedEvent]
    }];
  });

  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto deepLinkEvent = [[INTDeepLinkOpenedEvent alloc] initWithDeepLink:@"foo://bar.com"];

    auto expectedEvent = [[INTAnalytricksAppForegrounded alloc]
                         initWithSource:@"deep_link" isLaunch:YES].properties;

    return [sharedExampleDict int_mergeUpdates:@{
      kINTTransformerBlockExamplesArgumentsSequence: @[
        INTEventTransformerArgs(appWillForegroundEvent, INTCreateEventMetadata()),
        INTEventTransformerArgs(deepLinkEvent, INTCreateEventMetadata(1)),
        INTEventTransformerArgs(appBecameActiveEvent, INTCreateEventMetadata(2))
      ],
      kINTTransformerBlockExamplesExpectedEvents: @[expectedEvent]
    }];
  });
});

context(@"analytricks foreground event transformer", ^{
  __block INTAppWillEnterForegroundEvent *appWillForegroundEvent;
  __block INTAppBackgroundedEvent *appBackgroundedEvent;
  __block NSDictionary *sharedExampleDict;

  beforeEach(^{
    appWillForegroundEvent = [[INTAppWillEnterForegroundEvent alloc] initWithIsLaunch:YES];
    appBackgroundedEvent = [[INTAppBackgroundedEvent alloc] init];
    auto block = [INTAnalytricksTransformerBlocks backgroundEventTransformer];
    sharedExampleDict = @{kINTTransformerBlockExamplesTransformerBlock: block};
  });

  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto events = @[
      [[INTAnalytricksAppBackgrounded alloc] initWithForegroundDuration:@2].properties,
      [[INTAnalytricksAppBackgrounded alloc] initWithForegroundDuration:@83].properties
    ];
    NSMutableDictionary *exampleData = [sharedExampleDict mutableCopy];
    [exampleData addEntriesFromDictionary:@{
      kINTTransformerBlockExamplesArgumentsSequence: @[
        INTEventTransformerArgs(appWillForegroundEvent, INTCreateEventMetadata()),
        INTEventTransformerArgs(appBackgroundedEvent, INTCreateEventMetadata(2)),
        INTEventTransformerArgs(appBackgroundedEvent, INTCreateEventMetadata(5)),
        INTEventTransformerArgs(appWillForegroundEvent, INTCreateEventMetadata(7)),
        INTEventTransformerArgs(appBackgroundedEvent, INTCreateEventMetadata(90))
      ],
      kINTTransformerBlockExamplesExpectedEvents: events
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
    auto block = [INTAnalytricksTransformerBlocks screenVisitedEventTransformer];
    sharedExampleDict = @{
      kINTTransformerBlockExamplesTransformerBlock: block
    };
  });

  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksScreenVisited alloc]
       initWithScreenDuration:@2 dismissAction:@"baz"].properties,
      [[INTAnalytricksScreenVisited alloc]
       initWithScreenDuration:@43 dismissAction:@"baz"].properties
    ];
    NSMutableDictionary *exampleData = [sharedExampleDict mutableCopy];
    [exampleData addEntriesFromDictionary:@{
      kINTTransformerBlockExamplesArgumentsSequence: @[
        INTEventTransformerArgs(screenDisplayedEvent, INTCreateEventMetadata()),
        INTEventTransformerArgs(screenDismissedEvent, INTCreateEventMetadata(2)),
        INTEventTransformerArgs(screenDismissedEvent, INTCreateEventMetadata(6)),
        INTEventTransformerArgs(screenDisplayedEvent, INTCreateEventMetadata(7)),
        INTEventTransformerArgs(screenDismissedEvent, INTCreateEventMetadata(50))
      ],
      kINTTransformerBlockExamplesExpectedEvents: dataProviders
    }];

    return [exampleData copy];
  });
});

context(@"analytricks deep link opened event transformer", ^{
  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksDeepLinkOpened alloc] initWithDeepLink:@"http://foo.bar"].properties,
      [[INTAnalytricksDeepLinkOpened alloc] initWithDeepLink:@"http://baz.foo"].properties
    ];

    return @{
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     deepLinkOpenedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: @[
        INTEventTransformerArgs([[INTDeepLinkOpenedEvent alloc] initWithDeepLink:@"http://foo.bar"],
                                INTCreateEventMetadata()),
        INTEventTransformerArgs([[INTDeepLinkOpenedEvent alloc] initWithDeepLink:@"http://baz.foo"],
                                INTCreateEventMetadata()),
      ],
      kINTTransformerBlockExamplesExpectedEvents: dataProviders
    };
  });
});

context(@"analytricks push notification received event transformer", ^{
  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksPushNotificationOpened alloc]
       initWithPushID:@"foo" deepLink:nil pushSource:@"Local"].properties,
      [[INTAnalytricksPushNotificationOpened alloc]
       initWithPushID:@"bar" deepLink:@"http://foo" pushSource:@"Remote"].properties
    ];

    return @{
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                 pushNotificationOpenedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: @[
        INTEventTransformerArgs([[INTPushNotificationOpenedEvent alloc]
                                 initWithPushID:@"foo" deepLink:nil pushSource:@"Local"],
                                INTCreateEventMetadata()),
        INTEventTransformerArgs([[INTPushNotificationOpenedEvent alloc]
                                 initWithPushID:@"bar" deepLink:@"http://foo" pushSource:@"Remote"],
                                INTCreateEventMetadata()),
      ],
      kINTTransformerBlockExamplesExpectedEvents: dataProviders
    };
  });
});

context(@"analytricks media imported event transformer", ^{
  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksMediaImported alloc]
       initWithAssetType:@"image" format:@"png" assetWidth:345 assetHeight:32 assetDuration:nil
       importSource:@"Camera Roll" assetID:@"foo.bar.baz" isFromBundle:@YES].properties,
      [[INTAnalytricksMediaImported alloc]
       initWithAssetType:@"video" format:@"mp4" assetWidth:345 assetHeight:24 assetDuration:@3
       importSource:@"Camera Roll" assetID:@"foo.bar.baz.thud" isFromBundle:@NO].properties,
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
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     mediaImportedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: args,
      kINTTransformerBlockExamplesExpectedEvents: dataProviders
    };
  });
});

context(@"analytricks media imported event transformer", ^{
  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto dataProviders = @[
      [[INTAnalytricksMediaImported alloc]
       initWithAssetType:@"image" format:@"png" assetWidth:345 assetHeight:32 assetDuration:nil
       importSource:@"Camera Roll" assetID:@"foo.bar.baz" isFromBundle:@YES].properties,
      [[INTAnalytricksMediaImported alloc]
       initWithAssetType:@"video" format:@"mp4" assetWidth:345 assetHeight:24 assetDuration:@3
       importSource:@"Camera Roll" assetID:@"foo.bar.baz.thud" isFromBundle:@NO].properties,
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
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     mediaImportedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: args,
      kINTTransformerBlockExamplesExpectedEvents: dataProviders
    };
  });
});

context(@"analytricks media exported event transformer", ^{
  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto exportID1 = [NSUUID UUID];
    auto exportID2 = [NSUUID UUID];
    auto projectID = [NSUUID UUID];
    auto dataProviders = @[
      [[INTAnalytricksMediaExported alloc]
       initWithExportID:exportID1 assetType:@"image" format:@"png" assetWidth:234 assetHeight:443
       assetDuration:@34 exportTarget:@"Facebook" assetID:@"foo.bar" projectID:projectID
       isSuccessful:YES].properties,
      [[INTAnalytricksMediaExported alloc]
       initWithExportID:exportID1 assetType:@"image" format:@"png" assetWidth:234 assetHeight:44
       assetDuration:@34 exportTarget:@"Facebook" assetID:@"foo.bar1" projectID:projectID
       isSuccessful:YES].properties,
      [[INTAnalytricksMediaExported alloc]
       initWithExportID:exportID2 assetType:@"video" format:@"mp4" assetWidth:234 assetHeight:443
       assetDuration:@34 exportTarget:@"Camera Roll" assetID:@"foo.bar" projectID:projectID
       isSuccessful:NO].properties
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
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     mediaExportedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: args,
      kINTTransformerBlockExamplesExpectedEvents: dataProviders
    };
  });

  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
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
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                 mediaExportedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: args,
      kINTTransformerBlockExamplesExpectedEvents: @[]
    };
  });
});

context(@"analytricks project deleted event transformer", ^{
  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto projectID1 = [NSUUID UUID];
    auto projectID2 = [NSUUID UUID];

    auto args = [@[
      [[INTProjectDeletedEvent alloc] initWithProjectID:projectID1],
      [[INTProjectDeletedEvent alloc] initWithProjectID:projectID2]
    ] lt_map:^(INTMediaImportedEvent *event) {
      return INTEventTransformerArgs(event, INTCreateEventMetadata());
    }];

    auto expectedEvents = @[
      [[INTAnalytricksProjectDeleted alloc] initWithProjectID:projectID1].properties,
      [[INTAnalytricksProjectDeleted alloc] initWithProjectID:projectID2].properties,
    ];

    return @{
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     projectDeletedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: args,
      kINTTransformerBlockExamplesExpectedEvents: expectedEvents
    };
  });
});

context(@"analytricks project modified event transformer", ^{
  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto projectID = [NSUUID UUID];

    auto args = @[
      INTEventTransformerArgs([[INTProjectLoadedEvent alloc] initWithProjectID:projectID isNew:YES],
                              INTCreateEventMetadata()),
      INTEventTransformerArgs([[INTProjectUnloadedEvent alloc]
                               initWithProjectID:projectID diskSpaceOnUnload:@23],
                              INTCreateEventMetadata(4)),
      INTEventTransformerArgs([[INTProjectUnloadedEvent alloc]
                               initWithProjectID:projectID diskSpaceOnUnload:@23],
                              INTCreateEventMetadata(4)),
    ];

    auto expectedEvents = @[
     [[INTAnalytricksProjectModified alloc] initWithProjectID:projectID isNew:YES usageDuration:@4
                                            diskSpaceOnUnload:@23 wasDeleted:NO].properties,
    ];

    return @{
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     projectModifiedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: args,
      kINTTransformerBlockExamplesExpectedEvents: expectedEvents
    };
  });

  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto projectID = [NSUUID UUID];

    auto args = @[
      INTEventTransformerArgs([[INTProjectLoadedEvent alloc] initWithProjectID:projectID isNew:NO],
                              INTCreateEventMetadata()),
      INTEventTransformerArgs([[INTProjectDeletedEvent alloc] initWithProjectID:projectID],
                              INTCreateEventMetadata(1)),
      INTEventTransformerArgs([[INTProjectUnloadedEvent alloc]
                               initWithProjectID:projectID diskSpaceOnUnload:@23],
                              INTCreateEventMetadata(4)),
    ];

    auto expectedEvents = @[
      [[INTAnalytricksProjectModified alloc] initWithProjectID:projectID isNew:NO usageDuration:@4
                                             diskSpaceOnUnload:@23 wasDeleted:YES].properties,
    ];

    return @{
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     projectModifiedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: args,
      kINTTransformerBlockExamplesExpectedEvents: expectedEvents
    };
  });

  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto projectID = [NSUUID UUID];

    auto args = @[
      INTEventTransformerArgs([[INTProjectLoadedEvent alloc] initWithProjectID:projectID isNew:NO],
                              INTCreateEventMetadata()),
      INTEventTransformerArgs([[INTProjectDeletedEvent alloc] initWithProjectID:projectID],
                              INTCreateEventMetadata(1)),
      INTEventTransformerArgs([[INTProjectUnloadedEvent alloc]
                               initWithProjectID:projectID diskSpaceOnUnload:@23],
                              INTCreateEventMetadata(4)),
    ];

    auto expectedEvents = @[
      [[INTAnalytricksProjectModified alloc] initWithProjectID:projectID isNew:NO usageDuration:@4
                                             diskSpaceOnUnload:@23 wasDeleted:YES].properties,
    ];

    return @{
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     projectModifiedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: args,
      kINTTransformerBlockExamplesExpectedEvents: expectedEvents
    };
  });
});

context(@"analytricks device info changed event transformer", ^{
  __block INTDeviceInfo *deviceInfo;

  beforeEach(^{
    deviceInfo =
        [[INTDeviceInfo alloc]
         initWithIdentifierForVendor:[NSUUID UUID] advertisingID:[NSUUID UUID]
         advertisingTrackingEnabled:YES deviceKind:@"fooBar" iosVersion:@"10.2" appVersion:@"1"
         appVersionShort:@"1.2" timeZone:@"foo" country:@"bar" preferredLanguage:@"barFoo"
         currentAppLanguage:@"que"
         purchaseReceipt:[[NSData alloc] initWithBase64EncodedString:@"thud" options:0]
         appStoreCountry:@"bar" inLowPowerMode:@YES firmwareID:@"baz" usageEventsDisabled:@YES];
  });

  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto deviceInfoLoadedEvent =
        [[INTDeviceInfoLoadedEvent alloc] initWithDeviceInfo:deviceInfo
                                        deviceInfoRevisionID:[NSUUID UUID] isNewRevision:YES];

    auto expectedEvent =
        [[INTAnalytricksDeviceInfoChanged alloc]
         initWithIdForVendor:deviceInfo.identifierForVendor advertisingID:deviceInfo.advertisingID
         isAdvertisingTrackingEnabled:YES deviceKind:@"fooBar" iosVersion:@"10.2" appVersion:@"1"
         appVersionShort:@"1.2" timezone:@"foo" country:@"bar" preferredLanguage:@"barFoo"
         currentAppLanguage:@"que" purchaseReceipt:@"thud" appStoreCountry:@"bar"
         inLowPowerMode:@YES firmwareID:@"baz" usageEventsDisabled:@YES].properties;

    return @{
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     deviceInfoChangedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: @[
        INTEventTransformerArgs(deviceInfoLoadedEvent, INTCreateEventMetadata())
      ],
      kINTTransformerBlockExamplesExpectedEvents: @[expectedEvent]
    };
  });

  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto deviceInfoLoadedEvent =
        [[INTDeviceInfoLoadedEvent alloc] initWithDeviceInfo:deviceInfo
                                        deviceInfoRevisionID:[NSUUID UUID] isNewRevision:NO];

    return @{
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     deviceInfoChangedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: @[
        INTEventTransformerArgs(deviceInfoLoadedEvent, INTCreateEventMetadata())
      ],
      kINTTransformerBlockExamplesExpectedEvents: @[]
    };
  });
});

context(@"analytricks device token change event transformer", ^{
  itShouldBehaveLike(kINTTransformerBlockExamples, ^{
    auto args = [@[
      [[INTDeviceTokenChangedEvent alloc] initWithDeviceToken:@"foo"],
      [[INTDeviceTokenChangedEvent alloc] initWithDeviceToken:nil]
    ] lt_map:^(INTMediaImportedEvent *event) {
      return INTEventTransformerArgs(event, INTCreateEventMetadata());
    }];

    auto expectedEvents = @[
      [[INTAnalytricksDeviceTokenChanged alloc] initWithDeviceToken:@"foo"].properties,
      [[INTAnalytricksDeviceTokenChanged alloc] initWithDeviceToken:nil].properties,
    ];

    return @{
      kINTTransformerBlockExamplesTransformerBlock: [INTAnalytricksTransformerBlocks
                                                     deviceTokenChangedEventTransformer],
      kINTTransformerBlockExamplesArgumentsSequence: args,
      kINTTransformerBlockExamplesExpectedEvents: expectedEvents
    };
  });
});

SpecEnd
