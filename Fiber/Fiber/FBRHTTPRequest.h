// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark FBRHTTPRequestMethod
#pragma mark -

/// Enumerates the supported HTTP/1.1 request methods.
LTEnumDeclare(NSUInteger, FBRHTTPRequestMethod,
  /// HTTP 'GET' method.
  FBRHTTPRequestMethodGet,
  /// HTTP 'HEAD' method.
  FBRHTTPRequestMethodHead,
  /// HTTP 'POST' method.
  FBRHTTPRequestMethodPost,
  /// HTTP 'PUT' method.
  FBRHTTPRequestMethodPut,
  /// HTTP 'PATCH' method.
  FBRHTTPRequestMethodPatch,
  /// HTTP 'DELETE' method.
  FBRHTTPRequestMethodDelete
);

/// Provides the HTTP method as a string that can be embedded inside an HTTP request.
@interface FBRHTTPRequestMethod (Fiber)

/// HTTP method in string representation.
@property (readonly, nonatomic) NSString *HTTPMethod;

/// \c YES if this request downloads data from the server.
@property (readonly, nonatomic) BOOL downloadsData;

/// \c YES if this request uploads data to the server.
@property (readonly, nonatomic) BOOL uploadsData;

@end

#pragma mark -
#pragma mark FBRHTTPRequestParameters
#pragma mark -

/// Represents a set of parameters that can be appended to an HTTP request. The dictionary keys and
/// values are treated as parameter names and their values respectively. Parameter values must be
/// serializable according to the request encoding used.
///
/// @see FBRHTTPRequestParametersEncoding.
typedef NSDictionary<NSString *, NSObject *> FBRHTTPRequestParameters;

#pragma mark -
#pragma mark FBRHTTPRequestParametersEncoding
#pragma mark -

/// Encoding formats for HTTP request parameters.
///
/// Some HTTP requests make use of additional parameters. These parameters can be transferred in
/// various methods (as part of the request URL or as the body of the request) and can be encoded
/// using various encodings and formats. This enum defines the set of supported encoding formats
/// for HTTP requests parameters.
LTEnumDeclare(NSUInteger, FBRHTTPRequestParametersEncoding,
  /// Specifies URL query encoding using \c %HH escaping. Any object can be encoded with this
  /// encoding method, parameters are converted to strings by using their \c description property.
  ///
  /// When used for 'GET', 'HEAD' and 'DELETE' requests parameters will be encoded as query string
  /// and appended to the request URL. For other requests the query string will be embedded in the
  /// request body.
  FBRHTTPRequestParametersEncodingURLQuery,
  /// Specifies JSON encoding. To use this encoding parameters must be valid JSON objects, i.e.
  /// \c +[NSJSONSerialization isValidJSONObject:] should return \c YES. The rules for JSON
  /// serializable objects is defined in \c NSJSONSerialization documentation.
  ///
  /// When used for 'GET', 'HEAD' and 'DELETE' requests parameters will be encoded using URL query
  /// encoding since it is uncommon to send data as the request body for these type of requests. For
  /// other requests the parameters will be encoded into JSON string and embedded in the request's
  /// body.
  FBRHTTPRequestParametersEncodingJSON
);

#pragma mark -
#pragma mark FBRHTTPRequestHeaders
#pragma mark -

/// Dictionary of HTTP header fields that can be applied to HTTP requests. Keys and their values are
/// used as HTTP headers names and their values respectively.
typedef NSDictionary<NSString *, NSString *> FBRHTTPRequestHeaders;

#pragma mark -
#pragma mark FBRHTTPRequest
#pragma mark -

/// Represents a single HTTP request that can be used to initate an HTTP task. Tasks are initiated
/// by sending a request object to an \c FBRHTTPSession object.
///
/// @see FBRHTTPTaskFetcher.
@interface FBRHTTPRequest : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/// Returns \c YES if \c URL specifies a protocol that is valid for HTTP requests. The supported
/// protocols are `HTTP` and `HTTPS`. The validation is case insensitive.
+ (BOOL)isProtocolSupported:(NSURL *)URL;

/// Initializes an HTTP request to the given \c URL using the given HTTP \c method. No parameters or
/// headers will be added to the request.
///
/// @note If the session used to send this request specifies common headers, these headers will be
/// appended to the request without changing the request object.
- (instancetype)initWithURL:(NSURL *)URL method:(FBRHTTPRequestMethod *)method;

/// Initializes an HTTP request to the given \c URL using the given HTTP \c method. Optional
/// \c parameters can be added to the request. \c parametersEncoding may be specified in order to
/// override the session parameters encoding. \c headers may be specified in order to append
/// additional HTTP headers to the request on top of the common session headers.
- (instancetype)initWithURL:(NSURL *)URL method:(FBRHTTPRequestMethod *)method
                 parameters:(nullable FBRHTTPRequestParameters *)parameters
         parametersEncoding:(nullable FBRHTTPRequestParametersEncoding *)parametersEncoding
                    headers:(nullable FBRHTTPRequestHeaders *)headers
    NS_DESIGNATED_INITIALIZER;

/// URL of the requested resource.
@property (readonly, nonatomic) NSURL *URL;

/// HTTP method to use for this request.
@property (readonly, nonatomic) FBRHTTPRequestMethod *method;

/// Optional parameters to append to the request. The default value is \c nil.
@property (readonly, nonatomic, nullable) FBRHTTPRequestParameters *parameters;

/// Encoding for this request parameters. If \c parameters is \c nil this property is ignored. The
/// default value is \c nil.
@property (readonly, nonatomic, nullable) FBRHTTPRequestParametersEncoding *parametersEncoding;

/// Optional headers to add to the request. The default value is \c nil.
@property (readonly, nonatomic, nullable) FBRHTTPRequestHeaders *headers;

@end

NS_ASSUME_NONNULL_END
