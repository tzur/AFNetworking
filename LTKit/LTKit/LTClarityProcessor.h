// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// Add a clarity effect to the image. Clarity effect boosts local contrast at multiple scales.
/// Since changing local contrast is not orthogonal to changes in perceived brightness and
/// colorfulness of the image, control other these two parameters provided as well.
/// For an overview of local contrast boosting: "Edge-Preserving Decompositions for Multi-Scale Tone
/// and Detail Manipulation", ACM Transactions on Graphics, 27(3), August 2008.
@interface LTClarityProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Boost local contrast at medium-fine scale. Should be in [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat punch;
LTPropertyDeclare(CGFloat, punch, Punch);

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
