// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPSessionConfiguration;

@protocol FBRHTTPSession;

/// Wrapper object for \c FBRHTTPSession providing convenience reactive interface for making HTTP
/// requests.
///
/// @see FBRHTTPRequest, FBRHTTPSession, FBRHTTPSessionConfiguration.
@interface FBRHTTPClient : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Creates a new HTTP client using the default \c FBRHTTPSession implementation. The underlying
/// session is initialized with the configuration provided by
/// \c -[FBRHTTPSessionConfiguration init].
+ (instancetype)client;

/// Creates a new HTTP client using the default \c FBRHTTPSession implementation. The underlying
/// session is initialized with the given \c configuration. If \c baseURL is not \c nil it will be
/// used as prefix URL for all HTTP requests issued by this client.
+ (instancetype)clientWithSessionConfiguration:(FBRHTTPSessionConfiguration *)configuration
                                       baseURL:(nullable NSURL *)baseURL;

/// Initializes the receiver with a custom underlying HTTP \c session. If \c baseURL is not \c nil
/// it will be used as prefix URL for all HTTP requests issued by this client. \c baseURL must not
/// specify \c fragment or \c query string, if either is present or if the \c scheme of the URL
/// is not 'http' nor 'https' an \c NSInvalidArgumentException is raised.
- (instancetype)initWithSession:(id<FBRHTTPSession>)session baseURL:(nullable NSURL *)baseURL
    NS_DESIGNATED_INITIALIZER;

/// Initiates a GET request to the URL specified by \c URLString composed as relative path to the
/// client's \c baseURL. If \c parameters are specified they will be serialized and sent as part of
/// the request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progresses until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range
/// <tt>[200, 299]</tt>). Values and errors are delivered on the main queue.
- (RACSignal *)GET:(NSString *)URLString
    withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Initiates a HEAD request to the URL specified by \c URLString composed as relative path to the
/// client's \c baseURL. If \c parameters are specified they will be serialized and sent as part of
/// the request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progresses until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range
/// <tt>[200, 299]</tt>). Values and errors are delivered on the main queue.
- (RACSignal *)HEAD:(NSString *)URLString
     withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Initiates a POST request to the URL specified by \c URLString composed as relative path to the
/// client's \c baseURL. If \c parameters are specified they will be serialized and sent as part of
/// the request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progresses until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range
/// <tt>[200, 299]</tt>). Values and errors are delivered on the main queue.
- (RACSignal *)POST:(NSString *)URLString
     withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Initiates a PUT request to the URL specified by \c URLString composed as relative path to the
/// client's \c baseURL. If \c parameters are specified they will be serialized and sent as part of
/// the request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progresses until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range
/// <tt>[200, 299]</tt>). Values and errors are delivered on the main queue.
- (RACSignal *)PUT:(NSString *)URLString
    withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Initiates a PATCH request to the URL specified by \c URLString composed as relative path to the
/// client's \c baseURL. If \c parameters are specified they will be serialized and sent as part of
/// the request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progresses until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range
/// <tt>[200, 299]</tt>). Values and errors are delivered on the main queue.
- (RACSignal *)PATCH:(NSString *)URLString
      withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Initiates a DELETE request to the URL specified by \c URLString composed as relative path to the
/// client's \c baseURL. If \c parameters are specified they will be serialized and sent as part of
/// the request.
///
/// @return <tt>RACSignal<FBRHTTPTaskProgress *></tt>. The signal sends the request on subscription,
/// and delivers a sequence of \c FBRHTTPTaskProgress objects representing the task status as it
/// progresses until it completes. When the task completes the server response body is delivered
/// wrapped in an \c FBRHTTPTaskProgress object. The signal errs if a communication error occurs or
/// if the server response indicates an error (i.e. status code not in the range
/// <tt>[200, 299]</tt>). Values and errors are delivered on the main queue.
- (RACSignal *)DELETE:(NSString *)URLString
       withParameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Underlying HTTP session.
@property (readonly, nonatomic) id<FBRHTTPSession> session;

/// Base URL used as prefix for requests made by this client or \c nil if no base URL is used.
@property (readonly, nonatomic, nullable) NSURL *baseURL;

@end

NS_ASSUME_NONNULL_END
