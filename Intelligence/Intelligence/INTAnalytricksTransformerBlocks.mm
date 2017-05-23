// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksTransformerBlocks.h"

#import <LTKit/LTKeyPathCoding.h>
#import <LTKit/NSArray+Functional.h>

#import "INTAnalytricksAppBackgrounded.h"
#import "INTAnalytricksAppForegrounded.h"
#import "INTAnalytricksBaseUsage.h"
#import "INTAnalytricksContext.h"
#import "INTAnalytricksContextGenerators.h"
#import "INTAnalytricksDeepLinkOpened.h"
#import "INTAnalytricksMediaExported.h"
#import "INTAnalytricksMediaImported.h"
#import "INTAnalytricksMetadata.h"
#import "INTAnalytricksPushNotificationOpened.h"
#import "INTAnalytricksScreenVisited.h"
#import "INTAppBackgroundedEvent.h"
#import "INTAppBecameActiveEvent.h"
#import "INTAppWillEnterForegroundEvent.h"
#import "INTCycleTransformerBlockBuilder.h"
#import "INTDeepLinkOpenedEvent.h"
#import "INTEventMetadata.h"
#import "INTMediaExportEndedEvent.h"
#import "INTMediaExportStartedEvent.h"
#import "INTMediaImportedEvent.h"
#import "INTPushNotificationOpenedEvent.h"
#import "INTScreenDismissedEvent.h"
#import "INTScreenDisplayedEvent.h"
#import "INTTransformerBlockBuilder.h"
#import "NSDictionary+Merge.h"

NS_ASSUME_NONNULL_BEGIN

@implementation INTAnalytricksTransformerBlocks

+ (INTEventEnrichmentBlock)analytricksContextEnrichementBlock {
  return ^(NSArray *events, INTAppContext *appContext,
                                              INTEventMetadata *) {
    NSDictionary *analytricksContext =
        [appContext[kINTAppContextAnalytricksContextKey] properties] ?: @{};

    return [events lt_map:^(NSDictionary *event) {
      if (![event isKindOfClass:NSDictionary.class]) {
        return event;
      }

      return [analytricksContext int_dictionaryByAddingEntriesFromDictionary:event];
    }];
  };
}

+ (INTEventEnrichmentBlock)analytricksMetadataEnrichementBlock {
  return ^(NSArray *events, INTAppContext *appContext, INTEventMetadata *eventMetadata) {
    NSUUID * _Nullable ltDeviceID = appContext[kINTAppContextDeviceIDKey];
    NSUUID * _Nullable deviceInfoID = appContext[kINTAppContextDeviceInfoIDKey];

    NSDictionary *analytricksMetadata;

    if (!ltDeviceID || !deviceInfoID) {
      analytricksMetadata = @{};
    } else {
      analytricksMetadata = [[INTAnalytricksMetadata alloc]
         initWithEventID:eventMetadata.eventID deviceTimestamp:eventMetadata.deviceTimestamp
         appTotalRunTime:@(eventMetadata.totalRunTime) ltDeviceID:ltDeviceID
         deviceInfoID:deviceInfoID].properties;
    }

    return [events lt_map:^(NSDictionary *event) {
      if (![event isKindOfClass:NSDictionary.class]) {
        return event;
      }

      return [analytricksMetadata int_dictionaryByAddingEntriesFromDictionary:event];
    }];
  };
}

+ (INTTransformerBlock)foregroundEventTransformer {
  return INTCycleTransformerBuilder()
      .cycle(NSStringFromClass(INTAppWillEnterForegroundEvent.class),
             NSStringFromClass(INTAppBecameActiveEvent.class))
      .aggregate(NSStringFromClass(INTAppWillEnterForegroundEvent.class),
                 ^(NSDictionary<NSString *, id> *, INTAppWillEnterForegroundEvent *event) {
        return @{
          @instanceKeypath(INTAnalytricksAppForegrounded, isLaunch): @(event.isLaunch),
          @instanceKeypath(INTAnalytricksAppForegrounded, source): @"app_launcher"
        };
      })
      .aggregate(NSStringFromClass(INTDeepLinkOpenedEvent.class),
                 ^(NSDictionary<NSString *, id> *, id) {
        return @{@instanceKeypath(INTAnalytricksAppForegrounded, source): @"deep_link"};
      })
      .aggregate(NSStringFromClass(INTPushNotificationOpenedEvent.class),
                 ^(NSDictionary<NSString *, id> *, id) {
        return @{@instanceKeypath(INTAnalytricksAppForegrounded, source): @"push_notification"};
      })
      .onCycleEnd(^(NSDictionary<NSString *, id> *aggregatedData) {
        BOOL isLaunch =
            [aggregatedData[@instanceKeypath(INTAnalytricksAppForegrounded, isLaunch)] boolValue];
        NSString *source =
            aggregatedData[@instanceKeypath(INTAnalytricksAppForegrounded, source)];

        return @[[[INTAnalytricksAppForegrounded alloc] initWithSource:source
                                                              isLaunch:isLaunch].properties];
      })
      .build();
}

+ (INTTransformerBlock)backgroundEventTransformer {
  return INTCycleTransformerBuilder()
      .cycle(NSStringFromClass(INTAppWillEnterForegroundEvent.class),
             NSStringFromClass(INTAppBackgroundedEvent.class))
      .onCycleEnd(^(NSDictionary<NSString *, id> *aggregatedData) {
        return @[[[INTAnalytricksAppBackgrounded alloc]
                  initWithForegroundDuration:aggregatedData[kINTCycleDurationKey]].properties];
      })
      .build();
}

