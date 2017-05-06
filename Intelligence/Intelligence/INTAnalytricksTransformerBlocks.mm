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
#import "INTAnalytricksMetadata.h"
#import "INTAnalytricksScreenVisited.h"
#import "INTAppBackgroundedEvent.h"
#import "INTAppBecameActiveEvent.h"
#import "INTAppWillEnterForegroundEvent.h"
#import "INTCycleTransformerBlockBuilder.h"
#import "INTDeepLinkOpenedEvent.h"
#import "INTEventMetadata.h"
#import "INTPushNotificationOpenedEvent.h"
#import "INTScreenDismissedEvent.h"
#import "INTScreenDisplayedEvent.h"

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

@end

NS_ASSUME_NONNULL_END
