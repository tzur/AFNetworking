// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

@protocol DVNMaskBrushParametersProvider;

@class DVNPipelineConfiguration;

/// Object that provides \c DVNPipelineConfiguration objects for mask brushes, as defined in the
/// \c DVNMaskBrushConfigurationProvider class.
@interface DVNMaskBrushConfigurationProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c provider, which is held weakly. The given \c provider must not be
/// deallocated before this object is deallocated.
- (instancetype)initWithProvider:(id<DVNMaskBrushParametersProvider>)provider
    NS_DESIGNATED_INITIALIZER;

/// Returns a pipeline configuration according to the parameters retrieved from the provider.
- (DVNPipelineConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
