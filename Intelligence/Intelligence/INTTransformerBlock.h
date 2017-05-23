// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDataStructures.h"

NS_ASSUME_NONNULL_BEGIN

@class INTEventMetadata;

/// In the Intelligence events pipeline, events are divided into two kinds:
///
/// 1. Low level events: events containing minimal and very specific data about an occurrence in
/// the client application.
///
/// 2. High level events: events which is the result of aggregated data from one or more low level
/// events.
///
/// A transformer block is used for creating a pure function logic that can aggregate event data
/// over a sequence of low level events that are reported to the Intelligence pipeline on various
/// occurences in the client application, producing high level events with processed data.
///
/// The main reasons for using an event transformer are:
///
/// 1. Low-level events can be shared across many high-level events.
///
/// 2. Low-level events usually do not include aggregated data that can be derived from multiple
/// events.
///
/// A simple example of such aggregation is a high level event stating that the application was in
/// foreground mode, and went into background mode - such event usually has the duration of the
/// foreground activity and can be aggregated over two low level events: 'app did enter foreground'
/// and 'app did enter background'.
///
/// Usage example:
///
/// @code
/// // Transformer that returns a @"lifetime" when receiving @"background" event after @"foreground"
/// // event.
/// INTTransformerBlock transformerBlock = ...;
/// NSDictionary<NSString *, id> *initialAggregatedData = @{};
///
/// // Some code running.
///
/// // @"foreground" event is reported
/// auto result = transformerBlock(@{}, appContext, eventMetadata, @"foreground");
/// NSLog(@"events: %@", result.highLevelEvents) // prints "events: []"
///
/// // Some more code running.
///
/// // @"background" event is reported
/// result = transformerBlock(result.aggregatedData, appContext, eventMetadata, @"background");
/// NSLog(@"events: %@", result.highLevelEvents) // prints "events: ['lifetime']"
/// @endcode

namespace intl {
// Result of an \c INTTransformerBlock.
  struct TransformerBlockResult {
    // Initializes with \c aggregatedData and \c events. If any of the arguments is \c nil, an empty
    // \c NSDictionary or \c NSArray is set to the respective members.
    TransformerBlockResult(NSDictionary<NSString *, id> * _Nullable aggregatedData = nil,
                           NSArray * _Nullable highLevelEvents = nil) :
        aggregatedData(aggregatedData ?: @{}), highLevelEvents(highLevelEvents ?: @[]) {}

    // Aggregated data of an event transformation process. Cumulated over subsequent executions
    // of a transformer block.
    NSDictionary<NSString *, id> *aggregatedData;

    // High level aggregated events, result of one or many aggregations over raw events.
    NSArray *highLevelEvents;
  };
} // namespace intl

/// Block defining an aggregation in the form of prefix sum over \c aggregatedData,
/// \c appContext, \c eventMetadata and \c event, returning an \c INTTransformerBlockResult.
/// Subsequent calls to this block should be invoked with the last returned \c aggregationData by
/// this block. The block must be a pure function without side effects.
typedef intl::TransformerBlockResult(^INTTransformerBlock)
    (NSDictionary<NSString *, id> *aggregatedData, INTAppContext *appContext,
     INTEventMetadata *eventMetadata, id event);

/// Block defining an enrichements of \c events, with data from \c appContext and \c metadata.
typedef NSArray * _Nonnull(^INTEventEnrichmentBlock)(NSArray *events, INTAppContext *appContext,
    INTEventMetadata *metadata);

/// Returns a composed \c INTTransformerBlock. The resulting \c INTTransformerBlock invokes
/// \c transformerBlock with \c aggregatedData, \c appContext, \c eventMetadata and \c event, and
/// invokes \c enrichmentBlock on resulting \c highLevelEvents. Returns the \c aggregatedData
/// returned from transformer and the enriched \c highLevelEvents.
INTTransformerBlock INTEnrichTransformer(INTTransformerBlock transformerBlock,
                                         INTEventEnrichmentBlock enrichmentBlock);

NS_ASSUME_NONNULL_END
