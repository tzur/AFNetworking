// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTTransformerBlockBuilder.h"

#import "NSDictionary+Merge.h"

NS_ASSUME_NONNULL_BEGIN

/// A mapping from event identifiers to arrays of \c INTTransformCompletionBlock blocks.
typedef NSMutableDictionary<NSString *, NSArray<INTTransformCompletionBlock> *>
    INTTransformCompletionBlocks;

@interface INTTransformerBlockBuilder ()

/// Used for getting events identifier from event objects.
@property (readonly, nonatomic) INTEventIdentifierBlock eventIdentifier;

/// Aggregation blocks for event classes.
@property (readonly, nonatomic) INTAggregationBlocks *aggregationBlocks;

/// Completion blocks for event classes.
@property (readonly, nonatomic) INTTransformCompletionBlocks *completionBlocks;

@end

@implementation INTTransformerBlockBuilder

+ (instancetype)defaultBuilder {
  return [[self alloc] initWithEventIdentifier:^(id event) {
    return NSStringFromClass([event class]);
  }];
}

+ (instancetype)builderWithEventIdentifier:(NSString * _Nullable(^)(id))eventIdentifier {
  LTParameterAssert(eventIdentifier);
  return [[self alloc] initWithEventIdentifier:eventIdentifier];
}

- (instancetype)initWithEventIdentifier:(NSString * _Nullable(^)(id))eventIdentifier {
  if (self = [super init]) {
    _eventIdentifier = eventIdentifier;
    _aggregationBlocks = [NSMutableDictionary dictionary];
    _completionBlocks = [NSMutableDictionary dictionary];
  }
  return self;
}

- (INTTransformerBlockBuilder *(^)(NSString *eventType, intl::AggregationBlock))aggregate {
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

- (INTTransformerBlockBuilder *(^)(NSString *eventType, intl::TransformCompletionBlock))transform {
  return ^(NSString *eventType, intl::TransformCompletionBlock completion) {
    [self addCompletionBlock:completion.getFullBlock() forEventType:eventType];
    return self;
  };
}

- (void)addCompletionBlock:(INTTransformCompletionBlock)block forEventType:(NSString *)eventType {
  NSMutableArray *completions = [self.completionBlocks[eventType] ?: @[] mutableCopy];
  [completions addObject:block];
  self.completionBlocks[eventType] = [completions copy];
}

- (INTTransformerBlock(^)())build {
  return ^() {
    NSDictionary<NSString *, NSArray<INTAggregationBlock> *> *aggregationBlocks =
        [self.aggregationBlocks copy];
    NSDictionary<NSString *, NSArray<INTTransformCompletionBlock> *> *completionBlocks =
        [self.completionBlocks copy];

    INTEventIdentifierBlock eventIdentifier = self->_eventIdentifier;

    return ^(NSDictionary<NSString *,id> *aggregatedData, INTAppContext *context,
             INTEventMetadata *metadata, id event) {
      NSString * _Nullable eventType = eventIdentifier(event);

      if (!eventType) {
        return intl::TransformerBlockResult(aggregatedData, nil);
      }

      auto eventAggregationBlocks = aggregationBlocks[eventType];
      if (eventAggregationBlocks) {
        for (INTAggregationBlock block in eventAggregationBlocks) {
          auto aggregatedDataUpdates = block(aggregatedData, event, metadata, context);
          aggregatedData = [aggregatedData int_mergeUpdates:aggregatedDataUpdates];
        }
      }

      NSMutableArray *events = [NSMutableArray array];

      auto eventCompletionBlocks = completionBlocks[eventType];
      if (eventCompletionBlocks) {
        for (INTTransformCompletionBlock block in eventCompletionBlocks) {
          [events addObjectsFromArray:block(aggregatedData, event, metadata, context)];
        }
      }

      return intl::TransformerBlockResult(aggregatedData, events);
    };
  };
}

@end

NS_ASSUME_NONNULL_END
