// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTInterval.h>

NS_ASSUME_NONNULL_BEGIN

@class DVNPipelineConfiguration, LTControlPointModel;

/// Value class holding the information required by a \c DVNSplineRenderer to construct a spline
/// from a given \c LTControlPointModel and perform a rendering of the sampled spline according to a
/// given \c DVNPipelineConfiguration.
///
/// @note The model represents the entire spline and describes a way to render the entire spline
///       according to the associated configuration.
@interface DVNSplineRenderModel : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c controlPointModel, \c configuration, and \c endInterval.
- (instancetype)initWithControlPointModel:(LTControlPointModel *)controlPointModel
                            configuration:(DVNPipelineConfiguration *)configuration
                              endInterval:(lt::Interval<CGFloat>)endInterval;

/// Model representing a spline.
@property (readonly, nonatomic) LTControlPointModel *controlPointModel;

/// Configuration of a \c DVNPipeline object.
@property (readonly, nonatomic) DVNPipelineConfiguration *configuration;

/// End interval to use in the rendering of geometry created from the spline represented by the
/// \c controlPointModel. Refer to the documentation of the \c DVNSplineRenderer for more
/// information.
@property (readonly, nonatomic) lt::Interval<CGFloat> endInterval;

@end

NS_ASSUME_NONNULL_END
