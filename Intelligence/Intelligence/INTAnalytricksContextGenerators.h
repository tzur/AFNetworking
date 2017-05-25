// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDataStructures.h"

NS_ASSUME_NONNULL_BEGIN

/// Key for an \c INTAnalytricksContext. Applicable in an \c INTAppContext only after an app launch.
extern NSString * const kINTAppContextAnalytricksContextKey;

/// Key for an \c NSUUID, uniquely identifying the current device. Applicable in an
/// \c INTAppContext.
extern NSString * const kINTAppContextDeviceIDKey;

/// Key for an \c NSUUID, uniquely identifying the current device configuration revision, as defined
/// by Lightricks backend and \c INTAnalytricksMetadata. Applicable in an \c INTAppContext.
extern NSString * const kINTAppContextDeviceInfoIDKey;

/// Static class of \c INTAppContextGeneratorBlock blocks for Lightricks shared events
/// (a.k.a Analytricks) events transformation pipeline.
@interface INTAnalytricksContextGenerators : NSObject

/// Context generator that generates an \c INTAppContext with an updated value in
/// \c kINTAppContextAnalytricksContextKey. The updates to the \c INTAnalytricksContext are made
/// when the following events are processed:
///
/// 1. INTAppWillForegroundEvent -
///    a. If \c isLaunch is \c YES, then a new \c INTAnalytricksContext is generated, having only
///    \c appRunID and \c sessionID set to a uniquely generated \c NSUUID for each.
///    b. If \c isLaunch is \c NO, \c sessionID is set to a uniquely generated \c NSUUID.
/// 2. INTScreenDisplayedEvent - the \c screenUsageID is set to a new value, and \c screenName is
///    set to the <tt>-[INTScreenDisplayedEvent screenName]</tt>.
/// 3. INTProjectLoadedEvent - the \c openProjectID is set to
///    <tt>-[INTProjectLoadedEvent openProjectID]</tt>.
/// 3. INTProjectClosedEvent - the \c openProjectID is set \c nil.
///
/// @attention for options {1a, 2, 3, 4} updates are made only if the input \c context has a
/// value for \c kINTAppContextAnalytricksContextKey.
+ (INTAppContextGeneratorBlock)analytricksContextGenerator;

/// Returns a context generator that generates an \c INTAppcontext with an updated values in
/// \c kINTAppContextDeviceIDKey and \c kINTAppContextDeviceInfoIDKey when an
/// \c INTDeviceInfoLoadedEvent is observed. \c kINTAppContextDeviceIDKey is set to the
/// \c identifierForVendor property of the loaded \c INTDeviceInfo. \c kINTAppContextDeviceInfoIDKey
/// is set to the \c deviceInfoRevisionID property of the event.
+ (INTAppContextGeneratorBlock)deviceInfoContextGenerator;

@end

NS_ASSUME_NONNULL_END
