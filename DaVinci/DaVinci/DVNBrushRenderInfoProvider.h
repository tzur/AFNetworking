// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class DVNPipelineConfiguration, LTParameterizedObjectType;

/// Protocol to be implemented by objects returning an \c LTParameterizedObjectType object which can
/// be used for constructing a spline along which a brush stroke is rendered, and a
/// \c DVNPipelineConfiguration object constituting the configuration for rendering aforementioned
/// brush stroke.
@protocol DVNBrushRenderInfoProvider <NSObject>

/// Returns the type of a spline along which a brush stroke can be rendered.
- (LTParameterizedObjectType *)brushSplineType;

/// Returns the configuration of a \c DVNPipeline object usable for brush stroke rendering.
- (DVNPipelineConfiguration *)brushRenderConfiguration;

@end

NS_ASSUME_NONNULL_END
