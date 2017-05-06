// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTTransformerBlock.h"
#import "INTTransformerBlockBuilderStructures.h"

NS_ASSUME_NONNULL_BEGIN

/// Static class of \c INTTransformerBlock blocks that produce \c INTAnalytricksBaseUsage high level
/// events. Each transformer returned by this class transforms events in a cycle form, including a
/// cycle of one (a.k.a map). A resulting \c INTAnalytricksBaseUsage always has the following
/// properties:
///
/// 1. \c INTAnalytricksMetadata member is combined of the data passed in:
///    - \c INTEventMetadata: \c totalRunTime, \c eventID, \c deviceTimestamp.
///    - \c ltDeviceID has the value for kINTAppContextDeviceIDKey in \c INTAppContext.
///    - \c deviceInfoID has the value for kINTAppContextDeviceInfoIDKey in \c INTAppContext.
/// 2. \c INTAnalytricksContext has the value for kINTAppContextAnalytricsContextKey in
///    \c INTAppContext.
/// 3. \c INTAnalytricksMetadata and \c INTAnalytricksContext members are composed either by the
///    context and metadata processed with the start low level event or the end low level event.
///    Merge of context or metadata from the start and end of a cycle is never done by the
///    transformer blocks.
///
/// If any value for the keys \c kINTAppContextAnalytricsContextKey, \c kINTAppContextDeviceIDKey
/// and \c kINTAppContextDeviceInfoIDKey is not set, the transformers will not produce events.
@interface INTAnalytricksBaseUsageTransformerBlocks : NSObject

/// Transformer that produces an \c INTAnalytricksBaseUsage event with \c dataProvider set to
/// an \c INTAnalytricksAppForegrounded. The transformer observes a cycle of low level events
/// starting with \c INTAppWillEnterForegroundEvent and ending with \c INTAppBecameActiveEvent. It
/// also observes mid-cycle events - \c INTDeepLinkOpenedEvent and
/// \c INTPushNotificationOpenedEvent. The \c source property of \c INTAnalytricksAppForegrounded is
/// set according to the last occurence of one of the following events before the cycle ends:
///
/// 1. INTAppWillEnterForegroundEvent - value is set to "app_launcher".
/// 2. INTDeepLinkOpenedEvent - value is set to "deep_link".
/// 3. INTPushNotificationOpenedEvent - value is set to "push_notification".
///
/// The context and metadata used by this transformer are of the cycles' start.
+ (INTTransformerBlock)foregroundEventTransformer;

/// Transformer that produces an \c INTAnalytricksBaseUsage event with \c dataProvider set to
/// an \c INTAnalytricksAppBackgrounded. The transformer observes a cycle of low level events
/// starting with \c INTAppWillEnterForegroundEvent and ending with \c INTAppBacgroundedEvent. The
/// \c foregroundDuration property of \c INTAnalytricksAppForegrounded is set to the duration of
/// the cycle. The context and metadata used by this transformer are of the cycles' end.
+ (INTTransformerBlock)backgroundEventTransformer;

/// Transformer that produces an \c INTAnalytricksBaseUsage event with \c dataProvider set to
/// an \c INTAnalytricksScreenVisited. The transformer observes a cycle of low level events
/// starting with \c INTScreenDisplayedEvent and ending with \c INTScreenDismissedEvent. The
/// \c screenDuration property of \c INTAnalytricksAppForegrounded is set to the duration of
/// the cycle. \c dismissAction is fetched from \c INTScreenDismissedEvent. The context and metadata
/// used by this transformer are of the cycles' end.
+ (INTTransformerBlock)screenVisitedEventTransformer;

@end

NS_ASSUME_NONNULL_END
