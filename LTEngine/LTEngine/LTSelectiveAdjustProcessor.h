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

/// Changes the saturation of the reds. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat redSaturation;
LTPropertyDeclare(CGFloat, redSaturation, RedSaturation);

/// Changes the luminance of the reds. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat redLuminance;
LTPropertyDeclare(CGFloat, redLuminance, RedLuminance);

/// Changes the hue of the reds. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat redHue;
LTPropertyDeclare(CGFloat, redHue, RedHue);

#pragma mark -
#pragma mark Orange
#pragma mark -

/// Changes the saturation of the oranges. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat orangeSaturation;
LTPropertyDeclare(CGFloat, orangeSaturation, OrangeSaturation);

/// Changes the luminance of the oranges. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat orangeLuminance;
LTPropertyDeclare(CGFloat, orangeLuminance, OrangeLuminance);

/// Changes the hue of the oranges. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat orangeHue;
LTPropertyDeclare(CGFloat, orangeHue, OrangeHue);

#pragma mark -
#pragma mark Yellow
#pragma mark -

/// Changes the saturation of the yellows. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat yellowSaturation;
LTPropertyDeclare(CGFloat, yellowSaturation, YellowSaturation);

/// Changes the luminance of the yellows. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat yellowLuminance;
LTPropertyDeclare(CGFloat, yellowLuminance, YellowLuminance);

/// Changes the hue of the yellows. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat yellowHue;
LTPropertyDeclare(CGFloat, yellowHue, YellowHue);

#pragma mark -
#pragma mark Green
#pragma mark -

/// Changes the saturation of the greens. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat greenSaturation;
LTPropertyDeclare(CGFloat, greenSaturation, GreenSaturation);

/// Changes the luminance of the greens. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat greenLuminance;
LTPropertyDeclare(CGFloat, greenLuminance, GreenLuminance);

/// Changes the hue of the greens. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat greenHue;
LTPropertyDeclare(CGFloat, greenHue, GreenHue);

#pragma mark -
#pragma mark Cyan
#pragma mark -

/// Changes the saturation of the cyans. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat cyanSaturation;
LTPropertyDeclare(CGFloat, cyanSaturation, CyanSaturation);

/// Changes the luminance of the cyans. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat cyanLuminance;
LTPropertyDeclare(CGFloat, cyanLuminance, CyanLuminance);

/// Changes the hue of the cyans. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat cyanHue;
LTPropertyDeclare(CGFloat, cyanHue, CyanHue);

#pragma mark -
#pragma mark Blue
#pragma mark -

/// Changes the saturation of the blues. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat blueSaturation;
LTPropertyDeclare(CGFloat, blueSaturation, BlueSaturation);

/// Changes the luminance of the blues. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat blueLuminance;
LTPropertyDeclare(CGFloat, blueLuminance, BlueLuminance);

/// Changes the hue of the blues. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat blueHue;
LTPropertyDeclare(CGFloat, blueHue, BlueHue);

@end
