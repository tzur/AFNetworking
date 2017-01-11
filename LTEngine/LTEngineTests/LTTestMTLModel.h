// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

/// Simple \c MTLModel that supports serialization for tests.
@interface LTTestMTLModel : MTLModel <MTLJSONSerializing>

/// Initializes with the given \c name and \c value.
- (instancetype)initWithName:(NSString *)name value:(NSUInteger)value;

/// Name of the model.
@property (readonly, nonatomic) NSString *name;

/// Primitive value of the model.
@property (readonly, nonatomic) NSUInteger value;

@end

NS_ASSUME_NONNULL_END
