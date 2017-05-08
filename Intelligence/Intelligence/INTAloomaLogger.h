// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTEventLogger.h"

NS_ASSUME_NONNULL_BEGIN

@class Alooma;

/// Logs events to an Alooma service endpoint. The current supported events are of
/// \c INTAnalytricksEvent class.
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
