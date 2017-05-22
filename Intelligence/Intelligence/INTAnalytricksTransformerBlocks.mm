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

INTTransformCompletionBlock
    INTAnalytricksBaseUsageTransformCompletion(intl::TransformCompletionBlock providerCompletion,
                                               BOOL useStartMetadata = NO,
                                               BOOL useStartContext = NO) {
  return ^(NSDictionary<NSString *, id> *aggregatedData, id event, INTEventMetadata *metadata,
           INTAppContext *context) {
    auto providers = providerCompletion.getFullBlock()(aggregatedData, event, metadata, context);
    auto providerIndices = [providers indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger,
                                                                        BOOL *) {
      return [obj conformsToProtocol:@protocol(INTAnalytricksBaseUsageDataProvider)];
    }];

    providers = [providers objectsAtIndexes:providerIndices];

    INTAppContext *appContext =
        useStartContext ? aggregatedData[kINTStartContextKey] : context;

    INTAnalytricksContext * _Nullable analytricksContext =
        appContext[kINTAppContextAnalytricksContextKey];

    NSUUID * _Nullable ltDeviceID = appContext[kINTAppContextDeviceIDKey];
    NSUUID * _Nullable deviceInfoID = appContext[kINTAppContextDeviceInfoIDKey];

    if (!(analytricksContext && ltDeviceID && deviceInfoID)) {
      return @[];
    }

    INTEventMetadata *eventMetadata =
        useStartMetadata ? aggregatedData[kINTStartMetadataKey] : metadata;

    auto analytricksMetadata =
        [[INTAnalytricksMetadata alloc]
         initWithEventID:eventMetadata.eventID deviceTimestamp:eventMetadata.deviceTimestamp
         appTotalRunTime:@(eventMetadata.totalRunTime) ltDeviceID:ltDeviceID
         deviceInfoID:deviceInfoID];

    return [providers lt_map:^(id<INTAnalytricksBaseUsageDataProvider> provider) {
      return [[INTAnalytricksBaseUsage alloc] initWithDataProvider:provider
                                             INTAnalytricksContext:analytricksContext
                                            INTAnalytricksMetadata:analytricksMetadata];
    }];
  };
}

@implementation INTAnalytricksBaseUsageTransformerBlocks

+ (INTTransformerBlock)foregroundEventTransformer {
  INTAggregationTransformCompletionBlock providerCompletion =
      ^(NSDictionary<NSString *, id> *aggregatedData) {
        BOOL isLaunch =
            [aggregatedData[@instanceKeypath(INTAnalytricksAppForegrounded, isLaunch)] boolValue];
        NSString *source =
            aggregatedData[@instanceKeypath(INTAnalytricksAppForegrounded, source)];

        return @[[[INTAnalytricksAppForegrounded alloc] initWithSource:source isLaunch:isLaunch]];
      };

  auto completionBlock = INTAnalytricksBaseUsageTransformCompletion(providerCompletion, YES, YES);

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
      .onCycleEnd(completionBlock)
      .build();
}

+ (INTTransformerBlock)backgroundEventTransformer {
  INTAggregationTransformCompletionBlock providerCompletion =
      ^(NSDictionary<NSString *, id> *aggregatedData) {
        return @[[[INTAnalytricksAppBackgrounded alloc]
                  initWithForegroundDuration:aggregatedData[kINTCycleDurationKey]]];
      };

  auto completionBlock = INTAnalytricksBaseUsageTransformCompletion(providerCompletion);

  return INTCycleTransformerBuilder()
      .cycle(NSStringFromClass(INTAppWillEnterForegroundEvent.class),
             NSStringFromClass(INTAppBackgroundedEvent.class))
      .onCycleEnd(completionBlock)
      .build();
}

+ (INTTransformerBlock)screenVisitedEventTransformer {
  INTAggregationTransformCompletionBlock providerCompletion =
      ^(NSDictionary<NSString *, id> *aggregatedData) {
        NSString *dismissAction =
        aggregatedData[@instanceKeypath(INTAnalytricksScreenVisited, dismissAction)];

        return @[[[INTAnalytricksScreenVisited alloc]
                  initWithScreenDuration:aggregatedData[kINTCycleDurationKey]
                  dismissAction:dismissAction]];
      };

  auto completionBlock = INTAnalytricksBaseUsageTransformCompletion(providerCompletion);

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
      .onCycleEnd(completionBlock)
      .build();
}

+ (INTTransformerBlock)deepLinkOpenedEventTransformer {
  INTTransformCompletionBlock providerCompletion =
      ^(NSDictionary<NSString *, id> *, INTDeepLinkOpenedEvent *event, INTEventMetadata *,
        INTAppContext *) {
          return @[[[INTAnalytricksDeepLinkOpened alloc] initWithDeepLink:event.deepLink]];
      };

  auto completionBlock = INTAnalytricksBaseUsageTransformCompletion(providerCompletion);

  return INTTransformerBuilder()
      .transform(NSStringFromClass(INTDeepLinkOpenedEvent.class), completionBlock)
      .build();
}

+ (INTTransformerBlock)pushNotificationOpenedEventTransformer {
  INTTransformCompletionBlock providerCompletion =
      ^(NSDictionary<NSString *, id> *, INTPushNotificationOpenedEvent *event, INTEventMetadata *,
        INTAppContext *) {
          return @[[[INTAnalytricksPushNotificationOpened alloc]
                    initWithPushID:event.pushID deepLink:event.deepLink]];
      };

  auto completionBlock = INTAnalytricksBaseUsageTransformCompletion(providerCompletion);

  return INTTransformerBuilder()
      .transform(NSStringFromClass(INTPushNotificationOpenedEvent.class), completionBlock)
      .build();
}

+ (INTTransformerBlock)mediaImportedEventTransformer {
  INTTransformCompletionBlock providerCompletion =
      ^(NSDictionary<NSString *, id> *, INTMediaImportedEvent *event, INTEventMetadata *,
        INTAppContext *) {
          return @[[[INTAnalytricksMediaImported alloc]
                    initWithAssetType:event.assetType format:event.format
                    assetWidth:event.assetWidth assetHeight:event.assetHeight
                    assetDuration:event.assetDuration importSource:event.importSource
                    assetID:event.assetID isFromBundle:event.isFromBundle]];
      };

  auto completionBlock = INTAnalytricksBaseUsageTransformCompletion(providerCompletion);

  return INTTransformerBuilder()
      .transform(NSStringFromClass(INTMediaImportedEvent.class), completionBlock)
      .build();
}

+ (INTTransformerBlock)mediaExportedEventTransformer {
  static NSString * const kOngoingExportsKey = @"_ongoingExports";
  static NSString * const kFinishedExportKey = @"_finishedExport";

  INTTransformCompletionBlock providerCompletion =
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
                  projectID:exportStarted.projectID isSuccessful:event.isSuccessful];
        }];
      };

  auto completionBlock = INTAnalytricksBaseUsageTransformCompletion(providerCompletion);

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
      .transform(NSStringFromClass(INTMediaExportEndedEvent.class), completionBlock)
      .build();
}

@end

NS_ASSUME_NONNULL_END
