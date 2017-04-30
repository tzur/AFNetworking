// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Protocol implemented by objects that log events to a specific service. A service can be a local
/// service running on the device or a backend service.
@protocol INTEventLogger <NSObject>

/// Logs \c event only if it's supported by the receiver. If \c event is not supported by the
/// receiver, this call has no effect. This call is thread safe.
- (void)logEvent:(id)event;

/// Returns \c YES if \c event is supported and can be logged by the receiver.
- (BOOL)isEventSupported:(id)event;

@end

NS_ASSUME_NONNULL_END
