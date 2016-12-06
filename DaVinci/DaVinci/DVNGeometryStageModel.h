// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <Mantle/MTLModel.h>

#import "DVNPipelineStagesMutableModels.h"

NS_ASSUME_NONNULL_BEGIN

/// Mutable pipeline geometry stage model that provides geometry providers.
@interface DVNGeometryStageModel : MTLModel <DVNGeometryStageModel>

/// Base diameter of the brush.
@property (nonatomic) CGFloat diameter;
LTPropertyDeclare(CGFloat, diameter, Diameter);

/// Maximum number of brush tips to scatter.
@property (nonatomic) NSUInteger maxScatterCount;

/// Minimum distance between original brush tip and its respective scattered tips.
@property (nonatomic) CGFloat minScatterDistance;

/// Maximum distance between original brush tip and its respective scattered tips.
@property (nonatomic) CGFloat maxScatterDistance;

/// Minimum angle to rotate each scattered brush tip.
@property (nonatomic) CGFloat minScatterAngle;

/// Maximum angle to rotate each scattered brush tip.
@property (nonatomic) CGFloat maxScatterAngle;

/// Minimum scale factor to apply on each scattered brush tip.
@property (nonatomic) CGFloat minScatterScale;

/// Maximum scale factor to apply on each scattered brush tip.
@property (nonatomic) CGFloat maxScatterScale;

@end

NS_ASSUME_NONNULL_END
