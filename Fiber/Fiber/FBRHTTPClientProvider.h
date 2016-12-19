// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPClient;

/// Protocol for providing HTTP clients.
@protocol FBRHTTPClientProvider <NSObject>

/// Creates a new \c FBRHTTPClient which is used to make HTTP requests.
- (FBRHTTPClient *)HTTPClient;

@end

NS_ASSUME_NONNULL_END
