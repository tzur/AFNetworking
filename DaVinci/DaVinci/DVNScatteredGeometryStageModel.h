// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <Mantle/MTLModel.h>

#import "DVNPipelineStagesMutableModels.h"

NS_ASSUME_NONNULL_BEGIN

/// Mutable geometry stage model that provides models of \c DVNGeometryProvider objects that
/// construct potentially scattered geometry.
@interface DVNScatteredGeometryStageModel : MTLModel <DVNGeometryStageModel>

/// Base diameter of the brush.
@property (nonatomic) CGFloat diameter;
LTPropertyDeclare(CGFloat, diameter, Diameter);

/// Maximum number of duplications per processed quad.
@property (nonatomic) NSUInteger maxCount;

/// Lower bound on the random distance between the \c center of any processed quad and the \c center
/// of the corresponding duplicated quads.
@property (nonatomic) CGFloat minDistance;

/// Upper bound on the random distance between the \c center of any processed quad and the \c center
/// of the corresponding duplicated quads.
@property (nonatomic) CGFloat maxDistance;

/// Lower bound on the random angle by which any duplicated quad is rotated around its \c center.
@property (nonatomic) CGFloat minAngle;

/// Upper bound on the random angle by which any duplicated quad is rotated around its \c center.
@property (nonatomic) CGFloat maxAngle;

/// Lower bound on the random scale factor by which any duplicated quad is scaled around its
/// \c center.
@property (nonatomic) CGFloat minScale;

/// Upper bound on the random scale factor by which any duplicated quad is scaled around its
/// \c center.
@property (nonatomic) CGFloat maxScale;

@end

NS_ASSUME_NONNULL_END
