// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTOneShotImageProcessor.h"

/// Possible scaling modes for the perspective processor.
typedef NS_ENUM(NSUInteger, LTPerspectiveProcessorScaleMode) {
  /// Scale the content to fit the entire projection of the input texture inside the output texture.
  LTPerspectiveProcessorScaleModeFit,
  /// Scale the content to fill the entire output texture, so no "black" areas from outside the
  /// input texture appear in the output texture.
  ///
  /// @note currently supported for rotation adjustments only.
  LTPerspectiveProcessorScaleModeFill
};

@class LTTexture;

/// Processor for applying a perspective correction on a texture.
@interface LTPerspectiveProcessor : LTOneShotImageProcessor

/// Initializes the processor with the given input texture and output texture.
- (instancetype)initWithInput:(LTTexture *)input andOutput:(LTTexture *)output;

/// Returns whether the given point (in [0,1]x[0,1] coordinates) is mapped to a point inside the
/// projected texture.
- (BOOL)pointInTexture:(CGPoint)point;

/// Amount of horizontal perspective adjustment applied by the processor. This is the rotation angle
/// (in radians) around the Y axis of the homography matrix used for the perspective correction.
/// Must be in range [-M_PI/10,M_PI/10], default is \c 0.
@property (nonatomic) CGFloat horizontal;
LTPropertyDeclare(CGFloat, horizontal, Horizontal);

/// Amount of vertical perspective adjustment applied by the processor. This is the rotation angle
/// (in radians) around the X axis of the homography matrix used for the perspective correction.
/// Must be in range [-M_PI/10,M_PI/10], default is \c 0.
@property (nonatomic) CGFloat vertical;
LTPropertyDeclare(CGFloat, vertical, Vertical);

/// Angle (in radians) of the clockwise rotation around the X axis applied by the processor.
/// Must be in range [-M_PI/6,M_PI/6], default is \c 0.
@property (nonatomic) CGFloat rotationAngle;
LTPropertyDeclare(CGFloat, rotationAngle, RotationAngle);

/// Amount of geometric distortion to correct. Negative values fix a barrel distortion while
/// positive values fix a pincushion distortion. Must be in range [-0.5,0.5], default is \c 0.
@property (nonatomic) CGFloat distortion;
LTPropertyDeclare(CGFloat, distortion, Distortion);

/// Automatic scaling applied to the projection.
@property (nonatomic) LTPerspectiveProcessorScaleMode scaleMode;

/// Uniform scale applied on the projection to guarantee that it entirely fits the output texture.
@property (readonly, nonatomic) CGFloat scale;

/// Translation applied to center the rectangle bounding the projected trapezoid.
@property (readonly, nonatomic) CGSize translation;

/// Point (in [0,1]x[0,1] coordinates) mapped to the top left corner of the texture.
@property (readonly, nonatomic) LTVector2 topLeft;

/// Point (in [0,1]x[0,1] coordinates) mapped to the top right corner of the texture.
@property (readonly, nonatomic) LTVector2 topRight;

/// Point (in [0,1]x[0,1] coordinates) mapped to the bottom left corner of the texture.
@property (readonly, nonatomic) LTVector2 bottomLeft;

/// Point (in [0,1]x[0,1] coordinates) mapped to the bottom right corner of the texture.
@property (readonly, nonatomic) LTVector2 bottomRight;

/// Rectangle bounding the \c topLeft, \c topRight, \c bottomLeft, and \c bottomRight properties.
@property (readonly, nonatomic) CGRect boundingRect;

@end
