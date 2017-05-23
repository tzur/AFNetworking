// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTTransformerBlock.h"

INTTransformerBlock INTEnrichTransformer(INTTransformerBlock transformerBlock,
                                         INTEventEnrichmentBlock enrichmentBlock) {
  return ^(NSDictionary<NSString *, id> *aggregatedData, INTAppContext *appContext,
           INTEventMetadata *eventMetadata, id event) {
    auto result = transformerBlock(aggregatedData, appContext, eventMetadata, event);

    if (!result.highLevelEvents.count ) {
      return result;
    }

    auto enrichedEvents = enrichmentBlock(result.highLevelEvents, appContext, eventMetadata);
    return intl::TransformerBlockResult(result.aggregatedData, enrichedEvents);
  };
}
