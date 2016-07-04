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
/// @param headers an optional set of HTTP headers to add to new requests made by the session.
- (instancetype)initWithParametersEncoding:(FBRHTTPRequestParametersEncoding *)parametersEncoding
                                   headers:(nullable FBRHTTPRequestHeaders *)headers
    NS_DESIGNATED_INITIALIZER;

/// HTTP request parameters encoding to use. The default value is
/// \c FBRHTTPRequestParametersEncodingURLQuery.
@property (readonly, nonatomic) FBRHTTPRequestParametersEncoding *parametersEncoding;

/// Additional header fields to add to HTTP requests. The default value is \c nil.
@property (readonly, nonatomic, nullable) FBRHTTPRequestHeaders *headers;

@end

NS_ASSUME_NONNULL_END
