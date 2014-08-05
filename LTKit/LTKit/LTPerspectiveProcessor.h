// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTGPUImageProcessor.h"

@class LTTexture;

/// Processor for applying a perspective correction on a texture.
@interface LTPerspectiveProcessor : LTImageProcessor

/// Initializes the processor with the given input texture and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Returns whether the given point (in [0,1]x[0,1] coordinates) is mapped to a point inside the
/// projected texture.
- (BOOL)pointInTexture:(CGPoint)point;

/// Amount of horizontal perspective adjustment applied by the processor. This is the rotation angle
/// (in radians) around the Y axis of the homography matrix used for the perspective correction.
/// Must be in range [-PI/10,PI/10], default is \c 0.
@property (nonatomic) CGFloat horizontal;
LTPropertyDeclare(CGFloat, horizontal, Horizontal);

/// Amount of vertical perspective adjustment applied by the processor. This is the rotation angle
/// (in radians) around the X axis of the homography matrix used for the perspective correction.
/// Must be in range [-PI/10,PI/10], default is \c 0.
@property (nonatomic) CGFloat vertical;
LTPropertyDeclare(CGFloat, vertical, Vertical);

/// Angle (in radians) of the rotation around the X axis applied by the processor.
/// Must be in range [-PI/6,PI/6], default is \c 0.
@property (nonatomic) CGFloat rotationAngle;
LTPropertyDeclare(CGFloat, rotationAngle, RotationAngle);

/// Uniform scale applied on the projection to guarantee that it entirely fits the output texture.
@property (readonly, nonatomic) CGFloat scale;

/// Translation applied to center the rectangle bounding the projected trapezoid.
@property (readonly, nonatomic) CGSize translation;

/// The point (in [0,1]x[0,1] coordinates) mapped to the top left corner of the texture.
@property (readonly, nonatomic) LTVector2 topLeft;

/// The point (in [0,1]x[0,1] coordinates) mapped to the top right corner of the texture.
@property (readonly, nonatomic) LTVector2 topRight;

/// The point (in [0,1]x[0,1] coordinates) mapped to the bottom left corner of the texture.
@property (readonly, nonatomic) LTVector2 bottomLeft;

/// The point (in [0,1]x[0,1] coordinates) mapped to the bottom right corner of the texture.
@property (readonly, nonatomic) LTVector2 bottomRight;

@end
