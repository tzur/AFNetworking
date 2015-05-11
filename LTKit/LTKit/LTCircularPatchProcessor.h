// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTOneShotBaseImageProcessor.h"

#import "LTCircularPatchDrawer.h"

@class LTTexture;

/// Uses circular patch, heal or clone to fix defects in the image or clone from target to source.
/// Patch copies from source to target, using a smoothing membrane. Heal applies the smoothing
/// membrane on the target patch and clone copies pixels from source to target.
@interface LTCircularPatchProcessor : LTOneShotBaseImageProcessor

/// Initializes the processor with \c input texture from which to take the circular patches and
/// \c output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Sets the \c sourceCenter out of \c sourceCenters which best matches \c targetCenter.
- (void)setBestSourceCenterForCenters:(const CGPoints &)sourceCenters;

/// Circular patch mode. Default mode is \c LTCircularPatchModePatch.
@property (nonatomic) LTCircularPatchMode circularPatchMode;

/// Center of the source circular patch.
@property (nonatomic) CGPoint sourceCenter;

/// Center of the target circular patch.
@property (nonatomic) CGPoint targetCenter;

/// Radius of the circular patch in pixels. Default \c radius is \c 0.
@property (nonatomic) CGFloat radius;
LTPropertyDeclare(CGFloat, radius, Radius);

/// Clockwise rotation in radians of the source circular patch. Default \c rotation is \c 0.
@property (nonatomic) CGFloat rotation;
LTPropertyDeclare(CGFloat, rotation, Rotation);

/// Flips horizontally the source patch.
@property (nonatomic) BOOL flip;

/// Controls the amount of feathering of the membrane. Default value is \c 0, which means light
/// feathering. Higher alpha value means stronger feathering.
@property (nonatomic) CGFloat featheringAlpha;
LTPropertyDeclare(CGFloat, featheringAlpha, FeatheringAlpha);

/// Blends source and target patches using \c alpha. Default value is \c 1, which means fully
/// blended.
@property (nonatomic) CGFloat alpha;
LTPropertyDeclare(CGFloat, alpha, Alpha);

/// Modulates the source smoothing. Value of \c 1 means fully smoothed, which gives seamless
/// patching effect. Value of \c 0 means pixels from the source are simply copied without any
/// smoothing. Default value is \c 1.
@property (nonatomic) CGFloat smoothingAlpha;
LTPropertyDeclare(CGFloat, smoothingAlpha, SmoothingAlpha);

@end
