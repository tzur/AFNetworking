// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <Fiber/FBRHTTPRequest.h>

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPResponse;

/// Returns a fake \c FBRHTTPResponse with the given properties. \c requestURL, \c statusCode
/// and \c headers parameters will be used as the properties of the response \c metadata and the
/// \c content parameter will be set as the response \c content property.
FBRHTTPResponse *FBRFakeHTTPResponse(NSString *requestURL, NSUInteger statusCode = 200,
                                     FBRHTTPRequestHeaders * _Nullable headers = nil,
                                     NSData * _Nullable content = nil);

/// Returns a fake \c FBRHTTPResponse with the given properties. \c requestURL, \c statusCode and
/// \c headers parameters will be used as the properties of the response \c metadata. The
/// \c JSONObject, which has to be a JSON serializable \c NSArray or \c NSDictionary or an
/// \c MTLModel conforming to \c MTLJSONSerialing protocol, will be serialized to an \c NSData
/// buffer containing its JSON representation and will be set as the response \c content.
///
/// @note \c headers will be merged with 2 additional headers: "Content-Type" which is set to
/// "application/json" and "Cotnent-Length" which is set to the serializaed buffer length. In case
/// \c headers contain these headers they will take precendence.
FBRHTTPResponse *FBRFakeHTTPJSONResponse(NSString *requestURL, id JSONObject,
                                         NSUInteger statusCode = 200,
                                         FBRHTTPRequestHeaders * _Nullable headers = nil);

NS_ASSUME_NONNULL_END
