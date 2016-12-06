// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Geometry provider model for testing.
@interface DVNTestGeometryProviderModel : NSObject <DVNGeometryProviderModel>

/// Initializes with the given \c state.
- (instancetype)initWithState:(NSUInteger)state;

/// State of this provider model.
@property (readonly, nonatomic) NSUInteger state;

@end

/// Geometry provider for testing. Holding fake "state" property that gets incremented on every call
/// to <tt>valuesFromSamples:end:</tt>.
@interface DVNTestGeometryProvider : NSObject <DVNGeometryProvider>

/// Initializes with the given \c state.
- (instancetype)initWithState:(NSUInteger)state;

/// Current state of this provider.
@property (readonly, nonatomic) NSUInteger state;

@end

NS_ASSUME_NONNULL_END
