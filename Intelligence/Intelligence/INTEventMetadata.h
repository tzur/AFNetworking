// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Class containing event metadata that is provided with each event that enters the event
/// transformation pipline of Intelligence.
@interface INTEventMetadata : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c totalRunTime, \c foregroundRunTime \c deviceTimestamp and
/// \c eventID. \c totalRunTime is time spent in foreground and background since the app started, at
/// the time the event was created. \c foregroundRunTime is the time spent in foreground since the
/// app started, at the time the event was created. \c deviceTimestamp is the local device date in
/// which the event was created, in UTC timezone. \c eventID uniquely identifies the event.
- (instancetype)initWithTotalRunTime:(NSTimeInterval)totalRunTime
                   foregroundRunTime:(NSTimeInterval)foregroundRunTime
                     deviceTimestamp:(NSDate *)deviceTimestamp eventID:(NSUUID *)eventID
    NS_DESIGNATED_INITIALIZER;

/// Time spent in foreground and background since the app started, at the time the event was
/// created.
@property (readonly, nonatomic) NSTimeInterval totalRunTime;

/// Time spent in foreground since the app started, at the time the event was created.
@property (readonly, nonatomic) NSTimeInterval foregroundRunTime;

/// Local device date in which the event was created, in UTC timezone.
@property (readonly, nonatomic) NSDate *deviceTimestamp;

/// Event unique ID.
@property (readonly, nonatomic) NSUUID *eventID;

@end

/// Returns an \c INTEventMetadata initialized with the given \c totalRunTime, \c foregroundRunTime,
/// \c deviceTimestamp and \c eventID. If \c eventID is \c nil a new \c NSUUID is created. If
/// \c deviceTimestamp is \c nil a new \c NSDate is created.
INTEventMetadata *INTCreateEventMetadata(NSTimeInterval totalRunTime = 0,
                                         NSTimeInterval foregroundRunTime = 0,
                                         NSDate * _Nullable deviceTimestamp = nil,
                                         NSUUID * _Nullable eventID = nil);

NS_ASSUME_NONNULL_END
