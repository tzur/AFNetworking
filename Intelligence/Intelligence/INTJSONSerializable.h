// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Protocol implemented by value objects that provide a JSON representing its properties.
@protocol INTJSONSerializable <NSObject>

/// Dictionary representing the receiver's current properties assignments that can be serialized
/// into JSON.
@property (readonly, nonatomic) NSDictionary<NSString *, id> *properties;

@end

NS_ASSUME_NONNULL_END
