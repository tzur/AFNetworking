// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTJSONSerializable.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol implemented by objects that provide a JSON serializable dictionary compliant with the
/// Lightricks backend events structure.
@protocol INTAnalytricksEvent <NSObject>

/// Dictionary representing the receiver's current properties assignments that can be serialized
/// into JSON. Must contain the key "event" with an \c NSString value, representing the event type
/// as defined by the Lightricks backend.
@property (readonly, nonatomic) NSDictionary<NSString *, id> *properties;

@end

NS_ASSUME_NONNULL_END
