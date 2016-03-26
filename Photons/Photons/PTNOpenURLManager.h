// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNOpenURLHandler.h"

NS_ASSUME_NONNULL_BEGIN

/// Registers URL handlers and demultiplexes the \c -application:openURL:options: call to each one
/// of them in the given order, until one of the handlers handles the call successfully. This serves
/// as an entry point to URL handling by the handlers that are provided by Photons sources.
@interface PTNOpenURLManager : NSObject <PTNOpenURLHandler>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c handlers that handle calls from the OpenURL mechanism. A call to
/// \c -application:openURL:options: will be sent to each handler, in the order defined by
/// \c handlers, until one handles it succesfully.
- (instancetype)initWithHandlers:(NSArray<id<PTNOpenURLHandler>> *)handlers
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
