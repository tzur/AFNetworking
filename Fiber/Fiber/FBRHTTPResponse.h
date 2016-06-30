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

NS_ASSUME_NONNULL_END
