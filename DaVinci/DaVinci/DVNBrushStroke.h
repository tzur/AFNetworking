// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTInterval.h>
#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@class DVNBrushRenderModel, LTControlPointModel, LTTexture;

/// Value class specifying a brush stroke, as defined by the \c DVNBrushModel class. In
/// particular, the value class holds the information required to construct a spline from an
/// \c LTControlPointModel and perform the rendering of the brush stroke along the spline, according
/// to a \c DVNBrushRenderModel.
@interface DVNBrushStrokeSpecification : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new instance with the given \c controlPointModel, \c brushRenderModel, and
/// \c endInterval. The given \c endInterval must be non-negative.
+ (instancetype)specificationWithControlPointModel:(LTControlPointModel *)controlPointModel
                                  brushRenderModel:(DVNBrushRenderModel *)brushRenderModel
                                       endInterval:(lt::Interval<CGFloat>)endInterval;

/// Model representing the spline of the brush stroke.
@property (readonly, nonatomic) LTControlPointModel *controlPointModel;

/// Model determining the brush and additional rendering-specific information.
@property (readonly, nonatomic) DVNBrushRenderModel *brushRenderModel;

/// End interval of the brush stroke.
@property (readonly, nonatomic) lt::Interval<CGFloat> endInterval;

@end

/// Value class representing the entire data required to paint a brush stroke, as defined by the
/// \c DVNBrushModel class. In particular, the value class holds the brush stroke specification and
/// the corresponding textures.
@interface DVNBrushStrokeData : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new instance with the given brush stroke \c specification and the given
/// \c textureMapping. The texture mapping provides the textures required by the used brush model.
+ (instancetype)dataWithSpecification:(DVNBrushStrokeSpecification *)specification
                       textureMapping:(NSDictionary<NSString *, LTTexture *> *)textureMapping;

/// Specification of the brush stroke.
@property (readonly, nonatomic) DVNBrushStrokeSpecification *specification;

/// Textures required for rendering the brush stroke.
@property (readonly, nonatomic) NSDictionary<NSString *, LTTexture *> *textureMapping;

@end

NS_ASSUME_NONNULL_END
