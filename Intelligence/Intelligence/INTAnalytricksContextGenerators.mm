// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksContextGenerators.h"

#import <LTKit/LTKeyPathCoding.h>

#import "INTAnalytricksContext+Merge.h"
#import "INTAppRunCountUpdatedEvent.h"
#import "INTAppWillEnterForegroundEvent.h"
#import "INTDeviceInfo.h"
#import "INTDeviceInfoLoadedEvent.h"
#import "INTProjectLoadedEvent.h"
#import "INTProjectUnloadedEvent.h"
#import "INTScreenDisplayedEvent.h"
#import "INTTransformerBlockBuilder.h"
#import "NSDictionary+Merge.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kINTAppContextAnalytricksContextKey = @"_INTAnalytricksContext";
NSString * const kINTAppContextDeviceIDKey = @"_INTDeviceID";
NSString * const kINTAppContextDeviceInfoIDKey = @"_INTDeviceInfoID";
NSString * const kINTAppContextAppRunCountKey = @"_INTAppRunCount";

/// Block that inspects \c event and returns the updates that should be commited to the analytrics
/// context in a context aggregation process. The block must be a pure function without side
/// effects. Key having \c NSNull means that the property should be set to \c nil.
typedef NSDictionary<NSString *, id> *(^INTAnalytricksContextUpdates)(id event);

INTAggregationBlock INTAnalytricksContextAggregation(INTAnalytricksContextUpdates updatesBlock) {
  return ^(NSDictionary<NSString *, id> *, id event, INTEventMetadata *, INTAppContext *context) {
    auto updates = updatesBlock(event);

    if (!updates.count) {
      return @{};
    }

    INTAnalytricksContext *analytricksContext = nn(context[kINTAppContextAnalytricksContextKey]);
    return @{kINTAppContextAnalytricksContextKey: [analytricksContext merge:updates]};
  };
}

@implementation INTAnalytricksContextGenerators

+ (INTAppContextGeneratorBlock)analytricksContextGenerator {
  auto foregroundAggregation = ^(INTAppWillEnterForegroundEvent *) {
    return @{@instanceKeypath(INTAnalytricksContext, sessionID): [NSUUID UUID]};
  };

  auto screenDisplayAggregation = ^(INTScreenDisplayedEvent *event) {
    return @{
      @instanceKeypath(INTAnalytricksContext, screenUsageID): [NSUUID UUID],
      @instanceKeypath(INTAnalytricksContext, screenName): event.screenName
    };
  };

  auto projectLoadAggregation = ^(INTProjectLoadedEvent *event) {
    return @{@instanceKeypath(INTAnalytricksContext, openProjectID): event.projectID};
  };

  auto projectCloseAggregation = ^(INTProjectUnloadedEvent *) {
    return @{@instanceKeypath(INTAnalytricksContext, openProjectID): [NSNull null]};
  };

  INTTransformerBlock transformer = INTTransformerBuilder()
      .aggregate(NSStringFromClass(INTAppWillEnterForegroundEvent.class),
                 INTAnalytricksContextAggregation(foregroundAggregation))
      .aggregate(NSStringFromClass(INTScreenDisplayedEvent.class),
                 INTAnalytricksContextAggregation(screenDisplayAggregation))
      .aggregate(NSStringFromClass(INTProjectLoadedEvent.class),
                 INTAnalytricksContextAggregation(projectLoadAggregation))
      .aggregate(NSStringFromClass(INTProjectUnloadedEvent.class),
                 INTAnalytricksContextAggregation(projectCloseAggregation))
      .build();

  INTAppContextGeneratorBlock analytricksContextInitializer =
      ^(INTAppContext *context, INTEventMetadata *, id) {
        if (!context[kINTAppContextAnalytricksContextKey]) {
          auto *analytricksContext =
              [[INTAnalytricksContext alloc]
               initWithRunID:[NSUUID UUID] sessionID:nil screenUsageID:nil screenName:nil
               openProjectID:nil];

          return (INTAppContext *)[context int_mergeUpdates:@{
            kINTAppContextAnalytricksContextKey: analytricksContext
          }];
        }

        return context;
      };

  INTAppContextGeneratorBlock analytricksContextUpdater =
      ^(INTAppContext *context, INTEventMetadata *eventMetadata, id event) {
        auto contextUpdates = transformer(@{}, context, eventMetadata, event).aggregatedData;
        return [context int_mergeUpdates:contextUpdates];
      };

  return INTComposeAppContextGenerators(@[
    analytricksContextInitializer,
    analytricksContextUpdater
  ]);
}

+ (INTAppContextGeneratorBlock)deviceInfoContextGenerator {
  return ^(INTAppContext *context, INTEventMetadata *, INTDeviceInfoLoadedEvent *event) {
    if (![event isKindOfClass:INTDeviceInfoLoadedEvent.class]) {
      return context;
    }

    auto contextUpdates = @{
      kINTAppContextDeviceIDKey: event.deviceInfo.identifierForVendor,
      kINTAppContextDeviceInfoIDKey: event.deviceInfoRevisionID
    };
    return (INTAppContext *)[context int_mergeUpdates:contextUpdates];
  };
}

+ (INTAppContextGeneratorBlock)appRunCountContextGenerator {
  return ^(INTAppContext *context, INTEventMetadata *, INTAppRunCountUpdatedEvent *event) {
    if (![event isKindOfClass:INTAppRunCountUpdatedEvent.class]) {
      return context;
    }

    auto contextUpdates = @{kINTAppContextAppRunCountKey: event.runCount};
    return (INTAppContext *)[context int_mergeUpdates:contextUpdates];
  };
}

@end

NS_ASSUME_NONNULL_END
