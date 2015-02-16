// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// Add a clarity effect to the image. Clarity effect manipulates local contrast at multiple scales.
/// Since changing local contrast is not orthogonal to changes in perceived brightness and
/// colorfulness of the image, control other these two parameters provided as well.
/// The decomposition in this processor is built in the following manner:
/// 1) Tiniest details of the image are controlled by downscaling the image by the factor of 2.
/// Besides the sharpening control it provides, it allows to improve speed and memory consumption of
/// the subsequent decomposition levels.
/// 2) Fine details of the image are controlled by applying multiple iterations on the bilateral
/// filter on (1). While iterative setup is prone to oversharpening of the edges, this choice is
/// motivated by the fact that the ampllitude of this level is expected to be reduced, in order to
/// achieve a denoising effect.
/// 3) Medium and coarse details are controlled by creating a level using Edge-Avoiding Wavelets.
/// For an overview of local contrast boosting: "Edge-Preserving Decompositions for Multi-Scale Tone
/// and Detail Manipulation", ACM Transactions on Graphics, 27(3), August 2008.
@interface LTClarityProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Changes the sharpness of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat sharpen;
LTPropertyDeclare(CGFloat, sharpen, Sharpen);

/// Control local contrast at fine scale. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat fineContrast;
LTPropertyDeclare(CGFloat, fineContrast, FineContrast);

/// Boost local contrast at medium scale. Should be in [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat mediumContrast;
LTPropertyDeclare(CGFloat, mediumContrast, MediumContrast);

/// Shifts black by blackPointShift. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat blackPointShift;
LTPropertyDeclare(CGFloat, blackPointShift, BlackPointShift);

/// Reduce local contrast at coarse scale. Should be in [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat flatten;
LTPropertyDeclare(CGFloat, flatten, Flatten);

/// Increase brighntess and slightly increase contrast using a sigmoid function. Should be in
/// [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat gain;
LTPropertyDeclare(CGFloat, gain, Gain);

/// Changes the saturation of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat saturation;
LTPropertyDeclare(CGFloat, saturation, Saturation);

@end
