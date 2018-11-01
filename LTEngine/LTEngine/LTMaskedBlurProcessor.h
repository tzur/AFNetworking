// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "LTOneShotImageProcessor.h"

@class LTTexture;

NS_ASSUME_NONNULL_BEGIN

/// Apply progressive blur to input image according to blur mask values.
@interface LTMaskedBlurProcessor : LTOneShotImageProcessor

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the processor with \c input texture, blur mask and output texture.
///
/// @note: \c blurMask values should be in \c [0,0.5] where \c, 0 indicates maximal blur. Default is
/// \c nil - no blur applied.
- (instancetype)initWithInput:(LTTexture *)input blurMask:(nullable LTTexture *)blurMask
                       output:(LTTexture *)output;

/// Initializes the processor with \c input texture, \c mask texture, blur mask texture, which
/// control the blur amount which is applied to the input texture and an \c output texture.
///
/// @note: amount of blur applied is controlled by 3 parameters \c intensity, \c mask and
/// \c blurMask. \c blurMask values multiplied by factor of intensity and mask values to produce the
/// final value of blur amount. \c blurMask values should be in \c [0,0.5] where \c 0 indicates
/// maximal blur. Default is \c nil - no blur applied.
- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask
                     blurMask:(nullable LTTexture *)blurMask output:(LTTexture *)output
    NS_DESIGNATED_INITIALIZER;

#pragma mark -
#pragma mark Blur
#pragma mark -

/// Intensity of the blur. Accepts values in range \c [0,1]. Default is \c 1. Intensity is
/// multiplied by the mask to get the blending factor between the blurred and the input.
@property (nonatomic) CGFloat intensity;
LTPropertyDeclare(CGFloat, intensity, Intensity);

@end

NS_ASSUME_NONNULL_END
