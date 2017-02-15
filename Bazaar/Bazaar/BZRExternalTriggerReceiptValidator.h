// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BZRReceiptValidationStatusProvider;

/// Validator that once activated with a trigger signal initiates receipt validation whenever the
/// trigger signal fires.
///
/// The validator conforms to \c BZREventEmitter and reports on valdation errors thrgouh the
/// \c eventsSignal.
@interface BZRExternalTriggerReceiptValidator : NSObject <BZREventEmitter>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c validationStatusProvider, used to fetch receipt validation status.
- (instancetype)initWithValidationStatusProvider:
    (id<BZRReceiptValidationStatusProvider>)validationStatusProvider NS_DESIGNATED_INITIALIZER;

/// Activates the validator with the given \c triggerSignal. The receiver will immediately subscribe
/// to \c triggerSignal and will call \c fetchReceiptValidationStatus: on the
/// \c BZRReceiptValidationStatusProvider instance provided on initialization whenever
/// \c triggerSignal fires.
///
/// @note If the receiver is already activated it will be deactivated and then reactivated with the
/// new \c triggerSignal.
/// @note Errors in receipt validation will be provided via the \c eventsSignal and they will not
/// deactivate the receiver.
/// @note The receiver will be deactivated on deallocation.
- (void)activateWithTrigger:(RACSignal *)triggerSignal;

/// Deactivates the validator, i.e. values sent on the trigger signal after deactivation will not
/// trigger receipt validation.
///
/// @note If the receiver is not activated this method has no effect.
- (void)deactivate;

@end

NS_ASSUME_NONNULL_END
