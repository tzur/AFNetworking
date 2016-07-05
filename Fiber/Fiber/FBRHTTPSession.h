// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPRequest, FBRHTTPResponse, FBRHTTPSessionConfiguration;

/// \c FBRHTTPSession encapsulates an HTTP session and allows easy customization of some session
/// parameters such as SSL pinning, caching, serialization and more.
@protocol FBRHTTPSession <NSObject>

/// Callback used by \c FBRHTTPSession implementors to report the progress of an HTTP task.
///
/// The \c progress parameter indicates the progress of the task.
typedef void (^FBRHTTPTaskProgressBlock)(NSProgress *progress);

/// Callback used by \c FBRHTTPSession implementors to report successful completion of an HTTP task.
///
/// The \c response parameter contains metadata of the server response and the response's content if
/// the server attached body to the response.
typedef void (^FBRHTTPTaskSuccessBlock)(FBRHTTPResponse *response);

/// Callback used by \c FBRHTTPSession implementors to report an error during the execution of an
/// HTTP task.
///
/// The \c error parameters specifies the error that occurred during task execution.
typedef void (^FBRHTTPTaskFailureBlock)(NSError *error);

/// Initializes the receiver with the given session \c configuration.
- (instancetype)initWithConfiguration:(FBRHTTPSessionConfiguration *)configuration;

/// Initiates and returns a data task for the given HTTP \c request. Returns \c nil if failed to
/// initiate a task, in that case the \c failure block will be invoked with the relevant error.
///
/// If \c progress block is not \c nil, it may be invoked zero or more times during the task's
/// lifetime in order to report task progress. The \c success block is called upon successful
/// completion and the \c failure block is invoked if the task has ended with error or was
/// cancelled.
///
/// @note An HTTP task is considered a successfully completed one if the following conditions are
/// met: 1. the request sent successfully (with no serialization errors, communication errors etc.)
/// and 2. the server response was received with no errors and with status code that indicates a
/// successful processing of the request (i.e. status code in the range <tt>[200, 299]<tt>).
- (nullable NSURLSessionDataTask *)dataTaskWithRequest:(FBRHTTPRequest *)request
                                              progress:(nullable FBRHTTPTaskProgressBlock)progress
                                               success:(FBRHTTPTaskSuccessBlock)success
                                               failure:(FBRHTTPTaskFailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
