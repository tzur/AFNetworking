// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTEventLogger.h"

NS_ASSUME_NONNULL_BEGIN

@class Alooma;

/// Events that are provided by Intelligence that should always be whitelisted in for sending to
/// Alooma.
extern NSSet<NSString *> * const kINTDefaultWhitelistedEvents;

/// Returns a dictionary with the following structure:
/// @code
/// @{
///   @"event": "alooma_json_serialization_error",
///   @"event_description": [event description],
///   @"original_event_type": event[@"event"],
///   @"id_for_vendor": [[UIDevice currentDevice] identifierForVendor].UUIDString
/// }
/// @endcode
///
/// @note if <tt>[UIDevice currentDevice] identifierForVendor]</tt> returns \c nil, a zero UUID is
/// set for the key "id_for_vendor".
NSDictionary *INTAloomaJSONSerializationErrorEvent(NSDictionary *event,
                                                   UIDevice *device = [UIDevice currentDevice]);

/// Logs events to an Alooma service endpoint. Events are supported under specific conditions:
/// 1. If \c shouldWhitelistEvents is \c NO then \c NSDictionary instances containing an \c NSString
/// in the key "event" are supported.
/// 2. If \c shouldWhitelistEvents is \c YES then \c NSDictionary instances having a value in the
/// "event" key that is in \c whitelistedEvents are supported.
///
/// If the event is not json serializable, then a dictionary resulting in
/// \c INTAloomaJSONSerializationErrorEvent is sent to Alooma.
@interface INTAloomaLogger : NSObject <INTEventLogger>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a default \c aloomaRecorder, containing the given \c apiToken, \c flushInterval
/// and \c application. \c flushInterval marks the minimal time between two consecutive data
/// submits. \c whitelistedEvents contains the events that should be supported if
/// \c shouldWhitelistEvents is YES.
///
/// @attention \c nil application would disables background event flushing of \c aloomaRecorder.
/// @see -[Alooma flushInterval]
- (instancetype)initWithAPIToken:(NSString *)apiToken flushInterval:(NSUInteger)flushInterval
                     application:(nullable UIApplication *)application
               whitelistedEvents:(NSSet<NSString *> *)whitelistedEvents;

/// Initializes with the given \c aloomaRecorder and \c mandatoryEvents. \c aloomaRecorder is used
/// for recording events into the Alooma service. \c whitelistedEvents contains the events that
/// should be supported if \c shouldWhitelistEvents is YES.
- (instancetype)initWithAlooma:(Alooma *)aloomaRecorder
             whitelistedEvents:(NSSet<NSString *> *)whitelistedEvents NS_DESIGNATED_INITIALIZER;

/// \c YES if only mandatory events sould be supported, \c NO otherwise. Defaults to \c NO.
@property (atomic) BOOL shouldWhitelistEvents;

@end

NS_ASSUME_NONNULL_END
