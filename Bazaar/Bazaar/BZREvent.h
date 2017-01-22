// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Possible values for types of events sent by Bazaar.
LTEnumDeclare(NSUInteger, BZREventType,
  BZREventTypeNonCriticalError,
  BZREventTypeCriticalError,
  BZREventTypeReceiptValidationStatusReceived
);

/// Represents a single event that is sent from Bazaar.
@interface BZREvent : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c eventType, \c eventError. \c eventInfo is set to
/// \c nil. \c eventType must be an error event type, i.e., one of \c BZREventTypeNonCriticalError
/// \c BZREventTypeCriticalError.
- (instancetype)initWithType:(BZREventType *)eventType eventError:(NSError *)eventError;

/// Initializes with the given \c eventType, and \c eventInfo. \c eventError is set to \c nil.
/// \c eventType cannot be an error event type, i.e., one of \c BZREventTypeNonCriticalError
/// \c BZREventTypeCriticalError.
- (instancetype)initWithType:(BZREventType *)eventType eventInfo:(NSDictionary *)eventInfo;

/// Type of the event.
@property (readonly, nonatomic) BZREventType *eventType;

/// The error in case the event represents an error. \c nil in case the event doesn't represent an
/// error.
@property (readonly, nonatomic, nullable) NSError *eventError;

/// Additional information of the event. \c nil in case the event represents an error, since the
/// error contains the information in this case.
@property (readonly, nonatomic, nullable) NSDictionary *eventInfo;

@end

NS_ASSUME_NONNULL_END
