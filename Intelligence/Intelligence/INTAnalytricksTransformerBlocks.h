// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTTransformerBlock.h"
#import "INTTransformerBlockBuilderStructures.h"

NS_ASSUME_NONNULL_BEGIN

/// Static class of \c INTTransformerBlock blocks that produce Analytricks events as defined by the
/// Lightricks backend.
@interface INTAnalytricksTransformerBlocks : NSObject

/// Key for an \c NSNumber enrichment representing the app run count.
extern NSString * const kINTEnrichmentAppRunCountKey;

/// Returns a block that adds entries from an \c NSDictionary resulting from
/// <tt>-[INTAnalytricksContext properties]</tt> to each event in \c events only if an event is an
/// \c NSDictionary and if \c appContext contains an \c INTAnalytricksContext in
/// \c kINTAppContextAnalytricksContextKey, otherwise the event is returned as is. If there's a
/// conflict between the event keys and the analytricks context keys, the events' values are taken
/// for the final dictionary.
+ (INTEventEnrichmentBlock)analytricksContextEnrichementBlock;

/// Returns a block that adds entries from an \c NSDictionary resulting from
/// <tt>-[INTAnalytrickMetadata properties]</tt> to each event in \c events only if an event is an
/// \c NSDictionary and if \c appContext contains an \c kINTAppContextDeviceIDKey in
/// \c kINTAppContextDeviceInfoIDKey, otherwise the event is returned as is. If there's a conflict
/// between the event keys and the analytricks metadata keys, the events' values are taken for the
/// final dictionary.
+ (INTEventEnrichmentBlock)analytricksMetadataEnrichementBlock;

/// Returns a block that adds \c kINTEnrichmentAppRunCountKey key with the value of
/// \c kINTAppContextAppRunCountKey to each event in \c events only if an event is an
/// \c NSDictionary and if \c appContext contains an \c kINTAppContextAppRunCountKey, otherwise the
/// event is returned as is. If there's a conflict between the event keys and the
/// \c kINTEnrichmentAppRunCountKey key, the events' value are taken for that key.
+ (INTEventEnrichmentBlock)appRunCountEnrichementBlock;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalytricksAppForegrounded properties]</tt>. The transformer observes a cycle of low
/// level events starting with \c INTAppWillEnterForegroundEvent and ending with
/// \c INTAppBecameActiveEvent. It also observes mid-cycle events - \c INTDeepLinkOpenedEvent and
/// \c INTPushNotificationOpenedEvent. The \c source property of \c INTAnalytricksAppForegrounded is
/// set according to the last occurence of one of the following events before the cycle ends:
///
/// 1. INTAppWillEnterForegroundEvent - value is set to "app_launcher".
/// 2. INTDeepLinkOpenedEvent - value is set to "deep_link".
/// 3. INTPushNotificationOpenedEvent - value is set to "push_notification".
+ (INTTransformerBlock)foregroundEventTransformer;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalytricksAppBackgrounded properties]</tt>. The transformer observes a cycle of low
/// level events starting with \c INTAppWillEnterForegroundEvent and ending with
/// \c INTAppBackgroundedEvent. The \c foregroundDuration property of
/// \c INTAnalytricksAppBackgrounded is set to the duration of the cycle.
+ (INTTransformerBlock)backgroundEventTransformer;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalytricksScreenVisited properties]</tt>. The transformer observes a cycle of low
/// level events starting with \c INTScreenDisplayedEvent and ending with
/// \c INTScreenDismissedEvent. The \c screenDuration property of \c INTAnalytricksScreenVisited
/// is set to the duration of the cycle. \c dismissAction is fetched from
/// \c INTScreenDismissedEvent.
+ (INTTransformerBlock)screenVisitedEventTransformer;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalytricksDeepLinkOpened properties]</tt> when observing an \c INTDeepLinkOpenedEvent.
+ (INTTransformerBlock)deepLinkOpenedEventTransformer;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalytricksPushNotificationOpened properties]</tt> when observing an
/// \c INTPushNotificationOpenedEvent.
+ (INTTransformerBlock)pushNotificationOpenedEventTransformer;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalytricksAssetImported properties]</tt> when observing an
/// \c INTAssetImportedEvent.
+ (INTTransformerBlock)mediaImportedEventTransformer;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalytricksMediaExported properties]</tt>. The transformer observes the low level
/// events with \c INTMediaExportStartedEvent and \c INTMediaExportEndedEvent. When an
/// \c INTMediaExportEndedEvent is observed, a event is created for each observed
/// \c INTMediaExportStartedEvent with the same \c exportID.
+ (INTTransformerBlock)mediaExportedEventTransformer;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalytricksProjectDeleted properties]</tt> when observing an \c INTProjectDeletedEvent.
+ (INTTransformerBlock)projectDeletedEventTransformer;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalytricksProjectModified properties]</tt>. The transformer observes a cycle of low
/// level events starting with \c INTProjectLoadedEvent and ending with
/// \c INTProjectUnloadedEvent. It also observes a mid-cycle \c INTProjectDeletedEvent. The
/// \c usageDuration property of \c INTAnalytricksProjectModified is set to the duration of the
/// cycle. \c projectDeleted is set to \c YES if \c INTProjectDeletedEvent with the \c projectID of
/// the start event is observed, otherwise it is set to \c NO.
+ (INTTransformerBlock)projectModifiedEventTransformer;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalyticsDeviceInfoChanged properties]</tt> when observing an \c INTDeviceInfoLoaded
/// with \c isNewRevision set to \c YES.
+ (INTTransformerBlock)deviceInfoChangedEventTransformer;

/// Transformer that produces an \c NSDictionary, resulting from
/// <tt>-[INTAnalytricksDeviceTokenChanged properties]</tt> when observing an
/// \c INTDeviceTokenChangedEvent.
+ (INTTransformerBlock)deviceTokenChangedEventTransformer;

@end

NS_ASSUME_NONNULL_END
