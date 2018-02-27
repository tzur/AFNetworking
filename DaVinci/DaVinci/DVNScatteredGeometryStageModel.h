// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNPipelineStagesMutableModels.h"
#import "DVNPropertyMacros.h"

NS_ASSUME_NONNULL_BEGIN

/// Mutable geometry stage model that provides models of \c DVNGeometryProvider objects that
/// construct potentially scattered geometry.
@interface DVNScatteredGeometryStageModel : MTLModel <DVNGeometryStageModel>

/// Base diameter of the brush. Must be in <tt>[0.01, CGFLOAT_MAX]<\tt> range. Default value is
/// \c 1.
DVNPropertyDeclare(CGFloat, diameter, Diameter);

/// Minimum number of duplications per processed quad. Must be in <tt>[0, maxCount]<\tt> range.
/// Default value is \c 1.
DVNPropertyDeclare(NSUInteger, minCount, MinCount);

/// Maximum number of duplications per processed quad. Must in <tt>[minCount, NSUIntegerMax]<\tt>
/// range. Default value is \c 1.
DVNPropertyDeclare(NSUInteger, maxCount, MaxCount);

/// Lower bound on the random distance between the \c center of any processed quad and the \c center
/// of the corresponding duplicated quads. Must be in <tt>[0, maxDistance]<\tt> range. Default value
/// is \c 0.
DVNPropertyDeclare(CGFloat, minDistance, MinDistance);

/// Upper bound on the random distance between the \c center of any processed quad and the \c center
/// of the corresponding duplicated quads. Must be in <tt>[minDistance, CGFLOAT_MAX]<\tt> range.
/// Default value is \c 0.
DVNPropertyDeclare(CGFloat, maxDistance, MaxDistance);

/// Lower bound on the random angle by which any duplicated quad is rotated around its \c center.
/// Must be in range <tt>[0, maxAngle]</tt>. Default value is \c 0.
DVNPropertyDeclare(CGFloat, minAngle, MinAngle);

/// Upper bound on the random angle by which any duplicated quad is rotated around its \c center.
/// Must be in range <tt>[minAngle, 4 * M_PI]</tt>. Default value is \c 0.
DVNPropertyDeclare(CGFloat, maxAngle, MaxAngle);

/// Lower bound on the random scale factor by which any duplicated quad is scaled around its
/// \c center. Must be in <tt>[0, maxScale]<\tt> range. Default value is \c 1.
DVNPropertyDeclare(CGFloat, minScale, MinScale);

/// Upper bound on the random scale factor by which any duplicated quad is scaled around its
/// \c center. Must be in <tt>[minScale, CGFLOAT_MAX]<\tt> range. Default value is \c 1.
DVNPropertyDeclare(CGFloat, maxScale, MaxScale);

@end

NS_ASSUME_NONNULL_END
