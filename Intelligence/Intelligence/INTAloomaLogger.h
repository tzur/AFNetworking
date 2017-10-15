// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTEventLogger.h"

NS_ASSUME_NONNULL_BEGIN

@class Alooma;

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

/// Logs events to an Alooma service endpoint. The current supported events are \c NSDictionary
/// instances containing an \c NSString in the key "event". If the event is not json serializable,
/// then a dictionary resulting in \c INTAloomaJSONSerializationErrorEvent is sent to Alooma.
@interface INTAloomaLogger : NSObject <INTEventLogger>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a default \c aloomaRecorder, containing the given \c apiToken, \c flushInterval
/// and \c application. \c flushInterval marks the minimal time between two consecutive data
/// submits.
///
/// @attention \c nil application would disables background event flushing of \c aloomaRecorder.
/// @see -[Alooma flushInterval]
- (instancetype)initWithAPIToken:(NSString *)apiToken flushInterval:(NSUInteger)flushInterval
                     application:(nullable UIApplication *)application;

/// Initializes with the given \c aloomaRecorder. \c Alooma recorder is used for recording events
/// into the Alooma service.
- (instancetype)initWithAlooma:(Alooma *)aloomaRecorder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
