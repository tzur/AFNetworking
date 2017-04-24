// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTEventTransformer.h"

NS_ASSUME_NONNULL_BEGIN

/// Most recent aggregated data of transformer blocks.
typedef NSMutableArray<NSDictionary<NSString *, id> *> INTTransformerAggregations;

@interface INTEventTransformer ()

/// Transformer blocks.
@property (readonly, nonatomic) std::vector<INTTransformerBlock> transformerBlocks;

/// Transformers aggregated data.
@property (readonly, nonatomic) INTTransformerAggregations *aggregations;

@end

@implementation INTEventTransformer

- (instancetype)initWithTransformerBlocks:
    (const std::vector<INTTransformerBlock> &)transformerBlocks {
  if (self = [super init]) {
    _transformerBlocks = transformerBlocks;

    @synchronized (self.aggregations) {
      _aggregations = [self initialAggregationsWithSize:transformerBlocks.size()];
    }
  }
  return self;
}

- (INTTransformerAggregations *)initialAggregationsWithSize:(size_t)size {
  auto aggregations = [NSMutableArray arrayWithCapacity:size];
  for (size_t i = 0; i < size; ++i) {
    aggregations[i] = @{};
  }
  return aggregations;
}

- (NSArray *)processEvent:(id)event metadata:(INTEventMetadata *)metadata
               appContext:(INTAppContext *)appContext {
  @synchronized (self.aggregations) {
    auto highLevelEvents = [NSMutableArray array];

    for (size_t i = 0; i < self.transformerBlocks.size(); ++i) {
      auto aggregationData = self.aggregations[i];

      auto result = self.transformerBlocks[i](aggregationData, appContext, metadata, event);
      self.aggregations[i] = result.aggregatedData;
      [highLevelEvents addObjectsFromArray:result.highLevelEvents];
    }

    return [highLevelEvents copy];
  }
}

@end

NS_ASSUME_NONNULL_END
