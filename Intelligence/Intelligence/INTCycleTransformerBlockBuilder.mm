// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTCycleTransformerBlockBuilder.h"

#import "INTEventMetadata.h"
#import "INTTransformerBlockBuilder.h"
#import "NSDictionary+Merge.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kINTStartContextKey = @"_INTStartContext";

NSString * const kINTStartMetadataKey = @"_INTStartMetadata";

NSString * const kINTCycleDurationKey = @"_INTCycleDuration";

@interface INTCycleTransformerBlockBuilder ()

/// Event that starts an aggregation cycle.
@property (readonly, nonatomic) NSString *startEvent;

/// Event that ends an aggregation cycle.
@property (readonly, nonatomic) NSString *endEvent;

/// Invoked at the end of an aggregation cycle.
@property (readonly, nonatomic) INTTransformCompletionBlock cycleCompletion;

/// Key that holds the cycle duration in the end of an aggregation.
@property (readonly, nonatomic) NSString * _Nullable cycleDurationKey;

/// Aggregation blocks for event classes.
@property (readonly, nonatomic) INTAggregationBlocks *aggregationBlocks;

/// Identifies events at the beginning of a round in the transformation.
@property (readonly, nonatomic) INTEventIdentifierBlock eventIdentifier;

@end

@implementation INTCycleTransformerBlockBuilder

/// Key for an \c NSDictionary containing internal transformation cycle info.
static NSString * const kKeyForCycleInfo = @"CycleInfo";

/// Key for a \c BOOL in the aggregated data that represents the state of the cycle. \c YES means
/// that a cycle is ongoing.
static NSString * const kKeyForIsCycleOn = @"IsCycleOn";

/// Key for an \c NSDictionary containing the custom aggregations of blocks added by the
/// <tt>-[INTCycleTransformerBlockBuilder aggregate]</tt> method.
static NSString * const kKeyForCycleAggregations = @"CycleAggregations";

+ (instancetype)defaultBuilder {
  return [[self alloc] initWithEventIdentifier:^(id event) {
    return NSStringFromClass([event class]);
  }];
}

+ (instancetype)builderWithEventIdentifier:(NSString * _Nullable(^)(id))eventIdentifier {
  return [[self alloc] initWithEventIdentifier:eventIdentifier];
}

- (instancetype)initWithEventIdentifier:(NSString * _Nullable(^)(id))eventIdentifier {
  if (self = [super init]) {
    _eventIdentifier = eventIdentifier;

    _aggregationBlocks = [NSMutableDictionary dictionary];
  }
  return self;
}

- (INTCycleTransformerBlockBuilder * _Nonnull (^)(NSString *, NSString *))cycle {
  return ^(NSString *startEventType, NSString *endEventType) {
    self->_startEvent = startEventType;
    self->_endEvent = endEventType;
    return self;
  };
}

- (INTCycleTransformerBlockBuilder *(^)(NSString *eventType, intl::AggregationBlock))aggregate {
  return ^(NSString *eventType, intl::AggregationBlock aggregationBlock) {
    [self addBlock:aggregationBlock.getFullBlock() forEventType:eventType];
    return self;
  };
}

- (void)addBlock:(INTAggregationBlock)block forEventType:(NSString *)eventType {
  NSMutableArray *eventBlocks = [self.aggregationBlocks[eventType] ?: @[] mutableCopy];
  [eventBlocks addObject:block];
  self.aggregationBlocks[eventType] = [eventBlocks copy];
}

- (INTCycleTransformerBlockBuilder *(^)(intl::TransformCompletionBlock))onCycleEnd {
  return ^(intl::TransformCompletionBlock block) {
    self->_cycleCompletion = block.getFullBlock();
    return self;
  };
}

- (INTCycleTransformerBlockBuilder *(^)(NSString *key))appendDuration {
  return ^(NSString *key) {
    self->_cycleDurationKey = key;
    return self;
  };
}

