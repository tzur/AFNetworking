// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <Fiber/FBRHTTPClient.h>

NS_ASSUME_NONNULL_BEGIN

/// Adds methods to easily create an HTTP client for receipt validation using Validatricks server.
@interface FBRHTTPClient (Validatricks)

/// Name of the HTTP header used as API key in requests. 
+ (NSString *)bzr_validatricksAPIKeyHeaderName;

/// Creates a new HTTP client with \c serverURL as its base URL. If \c APIKey is not \c nil it will
/// be added as the value for \c 'x-api-key' HTTP header to every request sent by this client. If
/// \c pinnedCertificates is not \c nil the client will use a secured session using SSL certificate
/// pinning - that is the session will block communication with the server in case the server's SSL
/// certificate does not match one of the pinned certificates.
///
/// @note The underlying session is configured to not cache server responses.
+ (instancetype)bzr_validatricksClientWithServerURL:(NSURL *)serverURL
                                             APIKey:(nullable NSString *)APIKey
                                 pinnedCertificates:(nullable NSSet<NSData *> *)pinnedCertificates;

@end

NS_ASSUME_NONNULL_END