+ (INTTransformerBlock)screenVisitedEventTransformer {
  return INTCycleTransformerBuilder()
      .cycle(NSStringFromClass(INTScreenDisplayedEvent.class),
             NSStringFromClass(INTScreenDismissedEvent.class))
      .aggregate(NSStringFromClass(INTScreenDismissedEvent.class),
                 ^(NSDictionary<NSString *, id> *, INTScreenDismissedEvent *event) {
        return @{
          @instanceKeypath(INTAnalytricksScreenVisited, dismissAction):
               event.dismissAction ?: [NSNull null]
        };
      })
      .onCycleEnd(^(NSDictionary<NSString *, id> *aggregatedData) {
        NSString *dismissAction =
            aggregatedData[@instanceKeypath(INTAnalytricksScreenVisited, dismissAction)];

        return @[[[INTAnalytricksScreenVisited alloc]
                  initWithScreenDuration:aggregatedData[kINTCycleDurationKey]
                  dismissAction:dismissAction].properties];
      })
      .build();
}

+ (INTTransformerBlock)deepLinkOpenedEventTransformer {
  return INTTransformerBuilder()
      .transform(NSStringFromClass(INTDeepLinkOpenedEvent.class),
                 ^(NSDictionary<NSString *, id> *, INTDeepLinkOpenedEvent *event,
                   INTEventMetadata *, INTAppContext *) {
        return @[[[INTAnalytricksDeepLinkOpened alloc] initWithDeepLink:event.deepLink].properties];
      })
      .build();
}

+ (INTTransformerBlock)pushNotificationOpenedEventTransformer {
  return INTTransformerBuilder()
      .transform(NSStringFromClass(INTPushNotificationOpenedEvent.class),
                 ^(NSDictionary<NSString *, id> *, INTPushNotificationOpenedEvent *event,
                   INTEventMetadata *, INTAppContext *) {
        return @[[[INTAnalytricksPushNotificationOpened alloc]
                  initWithPushID:event.pushID deepLink:event.deepLink].properties];
      })
      .build();
}

+ (INTTransformerBlock)mediaImportedEventTransformer {
  return INTTransformerBuilder()
      .transform(NSStringFromClass(INTMediaImportedEvent.class),
                 ^(NSDictionary<NSString *, id> *, INTMediaImportedEvent *event, INTEventMetadata *,
                   INTAppContext *) {
        return @[[[INTAnalytricksMediaImported alloc]
                  initWithAssetType:event.assetType format:event.format
                  assetWidth:event.assetWidth assetHeight:event.assetHeight
                  assetDuration:event.assetDuration importSource:event.importSource
                  assetID:event.assetID isFromBundle:event.isFromBundle].properties];
      })
      .build();
}

+ (INTTransformerBlock)mediaExportedEventTransformer {
  static NSString * const kOngoingExportsKey = @"_ongoingExports";
  static NSString * const kFinishedExportKey = @"_finishedExport";

  return INTTransformerBuilder()
      .aggregate(NSStringFromClass(INTMediaExportStartedEvent.class),
                 ^(NSDictionary<NSString *, id> *aggregatedData,
                   INTMediaExportStartedEvent *event) {
        NSDictionary *ongoingExportsMap = aggregatedData[kOngoingExportsKey] ?:
            [NSDictionary dictionary];
        NSMutableArray *ongoingExports = [ongoingExportsMap[event.exportID] mutableCopy] ?:
            [NSMutableArray array];
        [ongoingExports addObject:event];

        return @{kOngoingExportsKey:
                   [ongoingExportsMap int_mergeUpdates:@{event.exportID: ongoingExports}]};
      })
      .aggregate(NSStringFromClass(INTMediaExportEndedEvent.class),
                 ^(NSDictionary<NSString *, id> *aggregatedData,
                   INTMediaExportStartedEvent *event) {
        NSDictionary *ongoingExports = aggregatedData[kOngoingExportsKey] ?:
            [NSDictionary dictionary];

        return @{
          kOngoingExportsKey: [ongoingExports int_mergeUpdates:@{
            event.exportID: [NSNull null]
          }],
          kFinishedExportKey: ongoingExports[event.exportID] ?: [NSNull null]
        };
      })
      .transform(NSStringFromClass(INTMediaExportEndedEvent.class),
                 ^(NSDictionary<NSString *, id> *aggregatedData, INTMediaExportEndedEvent *event,
        INTEventMetadata *, INTAppContext *) {
        NSArray<INTMediaExportStartedEvent *> *exportStarted =
            aggregatedData[kFinishedExportKey] ?: @[];

        return [exportStarted lt_map:^(INTMediaExportStartedEvent *exportStarted) {
          return [[INTAnalytricksMediaExported alloc]
                  initWithExportID:event.exportID assetType:exportStarted.assetType
                  format:exportStarted.format assetWidth:exportStarted.assetWidth
                  assetHeight:exportStarted.assetHeight assetDuration:exportStarted.assetDuration
                  exportTarget:exportStarted.exportTarget assetID:exportStarted.assetID
                  projectID:exportStarted.projectID isSuccessful:event.isSuccessful].properties;
        }];
      })
      .build();
}

@end

NS_ASSUME_NONNULL_END
