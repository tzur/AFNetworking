// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPSessionConfiguration;
@protocol FBRHTTPSession;

/// \c FBRHTTPClient is a wrapper object for \c FBRHTTPSession. It provides convenience reactive
/// interface for HTTP clients.
///
/// @see FBRHTTPRequest, FBRHTTPSession, FBRHTTPSessionCofniguration.
@interface FBRHTTPClient : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Creates a new HTTP client using the default HTTP session implementation. The unserlying session
/// is initialized with the configuration provided by \c -[FBRHTTPSessionConfiguration init].
+ (instancetype)client;

/// Creates a new HTTP client using the default HTTP session implementation. The underlying session
/// is initialized with the given \c configuration. If \c baseURL is not \c nil it will be used as
/// prefix URL for all HTTP requests issued by this client.
///
/// @see -[FBRHTTPClient initWithSession:baseURL:].
+ (instancetype)clientWithSessionConfiguration:(FBRHTTPSessionConfiguration *)configuration
                                       baseURL:(nullable NSURL *)baseURL;


/// Initializes the receiver with a custom underlying HTTP \c session. If \c baseURL is not \c nil
/// it will be used as prefix URL for all HTTP requests issued by this client. \c baseURL must not
/// specify \c fragment or \c query string, if either is present an \c NSInvalidArgumentException
/// is raised.
- (instancetype)initWithSession:(id<FBRHTTPSession>)session baseURL:(nullable NSURL *)baseURL
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

/// Underlying HTTP session.
@property (readonly, nonatomic) id<FBRHTTPSession> session;

/// Base URL used as prefix for requests made by this client.
@property (readonly, nonatomic, nullable) NSURL *baseURL;

@end

NS_ASSUME_NONNULL_END
