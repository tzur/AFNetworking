// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPRequest.h"

NS_ASSUME_NONNULL_BEGIN

/// Aggregates configuration parameters that are directly tied to HTTP request marshalling.
///
/// @see FBRHTTPSessionConfiguration, FBRHTTPSession.
@interface FBRHTTPSessionRequestMarshalling : NSObject <NSCopying>

/// Initializes the receiver with the default properties.
- (instancetype)init;

/// Initializes the receiver with the given parameters.
///
/// @param parametersEncoding determines how to encode request parameters.
/// @param baseURL an optional base URL for new requests made by the session.
/// @param headers an optional set of HTTP headers to add to new requests made by the session.
- (instancetype)initWithParametersEncoding:(FBRHTTPRequestParametersEncoding *)parametersEncoding
                                   baseURL:(nullable NSURL *)baseURL
                                   headers:(nullable FBRHTTPRequestHeaders *)headers
    NS_DESIGNATED_INITIALIZER;

/// HTTP request parameters encoding to use. The default value is
/// \c FBRHTTPRequestParametersEncodingURLQuery.
@property (readonly, nonatomic) FBRHTTPRequestParametersEncoding *parametersEncoding;

/// Base URL to be used as prefix for requests URLs or \c nil if no base URL should be used. The
/// default value is \c nil.
@property (readonly, nonatomic, nullable) NSURL *baseURL;

/// Additional header fields to add to HTTP requests. The default value is \c nil.
@property (readonly, nonatomic, nullable) FBRHTTPRequestHeaders *headers;

@end

NS_ASSUME_NONNULL_END
