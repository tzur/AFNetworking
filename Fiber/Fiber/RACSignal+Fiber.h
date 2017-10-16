// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPResponse;

@interface RACSignal (Fiber)

/// Skips incomplete task progress values and deserializes JSON object from completed task progress
/// values.
///
/// The receiver is assumed to send a sequence of zero or more incomplete
/// \c LTProgress<FBRHTTPResponse> values followed by a completed progress value.
///
/// The returned signal sends JSON objects deserialized from the received values \c content data.
/// It completes when the receiver completes or errs if the receiver errs. It will also err if the
/// a response object contains non-JSON content.
///
/// @return <tt>RACSignal<JSONObject></tt> where \c JSONObject may be \c NSDictionary or \c NSArray.
- (RACSignal *)fbr_deserializeJSON;

/// Skips incomplete task progress values.
///
/// The receiver is assumed to send a sequence of zero or more \c LTProgress<FBRHTTPResponse> values
/// followed by a single completed progress value.
///
/// The returned signal sends \c FBRHTTPResponse values when the receiver sends a completed
/// \c LTProgress object. It completes or errs when the receiver completes or errs respectively.
///
/// @return <tt>RACSignal<FBRHTTPResponse></tt>
- (RACSignal<FBRHTTPResponse *> *)fbr_skipProgress;

@end

NS_ASSUME_NONNULL_END
