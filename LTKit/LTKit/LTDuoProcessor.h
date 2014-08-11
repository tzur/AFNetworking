// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTDualMaskProcessor.h"

/// By using dual mask, this class applies a different effect in red and blue regions of the mask.
@interface LTDuoProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

#pragma mark -
#pragma mark Dual Mask
#pragma mark -

/// Dual mask type to construct. Default is LTDualMaskTypeRadial.
@property (nonatomic) LTDualMaskType maskType;

/// Center of the mask in coordinates of the output image, aka "pixel cooridnates". Despite the
/// relation to pixels, values in this coordinate system don't have to be integers.
/// Default value of the center is (width/2, height/2). Range is unbounded.
@property (nonatomic) GLKVector2 center;

/// Diameter of the mask is the length in pixels of the straight line between two neutral points
/// through the center. Range is unbounded. Default value is min(width, height)/2, so diameter of
/// the red part is half the of the smaller image dimension when corrected for aspect ratio.
/// @attention In case of linear mask type the width is zero by construction and this property
/// doesn't affect the mask.
@property (nonatomic) CGFloat diameter;

/// Spread of the mask determines how smooth or abrupt the transition from Red to Blue part around
/// neutral point is. Should be in [-1, 1] range. -1 is smooth, 1 is abrupt. Default value it 0.
@property (nonatomic) CGFloat spread;

/// Angle in radians which tilts the mask. Default value is 0.
/// @attention Radial mask is rotationally invariant, thus this parameters doesn't affect the mask.
@property (nonatomic) CGFloat angle;

#pragma mark -
#pragma mark Colors
#pragma mark -

/// The mapping in the blue region is constructed by assigning this color to luminance midrange and
/// building the gradient around it. Gradient will map black to black and white to white. Default
/// color is opaque blue (0, 0, 1, 1).
@property (nonatomic) GLKVector4 blueColor;
LTPropertyDeclare(GLKVector4, blueColor, BlueColor);

/// The mapping in the red region is constructed by assigning this color to luminance midrange and
/// building the gradient around it. Gradient will map black to black and white to white. Default
/// color is opaque red (1, 0, 0, 1).
@property (nonatomic) GLKVector4 redColor;
LTPropertyDeclare(GLKVector4, redColor, RedColor);

/// Opacity of the result wrt input texture. Should be in [0, 1] range. Default value is 1.
@property (nonatomic) CGFloat opacity;
LTPropertyDeclare(CGFloat, opacity, Opacity);

@end
