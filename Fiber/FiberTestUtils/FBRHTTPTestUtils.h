// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <Fiber/FBRHTTPRequest.h>

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPResponse;

/// Returns a fake \c FBRHTTPResponse with the given properites. \c requestURL, \c statusCode,
/// and \c headers parameters will be used as the properties of the response \c metadata and the
/// \c content parameter will be set as the response \c content property.
FBRHTTPResponse *FBRFakeHTTPResponse(NSString *requestURL, NSUInteger statusCode = 200,
                                     FBRHTTPRequestHeaders * _Nullable headers = nil,
                                     NSData * _Nullable content = nil);

NS_ASSUME_NONNULL_END
