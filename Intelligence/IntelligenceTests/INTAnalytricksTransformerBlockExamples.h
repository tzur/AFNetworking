// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Name of the example group of \c INTTransformerBlock blocks that produce
/// \c INTAnalytricsBaseUsage high level events. A transformer that's tested in these test examples
/// is expected to produce its events in a cycle form, including a cycle of one (a.k.a map). A
/// resulting \c INTAnalytricsBaseUsage must obide the following rules:
///
/// 1. \c INTAnalytricksMetadata member is combined of the data passed in:
///    - \c INTEventMetadata: \c totalRunTime, \c eventID, \c deviceTimestamp.
///    - \c ltDeviceID has the value for kINTAppContextDeviceIDKey in \c INTAppContext.
///    - \c deviceInfoID has the value for kINTAppContextDeviceInfoIDKey in \c INTAppContext.
/// 2. \c INTAnalytricksContext has the value for kINTAppContextAnalytricsContextKey in
///    \c INTAppContext.
/// 3. \c INTAnalytricksMetadata and \c INTAnalytricksContext members are composed either by the
///    context and metadata processed with the start low level event or the end low level event.
///    Merge of context or metadata from the start and end of a cycle is not expected and will fail
///    the example group.
extern NSString * const kINTAnalytricksBaseUsageTransformerBlockExamples;

/// Key pointing to the \c INTTransformerBlock object. Value for this key is mandatory.
extern NSString * const kINTAnalytricksBaseUsageTransformerBlock;

/// Key pointing to the <tt>NSArray<INTEventTransformerArguments *></tt> object. Value for this key
/// is mandatory.
extern NSString * const kINTAnalytricksEventTransformerArgumentsSequence;

/// Key pointing to the \c NSArray object containing the expected \c . Value for this key is
/// mandatory.
extern NSString * const kINTExpectedAnalytricksBaseUsageDataProviders;

/// Key pointing to an \c NSArray of \c NSNumber objects stating the start indices of transformation
/// cycles. This key can be excluded if a transformer is a mapper, or if the array in
/// \c kINTAnalytricksEventTransformerArgumentsSequence is a single strict cycle.
extern NSString * const kINTCycleStartIndices;

/// Key pointing to a \c BOOL. If the value is \c YES then the start event context is used for the
/// \c INTAnalytricsBaseUsage wrapper initiaization, otherwise the end event context is used. This
/// key can be excluded if the transformation is not a cycle transformation.
extern NSString * const kINTShouldUseStartContext;

/// Key pointing to a \c BOOL. If the value is \c YES then the start event metadata is used for the
/// \c INTAnalytricsBaseUsage wrapper initiaization, otherwise the end event metadata is used. This
/// key can be excluded if the transformation is not a cycle transformation.
extern NSString * const kINTShouldUseStartMetadata;

NS_ASSUME_NONNULL_END
