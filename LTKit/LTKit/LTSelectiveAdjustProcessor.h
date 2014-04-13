// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

/// LTSelectiveAdjustProcessor manipulates saturation and intensity of the image using masks defined
/// by the hues in the image.
@interface LTSelectiveAdjustProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture to be adjusted and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

#pragma mark -
#pragma mark Red
#pragma mark -

/// Changes the saturation of the red. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, redSaturation, RedSaturation);

/// Changes the luminance of the red. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, redLuminance, RedLuminance);

#pragma mark -
#pragma mark Orange
#pragma mark -

/// Changes the saturation of the orange. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, orangeSaturation, OrangeSaturation);

/// Changes the luminance of the orange. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, orangeLuminance, OrangeLuminance);

#pragma mark -
#pragma mark Yellow
#pragma mark -

/// Changes the saturation of the yellow. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, yellowSaturation, YellowSaturation);

/// Changes the luminance of the yellow. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, yellowLuminance, YellowLuminance);

#pragma mark -
#pragma mark Green
#pragma mark -

/// Changes the saturation of the green. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, greenSaturation, GreenSaturation);

/// Changes the luminance of the green. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, greenLuminance, GreenLuminance);

#pragma mark -
#pragma mark Cyan
#pragma mark -

/// Changes the saturation of the cyan. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, cyanSaturation, CyanSaturation);

/// Changes the luminance of the cyan. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, cyanLuminance, CyanLuminance);

#pragma mark -
#pragma mark Blue
#pragma mark -

/// Changes the saturation of the blue. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, blueSaturation, BlueSaturation);

/// Changes the luminance of the blue. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, blueLuminance, BlueLuminance);

@end
