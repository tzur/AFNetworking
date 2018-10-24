// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <Fiber/FBRHTTPSessionConfigurationProvider.h>

NS_ASSUME_NONNULL_BEGIN

/// Provider that provides HTTP session configuration for Validatricks clients.
@interface BZRValidatricksSessionConfigurationProvider:
    NSObject <FBRHTTPSessionConfigurationProvider>

/// Name of the HTTP header used as API key in requests.
+ (NSString *)validatricksAPIKeyHeaderName;

/// Initializes the provider with the default API key and pinned with the default Lightricks' SSL
/// certificates.
- (instancetype)init;

/// Initializes with \c APIKey that if not \c nil is added as the value for \c 'x-api-key' HTTP
/// header to every session configuration created. If \c pinnedCertificates is not \c nil the
/// created session configurations will set session security policy to use SSL certificate pinning
/// using these certificates. If \c pinnedCertificates is \c nil the standard security policy will
/// be used.
///
/// @see FBRHTTPSessionSecurityPloicy.
/// @note Configurations provided by this provider prohibits caching.
- (instancetype)initWithAPIKey:(nullable NSString *)APIKey
            pinnedCertificates:(nullable NSSet<NSData *> *)pinnedCertificates
    NS_DESIGNATED_INITIALIZER;

/// API key used for identification with Validatricks server.
@property (readonly, nonatomic, nullable) NSString *APIKey;

@end

NS_ASSUME_NONNULL_END
