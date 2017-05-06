// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksContextGenerators.h"

#import <LTKit/LTKeyPathCoding.h>

#import "INTAnalytricksContext+Merge.h"
#import "INTAppWillEnterForegroundEvent.h"
#import "INTProjectLoadedEvent.h"
#import "INTProjectUnloadedEvent.h"
#import "INTScreenDisplayedEvent.h"
#import "INTTransformerBlockBuilder.h"
#import "NSDictionary+Merge.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kINTAppContextAnalytricksContextKey =
    @"_INTAnalytricksContext";
extern NSString * const kINTAppContextDeviceIDKey = @"_INTDeviceID";
extern NSString * const kINTAppContextDeviceInfoIDKey = @"_INTDeviceInfoID";

/// Block that inspects \c event and returns the updates that should be commited to the analytrics
/// context in a context aggregation process. The block must be a pure function without side
/// effects. Key having \c NSNull means that the property should be set to \c nil.
typedef NSDictionary<NSString *, id> *(^INTAnalytricksContextUpdates)(id event);

INTAggregationBlock INTAnalytricksContextAggregation(INTAnalytricksContextUpdates updatesBlock) {
  return ^(NSDictionary<NSString *, id> *, id event, INTEventMetadata *, INTAppContext *context) {
    INTAnalytricksContext * _Nullable analytricksContext =
        context[kINTAppContextAnalytricksContextKey];
    if (!analytricksContext) {
      LogWarning(@"Application did not report INTAppWillForegroundEvent with property isLaunch set "
                 "to YES. The kINTAppContextAnalytricksContextKey in the resulting context remains "
                 "empty until then");
      return @{};
    }

    auto updates = updatesBlock(event);

    return @{kINTAppContextAnalytricksContextKey: [analytricksContext merge:updates]};
  };
}

@implementation INTAnalytricksContextGenerators

+ (INTAppContextGeneratorBlock)analytricksContextGenerator {
  auto foregroundAggregation = ^(INTAppWillEnterForegroundEvent *event) {
    if (event.isLaunch) {
      return @{};
    }

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
                 ^(NSDictionary<NSString *, id> *, INTAppWillEnterForegroundEvent *event) {
        if (!event.isLaunch) {
          return @{};
        }

        INTAnalytricksContext *analytricksContext =
            [[INTAnalytricksContext alloc]
             initWithRunID:[NSUUID UUID] sessionID:[NSUUID UUID] screenUsageID:nil screenName:nil
             openProjectID:nil];

        return @{kINTAppContextAnalytricksContextKey: analytricksContext};
      })
      .aggregate(NSStringFromClass(INTAppWillEnterForegroundEvent.class),
                 INTAnalytricksContextAggregation(foregroundAggregation))
      .aggregate(NSStringFromClass(INTScreenDisplayedEvent.class),
                 INTAnalytricksContextAggregation(screenDisplayAggregation))
      .aggregate(NSStringFromClass(INTProjectLoadedEvent.class),
                 INTAnalytricksContextAggregation(projectLoadAggregation))
      .aggregate(NSStringFromClass(INTProjectUnloadedEvent.class),
                 INTAnalytricksContextAggregation(projectCloseAggregation))
      .build();

  return ^(INTAppContext *context, INTEventMetadata *eventMetadata, id event) {
    auto contextUpdates = transformer(@{}, context, eventMetadata, event).aggregatedData;
    return [context int_mergeUpdates:contextUpdates];
  };
}

+ (INTAppContextGeneratorBlock)deviceInfoContextGenerator {
  return ^(INTAppContext *context, INTEventMetadata *, INTAppWillEnterForegroundEvent *event) {
    if (![event isKindOfClass:INTAppWillEnterForegroundEvent.class] || !event.isLaunch) {
      return context;
    }

    auto contextUpdates = @{
      kINTAppContextDeviceIDKey: [UIDevice currentDevice].identifierForVendor,
      kINTAppContextDeviceInfoIDKey: [UIDevice currentDevice].identifierForVendor
    };
    return (INTAppContext *)[context int_mergeUpdates:contextUpdates];
  };
}

@end

NS_ASSUME_NONNULL_END
