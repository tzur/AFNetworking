// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark FBRHTTPRequestEncoding
#pragma mark -

/// Encoding formats for HTTP request parameters.
///
/// Some HTTP requests make use of additional parameters. These parameters can be transferred in
/// various methods (as part of the request URL or as the body of the request) and can be encoded
/// using various encodings and formats. This enum defines the set of supported encoding formats
/// for HTTP requests parameters.
typedef NS_ENUM(NSUInteger, FBRHTTPRequestEncoding) {
  /// Specifies URL query encoding using \c %HH escaping.
  ///
  /// When used for 'GET', 'HEAD' and 'DELETE' requests parameters will be encoded as query string
  /// and appended to the request URL. For other requests the query string will be embedded in the
  /// request body.
  FBRHTTPRequestEncodingURLQuery,
  /// Specifies JSON encoding.
  ///
  /// When used for 'GET', 'HEAD' and 'DELETE' requests parameters will be encoded using URL query
  /// encoding since it is uncommon to send data as the request body for these type of requests. For
  /// other requests the parameters will be encoded into JSON string and embedded in the request's
  /// body.
  FBRHTTPRequestEncodingJSON
};

#pragma mark -
#pragma mark FBRHTTPSessionRequestMarshalling
#pragma mark -

/// Dictionary of HTTP header fields that can be applied to HTTP requests. Keys and their values are
/// used as HTTP headers names and their values respectively.
typedef NSDictionary<NSString *, NSString *> FBRHTTPRequestHeaders;

/// Aggregates configuration parameters that are directly tied to HTTP request marshalling.
///
/// @see FBRHTTPSessionConfiguration, FBRHTTPSession.
@interface FBRHTTPSessionRequestMarshalling : NSObject <NSCopying>

/// Initializes the receiver with the default properties.
- (instancetype)init;

/// Initializes the receiver with the given parameters.
///
/// @param requestEncoding determines how to encode request parameters.
/// @param baseURL an optional base URL for new requests made by the session.
/// @param headers an optional set of HTTP headers to add to new requests made by the session.
- (instancetype)initWithRequestEncoding:(FBRHTTPRequestEncoding)requestEncoding
                                baseURL:(nullable NSURL *)baseURL
                                headers:(nullable FBRHTTPRequestHeaders *)headers
    NS_DESIGNATED_INITIALIZER;

/// HTTP request parameters encoding to use. Default value is \c FBRHTTPRequestEncodingURLQuery.
@property (readonly, nonatomic) FBRHTTPRequestEncoding requestEncoding;

/// Base URL to be used as prefix for requests URLs or \c nil if no base URL should be used. The
/// default value is \c nil.
@property (readonly, nonatomic, nullable) NSURL *baseURL;

/// Additional header fields to add to HTTP requests. The default value is \c nil.
@property (readonly, nonatomic, nullable) FBRHTTPRequestHeaders *headers;

@end

NS_ASSUME_NONNULL_END
