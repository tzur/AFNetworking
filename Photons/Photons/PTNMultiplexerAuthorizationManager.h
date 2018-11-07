// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAuthorizationManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Mapping between an \c NSURL scheme and a \c PTNAuthorizationManager that corresponds to that
/// scheme.
typedef NSDictionary<NSString *, id<PTNAuthorizationManager>> PTNSchemeToAuthorizerMap;

/// Asset manager that backs and multiplexes several \c PTNAuthorizationManager objects.
/// Multiplexing is done according to URL schemes. Any authorization requests to the receiver are
/// forwarded to one of the internal authorization managers according to the given \c mapping.
/// Unsupported schemes will return an erroneous signal with the
/// \c PTNErrorCodeUnrecognizedURLScheme error code.
@interface PTNMultiplexerAuthorizationManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c sourceMapping as a mapping between URL schemes and the
/// \c PTNAuthorizationManager instances that correspond to them. Requests to the receiver are
/// multiplexed between the managers according to the given mapping.
- (instancetype)initWithSourceMapping:(PTNSchemeToAuthorizerMap *)sourceMapping
    NS_DESIGNATED_INITIALIZER;

/// Initializes with \c sourceMapping as a mapping between URL schemes and the
/// \c PTNAuthorizationManager instances that correspond to them. These are appended to the schemes
/// in \c authorizedSchemes. The schemes in \c authorizedSchemes are paired with a
/// \c PTNAuthorizationManager instance representing an already authorized source, simulating
/// authorized status for all requests and not supporting authorization revocation.
///
/// @see initWithSources:.
- (instancetype)initWithSourceMapping:(PTNSchemeToAuthorizerMap *)sourceMapping
                    authorizedSchemes:(NSArray<NSString *> *)authorizedSchemes;

/// Requests authorization from the Photons source corresponding to \c scheme in receiver's
/// \c mapping using \c viewController. Calling this method may present a user interface, made by
/// the source, on top of \c viewController or open a source related application if such exists. The
/// returned signal will send a single \c PTNAuthorizationStatus corresponding to the new status
/// and complete or err if the authorization process has been prematurely terminated.
///
/// The signal operates on an arbitrary thread.
- (RACSignal<PTNAuthorizationStatus *> *)
    requestAuthorizationForScheme:(NSString *)scheme
    fromViewController:(UIViewController *)viewController;

/// Revokes authorization from the Photons source corresponding to \c scheme in the receiver's
/// \c mapping, returning the \c authorizationStatus to \c PTNAuthorizationStatusNotDetermined. The
/// returned signal will complete on successful revocation and err if the revocation has been
/// failed.
///
/// The signal will complete or err on an arbitrary thread.
///
/// @note If the underlying authorization manager corresponding to \c scheme doesn't implement
/// \c -revokeAuthorization the returned signal will err with the
/// \c PTNErrorCodeUnrecognizedURLScheme error code.
///
/// @return <tt>RACSignal<></tt>.
- (RACSignal *)revokeAuthorizationForScheme:(NSString *)scheme;

/// Returns a signal sending the current authorization status of the Photons source corresponding to
/// \c scheme, followed by any updates to that authorization status or errs with
/// \c PTNErrorCodeUnrecognizedURLScheme error code if \c scheme does not correspond to any of the
/// receiver's underlying \c PTNAuthorizationManager objects.
- (RACSignal<PTNAuthorizationStatus *> *)authorizationStatusForScheme:(NSString *)scheme;

/// Mapping between \c NSURL schemes this manager supports and the \c PTNAuthorizationManager that
/// handles them.
@property (readonly, nonatomic) PTNSchemeToAuthorizerMap *sourceMapping;

@end

NS_ASSUME_NONNULL_END
