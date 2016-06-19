// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@interface FBRHTTPSessionConfiguration;

/// Represents a set of parameters that can be appended to an HTTP request. The dictionary keys and
/// values are treated as parameters names and their values respectively. Parameters values must
/// serializable according to the request encoding applied by the session.
///
/// @see FBRHTTPRequestEncoding.
typedef NSDictionary<NSString *, NSObject *> FBRHTTPRequestParameters;

/// \c FBRHTTPSession encapsulates an HTTP session and allows easy customization of some session
/// parameters such as SSL pinning, caching, serialization and more. A session object is initialized
/// with a \c FBRHTTPSessionConfiguration which specifies configuration parameters for the session.
///
/// @note Two HTTP headers are added to each HTTP requests regardless of whether they are specified
/// in the session configuration. These are the 'Accept-Languages' and 'User-Agent' headers. The
/// values for these headers can be overridden by the configuration but they can not be removed.
///
/// @see FBRHTTPSessionConfiguration, NSURLSession
@interface FBRHTTPSession : NSObject

/// Initializes the session with default configuration as returned by
/// \c -[FBRHTTPSessionConfiguration init].
- (instancetype)init;

/// Initializes the session with the given \c configuration.
- (instancetype)initWithConfiguration:(FBRHTTPSessionConfiguration *)configuration
    NS_DESIGNATED_INITIALIZER;

/// Initiates a GET request to the URL specified by \c URLString prefixed by the receiver's
/// \c baseURL. If \c parameters are specified they will be serialized and sent as part of the
/// request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progress until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range \c [200, 299]).
/// Values and errors are delivered on the main queue.
///
/// @see FBRHTTPRequestParameters, FBRHTTPSessionRequestConfiguration.
- (RACSignal *)GET:(NSString *)URLString
    withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Initiates a HEAD request to the URL specified by \c URLString prefixed by the receiver's
/// \c baseURL. If \c parameters are specified they will be serialized and sent as part of the
/// request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progress until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range \c [200, 299]).
/// Values and errors are delivered on the main queue.
///
/// @see FBRHTTPRequestParameters, FBRHTTPSessionRequestConfiguration.
- (RACSignal *)HEAD:(NSString *)URLString
     withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Initiates a POST request to the URL specified by \c URLString prefixed by the receiver's
/// \c baseURL. If \c parameters are specified they will be serialized and sent as part of the
/// request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progress until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range \c [200, 299]).
/// Values and errors are delivered on the main queue.
///
/// @see FBRHTTPRequestParameters, FBRHTTPSessionRequestConfiguration.
- (RACSignal *)POST:(NSString *)URLString
     withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Initiates a PUT request to the URL specified by \c URLString prefixed by the receiver's
/// \c baseURL. If \c parameters are specified they will be serialized and sent as part of the
/// request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progress until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range \c [200, 299]).
/// Values and errors are delivered on the main queue.
///
/// @see FBRHTTPRequestParameters, FBRHTTPSessionRequestConfiguration.
- (RACSignal *)PUT:(NSString *)URLString
    withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Initiates a PATCH request to the URL specified by \c URLString prefixed by the receiver's
/// \c baseURL. If \c parameters are specified they will be serialized and sent as part of the
/// request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progress until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range \c [200, 299]).
/// Values and errors are delivered on the main queue.
///
/// @see FBRHTTPRequestParameters, FBRHTTPSessionRequestConfiguration.
- (RACSignal *)PATCH:(NSString *)URLString
      withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Initiates a DELETE request to the URL specified by \c URLString prefixed by the receiver's
/// \c baseURL. If \c parameters are specified they will be serialized and sent as part of the
/// request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progress until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range \c [200, 299]).
/// Values and errors are delivered on the main queue.
///
/// @see FBRHTTPRequestParameters, FBRHTTPSessionRequestConfiguration.
- (RACSignal *)DELETE:(NSString *)URLString
       withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Session configuration.
@property (readonly, nonatomic) id<FBRHTTPSessionConfiguration> configuration;

@end

NS_ASSUME_NONNULL_END
