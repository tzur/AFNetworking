// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPSessionRequestMarshalling, FBRHTTPSessionSecurityPolicy;

#pragma mark -
#pragma mark FBRHTTPSessionConfiguration
#pragma mark -

/// Configuration object for \c FBRHTTPSession.
///
/// @see FBRHTTPSession, NSURLSessionConfiguration.
@interface FBRHTTPSessionConfiguration : NSObject <NSCopying>

/// Initializes the session configuration with default parameters.
///
/// \c sessionConfiguration will be the default session configuration as provided by
/// \c +[NSURLSessionConfiguration defaultSessionConfiguration].
///
/// \c requestMarshalling will be set to the default request marshalling configuration as provided
/// by \c -[FBRHTTPSessionRequestMarshalling init].
///
/// \c securityPolicy will be set to the default security policy as provided by
/// \c -[FBRHTTPSessionSecurityPolicy standardSecurityPolicy].
- (instancetype)init;

/// Initializes the configuration object with the specified \c sessionConfiguration,
/// \c requestMarshalling and \c securityPolicy.
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
                          requestMarshalling:(FBRHTTPSessionRequestMarshalling *)requestMarshalling
                              securityPolicy:(FBRHTTPSessionSecurityPolicy *)securityPolicy;

/// HTTP session configuration.
@property (readonly, nonatomic) NSURLSessionConfiguration *sessionConfiguration;

/// HTTP session request marshalling configuration.
@property (readonly, nonatomic) FBRHTTPSessionRequestMarshalling *requestMarshalling;

/// HTTP session security policy.
@property (readonly, nonatomic) FBRHTTPSessionSecurityPolicy *securityPolicy;

@end

NS_ASSUME_NONNULL_END
