// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Fiber.
  FiberErrorCodeProductID = 9
};

/// All error codes available in Fiber.
LTErrorCodesDeclare(FiberErrorCodeProductID,
  /// Serialization of an HTTP request failed.
  FBRErrorCodeHTTPRequestSerializationFailed,
  /// Initiation of an HTTP task failed.
  FBRErrorCodeHTTPTaskInitiationFailed,
  /// HTTP task terminated prematurely due to an error.
  FBRErrorCodeHTTPTaskFailed,
  /// HTTP task terminated prematurely due to cancellation.
  FBRErrorCodeHTTPTaskCancelled,
  /// HTTP response with status code that indicates unseccessful processing of the request received.
  FBRErrorCodeHTTPUnsuccessfulResponseReceived,
  /// Deserialization of an HTTP response failed.
  FBRErrorCodeHTTPResponseDeserializationFailed,
  /// Deserialization of a JSON object failed.
  FBRErrorCodeJSONDeserializationFailed,
  /// On demand resources request failed.
  FBRErrorCodeOnDemandResourcesRequestFailed
);

NS_ASSUME_NONNULL_END
