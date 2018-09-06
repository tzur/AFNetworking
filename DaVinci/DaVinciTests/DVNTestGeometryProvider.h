// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <LTEngine/LTQuad.h>

#import "DVNGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Geometry provider model for testing.
@interface DVNTestGeometryProviderModel : NSObject <DVNGeometryProviderModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c state and the given \c quads. The given \c quads are used as the
/// \c quads of the \c dvn::GeometryValues returned by the \c valuesFromSamples:end: method of the
/// \c DVNTestGeometryProvider instances constructible from this instance.
- (instancetype)initWithState:(NSUInteger)state quads:(std::vector<lt::Quad>)quads
    NS_DESIGNATED_INITIALIZER;

/// State of this provider model.
@property (readonly, nonatomic) NSUInteger state;

/// Quads used as the \c quads of the \c dvn::GeometryValues returned by the \c valuesFromSamples:
/// method of the \c DVNTestGeometryProvider instances constructible from this instance.
@property (readonly, nonatomic) std::vector<lt::Quad> quads;

@end

/// Geometry provider for testing. Holding fake "state" property that gets incremented on every call
/// to <tt>valuesFromSamples:end:</tt>.
@interface DVNTestGeometryProvider : NSObject <DVNGeometryProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c state and the given \c quads. The given \c quads are used as the
/// \c quads of the \c dvn::GeometryValues returned by the \c valuesFromSamples:end: method.
- (instancetype)initWithState:(NSUInteger)state quads:(std::vector<lt::Quad>)quads
    NS_DESIGNATED_INITIALIZER;

/// Current state of this provider.
@property (readonly, nonatomic) NSUInteger state;

/// Quads used as the \c quads of the \c dvn::GeometryValues returned by the \c valuesFromSamples:
/// method.
@property (readonly, nonatomic) std::vector<lt::Quad> quads;

@end

NS_ASSUME_NONNULL_END
