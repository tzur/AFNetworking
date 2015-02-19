// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

/// @class LTProceduralVignetting
///
/// Creates a vignetting pattern.
/// Vignetting pattern has a value of 1 at the corners of the image and decreases towards the
/// center. The fallof can be modulated with a noise to create a more ragged appearance.
///
/// @attention This class is not in charge to set the color of the vignetting.
@interface LTProceduralVignetting : LTOneShotImageProcessor

/// Initializes a procedural vignetting processor with an output texture.
- (instancetype)initWithOutput:(LTTexture *)output;

/// Percent of the image diagonal where the vignetting pattern is not zero.
/// Should be in [0-100] range. Default value is 100.
@property (nonatomic) CGFloat spread;
LTPropertyDeclare(CGFloat, spread, Spread);

/// Determines the corner type of the frame and corresponds to the p-norm which is used to compute
/// the distance field. Should be in [2-16] range. The default value is 2.
/// Corner values determince how the distance field in the shader is created. The corner can be
/// completely round by passing 2 and creating an Euclidean distance field for increasingly higher
/// values, the distance field will become more rectangular. The limit of 16 is due to the precision
/// limits in the shader.
@property (nonatomic) CGFloat corner;
LTPropertyDeclare(CGFloat, corner, Corner);

/// Controls how abrupt the transition of the vignetting pattern is. Should be in [0, 1] range.
/// Default value is 0. Higher values correspond to more abrupt transition.
@property (nonatomic) CGFloat transition;
LTPropertyDeclare(CGFloat, transition, Transition);

/// Noise textures that modulates with the vignetting pattern. Default value is a constant 0.5,
/// which doesn't affect the image. Set \c noise back to \c nil to restore the default value.
///
/// @attention Noise is assumed to be with 0.5 mean. Stick to this assumption, unless you want to
/// create a very specific visual result and understand well the underlying frame creation process.
@property (strong, nonatomic) LTTexture *noise;

/// Mixes the noise channels of the noise texture in order to create the transition noise.
/// Components should be in [-1, 1] range. Default value is (1, 0, 0). Input values are normalized,
/// to remove potential interference with noise amplitude.
@property (nonatomic) LTVector3 noiseChannelMixer;
LTPropertyDeclare(LTVector3, noiseChannelMixer, NoiseChannelMixer);

/// Amplitude of the noise. Should be in [0, 100] range. Default amplitude is 0.
@property (nonatomic) CGFloat noiseAmplitude;
LTPropertyDeclare(CGFloat, noiseAmplitude, NoiseAmplitude);

@end