- (INTTransformerBlock(^)())build {
  LTParameterAssert(_cycleCompletion, @"Completion must be set prior to building the transformer");
  LTParameterAssert(_startEvent, @"Start event must be set prior to building the transformer");
  LTParameterAssert(_endEvent, @"End event must be set prior to building the transformer");

  INTTransformerBlock internalTransformerBlock = [self internalTransformerBlock];

  auto startEvent = self.startEvent;
  auto endEvent = self.endEvent;
  INTEventIdentifierBlock eventIdentifier = self.eventIdentifier;

  return ^() {
    return ^(NSDictionary<NSString *, id> *aggregationData, INTAppContext *context,
             INTEventMetadata *metadata, id event) {
      auto _Nullable eventType = eventIdentifier(event);

      if (!eventType) {
        return intl::TransformerBlockResult(aggregationData, nil);
      }

      auto aggregationDataUpdates = [NSMutableDictionary dictionary];

      if ([eventType isEqual:startEvent]) {
        aggregationDataUpdates[kKeyForCycleInfo] = @{
          kKeyForIsCycleOn: @YES
        };
      } else if (![aggregationData[kKeyForCycleInfo][kKeyForIsCycleOn] boolValue]) {
        return intl::TransformerBlockResult(aggregationData, nil);
      }

      NSDictionary<NSString *,id> *cycleAggregations =
          aggregationData[kKeyForCycleAggregations] ?: @{};

      auto result = internalTransformerBlock(cycleAggregations, context, metadata, event);

      aggregationDataUpdates[kKeyForCycleAggregations] = result.aggregatedData;

      if ([eventType isEqual:endEvent]) {
        aggregationDataUpdates[kKeyForCycleInfo] = @{
          kKeyForIsCycleOn: @NO
        };
      }

      aggregationData = [aggregationData int_mergeUpdates:aggregationDataUpdates];
      return intl::TransformerBlockResult(aggregationData, result.highLevelEvents);
    };
  };
}

- (INTTransformerBlock)internalTransformerBlock {
  __block INTTransformerBlockBuilder *internalBlockBuilder =
      [self builderWithCycleDurationForStartEvent:self.startEvent endEvent:self.endEvent];

  [self.aggregationBlocks enumerateKeysAndObjectsUsingBlock:^(NSString *eventType,
                                                              NSArray<INTAggregationBlock> *blocks,
                                                              BOOL *) {
    for (INTAggregationBlock aggregationBlock in blocks) {
      internalBlockBuilder = internalBlockBuilder.aggregate(eventType, aggregationBlock);
    }
  }];

  INTAggregationBlock aggregateContext =
      ^(NSDictionary<NSString *, id> *, id, INTEventMetadata *, INTAppContext *appContext) {
        return @{kINTStartContextKey: appContext};
      };

  internalBlockBuilder = internalBlockBuilder.aggregate(self.startEvent, aggregateContext);

  INTPartialAggregationBlock aggregateMetadata =
      ^(NSDictionary<NSString *,id> *, id, INTEventMetadata *metadata) {
        return @{kINTStartMetadataKey: metadata};
      };

  internalBlockBuilder = internalBlockBuilder.aggregate(self.startEvent, aggregateMetadata);

  return internalBlockBuilder.transform(self.endEvent, self.cycleCompletion).build();
}

- (INTTransformerBlockBuilder *)builderWithCycleDurationForStartEvent:(NSString *)startEvent
                                                             endEvent:(NSString *)endEvent {
  INTPartialAggregationBlock durationStart =
      ^(NSDictionary<NSString *,id> *, id, INTEventMetadata *metadata) {
        return @{kINTCycleDurationKey: @(metadata.totalRunTime)};
      };

  INTPartialAggregationBlock durationEnd =
      ^(NSDictionary<NSString *,id> *aggregationData, id, INTEventMetadata *metadata) {
        auto duration = metadata.totalRunTime -
            [aggregationData[kINTCycleDurationKey] doubleValue];
        return @{kINTCycleDurationKey: @(duration)};
      };

  return INTTransformerBuilder(self.eventIdentifier)
      .aggregate(startEvent, durationStart)
      .aggregate(endEvent, durationEnd);
}

@end

NS_ASSUME_NONNULL_END
