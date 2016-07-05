// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSErrorCodes+Fiber.h"

NS_ASSUME_NONNULL_BEGIN

/// All error codes available in Fiber.
LTErrorCodesImplement(FiberErrorCodeProductID,
  /// Serialization of an HTTP request failed.
  FBRErrorCodeHTTPRequestSerializationFailed,
  /// Initiation of an HTTP task failed.
  FBRErrorCodeHTTPTaskInitiationFailed,
  /// HTTP task completed prematurely due to client error.
  FBRErrorCodeHTTPTaskFailed,
  /// HTTP task terminated prematurely due to cancellation.
  FBRErrorCodeHTTPTaskCancelled,
  /// HTTP response with status code that indicates unsuccessful processing of the request received.
  FBRErrorCodeHTTPUnsuccessfulResponseReceived,
  /// Deserialization of an HTTP response failed.
  FBRErrorCodeHTTPResponseDeserializationFailed
);

NS_ASSUME_NONNULL_END
