// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class PTNAuthorizationStatus;

/// Implemented by objects that handle authorization for a specific Photons source if that source
/// requires authorization to access its data.
@protocol PTNAuthorizationManager <NSObject>

/// Requests authorization from this source using \c viewController. Calling this method may present
/// a user interface, made by the source, on top of \c viewController or open a source related
/// application if such exists. The returned signal will send a single \c PTNAuthorizationStatus
/// corresponding to the new authorization status and complete. If the authorization process has
/// been prematurely terminated the signal will err with an appropriate error.
///
/// The signal operates or errs on an arbitrary thread.
- (RACSignal<PTNAuthorizationStatus *> *)
    requestAuthorizationFromViewController:(UIViewController *)viewController;

@optional

/// Revokes authorization from this source, returning the \c authorizationStatus to
/// \c PTNAuthorizationStatusNotDetermined. The returned signal will complete on successful
/// revocation and err if the revocation request failed.
///
/// The signal operates or errs on an arbitrary thread.
///
/// @return <tt>RACSignal<></tt>.
- (RACSignal *)revokeAuthorization;

@required

/// Current authorization status of this source. This property is KVO compliant, but will only
/// update according to authorization requests made by the receiver and on an arbitrary thread.
@property (readonly, nonatomic) PTNAuthorizationStatus *authorizationStatus;

@end

NS_ASSUME_NONNULL_END
