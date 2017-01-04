// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <AFNetworking/AFNetworking.h>

#import "FBRHTTPRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPSessionConfiguration, FBRHTTPSessionRequestMarshalling, FBRHTTPSessionSecurityPolicy;

#pragma mark -
#pragma mark AFSecurityPolicy+Fiber
#pragma mark -

/// Adds convenience methods to create \c AFSecurityPolicy with a \c FBRHTTPSessionSecurityPolicy.
@interface AFSecurityPolicy (Fiber)

/// Creates and returns a new \c AFSecurityPolicy based on the given Fiber \c securityPolicy.
+ (instancetype)fbr_securityPolicyWithFiberSecurityPolicy:
    (FBRHTTPSessionSecurityPolicy *)securityPolicy;

@end

#pragma mark -
#pragma mark AFHTTPRequestSerializer+Fiber
#pragma mark -

/// Adds convenience methods to build and use \c AFHTTPRequestSerializer using Fiber objects.
@interface AFHTTPRequestSerializer (Fiber)

/// Creates and returns a new request serializer that encodes request parameters and HTTP headers
/// according to the parameters specified in the given \c requestMarhsalling.
+ (AFHTTPRequestSerializer *)fbr_serializerWithFiberRequestMarshalling:
    (FBRHTTPSessionRequestMarshalling *)requestMarhsalling;

/// Creates and returns a serializer for the specified \c request.
///
/// The serializer type is based on the \c parametersEncoding property of the request. If the
/// request contains custom \c headers they will be embedded in the returned serializer. If no
/// special serialization is required for the request, i.e. \c parametersEncoding is \c nil, then
/// the \c defaultSerializer is returned. In case \c defaultSerializer is adequate for serializing
/// the request and the request specifies custom headers, a copy of the \c defaultSerializer is made
/// before embedding the custom headers.
///
/// @note If the request specifies custom headers they will override the default headers that are
/// added by the serializer.
+ (AFHTTPRequestSerializer *)fbr_serializerForRequest:(FBRHTTPRequest *)request
                                withDefaultSerializer:(AFHTTPRequestSerializer *)defaultSerializer;

/// Serializes the given \c request into an \c NSURLRequest. If an error occurs during the
/// serialization it will reported via the \c error argument, given that it is not \c nil. 
- (nullable NSURLRequest *)fbr_serializedRequestWithRequest:(FBRHTTPRequest *)request
                                                      error:(NSError * _Nullable *)error;

@end

#pragma mark -
#pragma mark AFHTTPSessionManager+Fiber
#pragma mark -

/// Adds convenience methods to create \c AFHTTPSessionManager with \c FBRHTTPSessionConfiguration.
@interface AFHTTPSessionManager (Fiber)

/// Creates and returns a new HTTP session manager with the given \c baseURL and Fiber
/// \c configuration.
///
/// @note If \c configuration specifies a security policy that requires SSL pinning \c baseURL must
/// be an HTTPS URL.
+ (instancetype)fbr_sessionManagerWithBaseURL:(nullable NSURL *)baseURL
                           fiberConfiguration:(FBRHTTPSessionConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
