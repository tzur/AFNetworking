// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRoundBrush.h"

@class LTTexture;

/// @class LTEdgeAvoidingBrush
///
/// A class representing a round edge-avoiding brush used by the \c LTPainter, using an input
/// texture for determining a factor based on the color similarity of each pixel to the area at the
/// center of the brush, and applying this factor on the brush intensity.
///
/// @note For performance reasons, the minimal value of the scale property is changed to 0.5.
/// @note The default value of the hardness property is changed to 0.
/// @note The behavior of some of the brush effects on this brush is unexpected.
@interface LTEdgeAvoidingBrush : LTRoundBrush

/// Texture of the base image (for color distance and edge-avoiding paint). When set to \c nil, the
/// brush will act as a regular brush.
@property (strong, nonatomic) LTTexture *inputTexture;

/// Edge Avoiding sigma parameter. The lower the value of this parameter, the stronger the
/// edge-avoiding effect will be. Must be in range [0.01,1], default is \c 0.5.
LTDeclareProperty(CGFloat, sigma, Sigma)

@end
