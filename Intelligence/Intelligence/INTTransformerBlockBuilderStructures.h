// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDataStructures.h"

NS_ASSUME_NONNULL_BEGIN

/// Block that inspects \c aggregatedData, \c event, \c metadata and \c context and returns the
/// updates that should be commited to the aggregated data of an event transformation process. The
/// block must be a pure function without side effects. Key having \c NSNull means that is should be
/// removed.
typedef NSDictionary<NSString *, id> * _Nonnull(^INTAggregationBlock)
    (NSDictionary<NSString *, id> *aggregatedData, id event, INTEventMetadata *metadata,
     INTAppContext *context);

/// Block that inspects \c aggregatedData, \c event and \c metadata and returns the updates that
/// should be commited to the aggregated data of an event transformation process. The block must be
/// a pure function without side effects. Key having \c NSNull means that is should be removed.
typedef NSDictionary<NSString *, id> * _Nonnull(^INTPartialAggregationBlock)
    (NSDictionary<NSString *, id> *aggregatedData, id event, INTEventMetadata *metadata);

/// Block that inspects \c aggregatedData and \c event and returns the updates that should be
/// commited to the aggregated data of an event transformation process. The block must be a pure
/// function without side effects. Key having \c NSNull means that is should be removed.
typedef NSDictionary<NSString *, id> * _Nonnull(^INTEventDataAggregationBlock)
    (NSDictionary<NSString *, id> *aggregatedData, id event);

/// Block that inspects \c aggregatedData, \c event, \c metadata and \c context and returns an array
/// of high level events. The block must be a pure function without side effects.
typedef NSArray * _Nonnull(^INTTransformCompletionBlock)
    (NSDictionary<NSString *, id> *aggregatedData, id event, INTEventMetadata *metadata,
     INTAppContext *context);

/// Block that inspects \c aggregatedData returns an array of high level events. The block must be a
/// pure function without side effects.
typedef NSArray * _Nonnull(^INTAggregationTransformCompletionBlock)
    (NSDictionary<NSString *, id> *aggregatedData);

/// Returns an \c NSString describing an \c event. The resulting string is considered as the event
/// type. Returns \c nil if an \c event is unsupported or if the block logic failed to produce an
/// identifier for it. The block must be a pure deterministic function without side effects.
typedef NSString * _Nullable(^INTEventIdentifierBlock)(id event);

/// A mapping from event identifiers to arrays of \c INTAggregationBlock blocks.
typedef NSMutableDictionary<NSString *, NSArray<INTAggregationBlock> *> INTAggregationBlocks;

namespace intl {

/// Class for transforming from different types of aggregation blocks to \c INTAggregationBlock.
class AggregationBlock {
public:
  /// Initializes with the given \c block. Raises an \c NSInvalidArgumentException if \c block is
  /// \c nil.
  AggregationBlock(INTAggregationBlock block) : _fullBlock(block) {
    LTParameterAssert(_fullBlock);
  };

  /// Initializes with the given \c block. \c block is used as an underlying block for a full
  /// \c INTAggregationBlock, with the resulting block ignoring the \c appContext argument.
  AggregationBlock(INTPartialAggregationBlock block) :
      AggregationBlock(^(NSDictionary<NSString *, id> *aggregatedData, id event,
                         INTEventMetadata *metadata, INTAppContext *) {
        return block(aggregatedData, event, metadata);
      }) {}

  /// Initializes with the given \c block. \c block is used as an underlying block for a full
  /// \c INTAggregationBlock, with the resulting block ignoring the \c appContext and \c metadata
  /// arguments.
  AggregationBlock(INTEventDataAggregationBlock block) :
      AggregationBlock(^(NSDictionary<NSString *, id> *aggregatedData, id event, INTEventMetadata *,
                         INTAppContext *) {
        return block(aggregatedData, event);
      }) {}

  /// Returns an \c INTAggregationBlock which is powered by the underlying \c block that was passed
  /// in a constructor.
  INTAggregationBlock getFullBlock() const {
    return _fullBlock;
  }

private:
  /// Resulting \c INTAggregationBlock.
  INTAggregationBlock _fullBlock;
};

/// Class for transforming from different types of transform completion blocks to
/// \c INTTransformCompletionBlock.
class TransformCompletionBlock {
public:
  /// Initializes with the given \c block. Raises an \c NSInvalidArgumentException if \c block is
  /// \c nil.
  TransformCompletionBlock(INTTransformCompletionBlock block) : _fullBlock(block) {
   LTParameterAssert(_fullBlock);
  };

  /// Initializes with the given \c block. \c block is used as an underlying block for a full
  /// \c INTAggregationBlock, with the resulting block ignoring the \c appContext, \c metadata
  /// and \c event arguments.
  TransformCompletionBlock(INTAggregationTransformCompletionBlock block) :
      TransformCompletionBlock(^(NSDictionary<NSString *, id> *aggregatedData, id,
                                 INTEventMetadata *, INTAppContext *) {
          return block(aggregatedData);
      }) {}

  /// Returns an \c INTTransformCompletionBlock which is powered by the underlying \c block that
  /// was passed in a constructor.
  INTTransformCompletionBlock getFullBlock() const {
    return _fullBlock;
  }

private:
  /// Resulting \c INTTransformCompletionBlock.
  INTTransformCompletionBlock _Nullable _fullBlock;
};

} /// namespace intl

NS_ASSUME_NONNULL_END
