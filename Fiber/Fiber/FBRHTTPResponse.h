// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Contains raw data as received by an HTTP in response to some HTTP request.
@interface FBRHTTPResponse : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver with the specified \c metadata and \c content
- (instancetype)initWithMetadata:(NSHTTPURLResponse *)metadata content:(nullable NSData *)content
    NS_DESIGNATED_INITIALIZER;

/// Response metadata.
@property (readonly, nonatomic) NSHTTPURLResponse *metadata;

/// Content of the HTTP response or \c nil if the server response contained no data.
@property (readonly, nonatomic, nullable) NSData *content;

@end

/// Adds JSON deserialization helper methods.
@interface FBRHTTPResponse (JSONDeserialization)

/// Try to deserialize the response \c content into a JSON object. The returned object can be either
/// an \c NSDictionary or \c NSArray (meaning this does not supports multi-part responses containing
/// partial JSON data). In case of an error during the deserialization or if the response has no
/// content \c nil is returned and \c error will be filled with appropriate error information. For
/// any error that occurs the error code will be \c FBRErrorCodeJSONDeserializationFailed and it
/// also may contain an underlying error depending on the cause.
- (nullable id)deserializeJSONContentWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
