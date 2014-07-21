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
@property (nonatomic) CGFloat redSaturation;
LTPropertyDeclare(CGFloat, redSaturation, RedSaturation);

/// Changes the luminance of the red. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat redLuminance;
LTPropertyDeclare(CGFloat, redLuminance, RedLuminance);

#pragma mark -
#pragma mark Orange
#pragma mark -

/// Changes the saturation of the orange. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat orangeSaturation;
LTPropertyDeclare(CGFloat, orangeSaturation, OrangeSaturation);

/// Changes the luminance of the orange. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat orangeLuminance;
LTPropertyDeclare(CGFloat, orangeLuminance, OrangeLuminance);

#pragma mark -
#pragma mark Yellow
#pragma mark -

/// Changes the saturation of the yellow. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat yellowSaturation;
LTPropertyDeclare(CGFloat, yellowSaturation, YellowSaturation);

/// Changes the luminance of the yellow. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat yellowLuminance;
LTPropertyDeclare(CGFloat, yellowLuminance, YellowLuminance);

#pragma mark -
#pragma mark Green
#pragma mark -

/// Changes the saturation of the green. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat greenSaturation;
LTPropertyDeclare(CGFloat, greenSaturation, GreenSaturation);

/// Changes the luminance of the green. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat greenLuminance;
LTPropertyDeclare(CGFloat, greenLuminance, GreenLuminance);

#pragma mark -
#pragma mark Cyan
#pragma mark -

/// Changes the saturation of the cyan. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat cyanSaturation;
LTPropertyDeclare(CGFloat, cyanSaturation, CyanSaturation);

/// Changes the luminance of the cyan. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat cyanLuminance;
LTPropertyDeclare(CGFloat, cyanLuminance, CyanLuminance);

#pragma mark -
#pragma mark Blue
#pragma mark -

/// Changes the saturation of the blue. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat blueSaturation;
LTPropertyDeclare(CGFloat, blueSaturation, BlueSaturation);

/// Changes the luminance of the blue. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat blueLuminance;
LTPropertyDeclare(CGFloat, blueLuminance, BlueLuminance);

@end
