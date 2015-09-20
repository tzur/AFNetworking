// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPropertyMacros.h"

#import "LTBrushEffect.h"

/// A class representing a dynamic brush effect used by the \c LTBrush.
/// This class implements the shape dynamics effect, allowing to dynamically control the size, angle
/// and roundness of the brush as we paint.
///
/// @see http://www.photoshopessentials.com/basics/photoshop-brushes/brush-dynamics/
@interface LTBrushShapeDynamicsEffect : LTBrushEffect

/// Returns an array of the manipulated \c LTRotatedRects based on the given array of \c
/// LTRotatedRects which represent the original locations of the brush tips.
- (NSMutableArray *)dynamicRectsFromRects:(NSArray *)rects;

/// Controls the randomness of how the size of brush marks varies in a stroke. The higher the value,
/// the higher the probability of a significant change. Must be in range [0,1], default is \c 0.
@property (nonatomic) CGFloat sizeJitter;
LTPropertyDeclare(CGFloat, sizeJitter, SizeJitter);

/// Specifies the minimum percentage by which brush marks can scale when \c sizeJitter is enabled.
/// Must be in range [0,1], default is \c 0.5.
@property (nonatomic) CGFloat minimumDiameter;
LTPropertyDeclare(CGFloat, minimumDiameter, MinimumDiameter);

/// Controls how the angle of the brush varies in a stroke. The higher the value, the higher the
/// probability of a significant change. When set to \c 1, the brush can rotate 180 degrees in both
/// directions. Must be in range [0,1], default is \c 0.
@property (nonatomic) CGFloat angleJitter;
LTPropertyDeclare(CGFloat, angleJitter, AngleJitter);

/// Controls how the roundness of the brush varies in a stroke. The higher the value, the higher the
/// probability that a round brush will turn into an ellipse. Must be in range [0,1], default is
/// \c 0.
@property (nonatomic) CGFloat roundnessJitter;
LTPropertyDeclare(CGFloat, roundnessJitter, RoundnessJitter);

/// Specifies the minimum roundness for brush marks when \c roundnessJitter is enabled.
/// Must be in range [0,1], default is \c 0.25.
@property (nonatomic) CGFloat minimumRoundness;
LTPropertyDeclare(CGFloat, minimumRoundness, MinimumRoundness);

@end
