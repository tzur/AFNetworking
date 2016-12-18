// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPSessionConfiguration;

/// Protocol for providing \c FBRHTTPSessionConfiguration.
@protocol FBRHTTPSessionConfigurationProvider <NSObject>

/// Returns an HTTP session configuration, which contains configuration that is vital for an HTTP
/// session.
- (FBRHTTPSessionConfiguration *)HTTPSessionConfiguration;

@end

NS_ASSUME_NONNULL_END
