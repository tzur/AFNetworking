// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Possible types of authorization request responses.
typedef NS_ENUM(NSUInteger, PTNAuthorizationStatus) {
  /// User has not yet granted or denied access to this source.
  PTNAuthorizationStatusNotDetermined,
  /// User cannot grant such permission.
  PTNAuthorizationStatusRestricted,
  /// User has explicitly denied the app access to this source.
  PTNAuthorizationStatusDenied,
  /// User has explicitly granted the app access to this source.
  PTNAuthorizationStatusAuthorized
};

/// Implemented by objects that handle authorization for a specific Photons source if that source
/// requires authorization to access its data.
@protocol PTNAuthorizationManager <NSObject>

/// Requests authorization from this source using \c viewController. Calling this method may present
/// a user interface, made by the source, on top of \c viewController or open a source related
/// application if such exists. The returned signal will complete when the authorization process has
/// been completed successfully and the authorization has been given or err if the authorization
/// process has been prematurely terminated or authorization has not been given.
///
/// The signal will complete or err on an arbitrary thread.
///
/// @return <tt>RACSignal<></tt>.
- (RACSignal *)requestAuthorizationFromViewController:(UIViewController *)viewController;

@optional

/// Revokes authorization from this source, returning the \c authorizationStatus to
/// \c PTNAuthorizationStatusNotDetermined. The returned signal will complete on successful
/// revocation and err if the revocation has been failed.
///
/// The signal will complete or err on an arbitrary thread.
///
/// @return <tt>RACSignal<></tt>.
- (RACSignal *)revokeAuthorization;

@required

/// Current authorization status of this source.
@property (readonly, nonatomic) PTNAuthorizationStatus authorizationStatus;

@end

NS_ASSUME_NONNULL_END
