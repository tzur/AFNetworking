// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTDualMaskProcessor.h"

/// Add a tilt shift effect to the image. Tilt shift effect created by locally blurring the image
/// using radial, linear or double linear pattern. This local application of the blur is used to
/// create a variety of artistic effects, such as making the objects to appear as miniatures.
/// The name tilt-shift is a legacy of the days where such effects where achieved by physically
/// manipulating the alignment of the surface of the center wrt the lens. For more information:
/// http://en.wikipedia.org/wiki/Tilt-shift_photography
@interface LTTiltShiftProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

#pragma mark -
#pragma mark Dual Mask
#pragma mark -

/// Dual mask type to construct. Default is LTDualMaskTypeRadial.
@property (nonatomic) LTDualMaskType maskType;

/// Center of the mask in coordinates of the output image, aka "pixel cooridnates". Despite the
/// relation to pixels, values in this coordinate system doesn't have to be integer.
/// Default value is the center (width/2, height/2). Range is unbounded.
@property (nonatomic) GLKVector2 center;

/// Diameter of the mask is the length in pixels of the straight line between two neutral points
/// through the center. Range is unbounded. Default value is min(width, height) / 2, so diameter of
/// the red part is half the of the smaller image dimension when corrected for aspect ratio.
/// @attention In case of linear mask type the width is zero by construction and this property
/// doesn't affect the mask.
@property (nonatomic) CGFloat diameter;

/// Spread of the mask determines how smooth or abrupt the transition from Red to Blue part around
/// neutral point is. Should be in [-1, 1] range. -1 is smooth, 1 is abrupt. Default value it 0.
@property (nonatomic) CGFloat spread;

/// Angle in radians which tilts the mask.
/// @attention Radial mask is rotationally invariant, thus this parameters doesn't affect the mask.
@property (nonatomic) CGFloat angle;

#pragma mark -
#pragma mark Blur
#pragma mark -

/// Intensity of the blur.
LTDeclareProperty(CGFloat, intensity, Intensity);

@end
