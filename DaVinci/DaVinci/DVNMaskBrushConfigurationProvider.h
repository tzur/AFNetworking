// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

@protocol DVNMaskBrushParametersProvider;

@class DVNBrushTipsProvider, DVNPipelineConfiguration;

/// Size of the mask brush tip texture.
extern const CGFloat kMaskBrushDimension;

/// Object that provides \c DVNPipelineConfiguration objects for mask brushes, as defined in the
/// \c DVNMaskBrushConfigurationProvider class.
@interface DVNMaskBrushConfigurationProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c parametersProvider and the given \c brushTipsProvider. The
/// \c parametersProvider is held weakly and must not be deallocated before this object is
/// deallocated. The \c brushTipsProvider is held strongly and is used to provide brush tips for the
/// mask brush.
- (instancetype)initWithParametersProvider:(id<DVNMaskBrushParametersProvider>)parametersProvider
                         brushTipsProvider:(DVNBrushTipsProvider *)brushTipsProvider
    NS_DESIGNATED_INITIALIZER;

/// Returns a pipeline configuration according to the parameters retrieved from the provider.
- (DVNPipelineConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
