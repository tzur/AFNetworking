// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

@class LTGLTexture;

/// Gaussian sigma used by the <tt>roundTipWithDimension:hardness:</tt> method of \c DVNBrushTips.
extern const CGFloat kRoundTipGaussianSigma;

/// Object that provides brush tip textures.
@interface DVNBrushTipsProvider : NSObject

/// Returns a single channel square texture with the given \c dimension, depicting a round brush tip
/// with the given \c hardness. \c dimension specify the size of the returned squared texture, and
/// must be a power of \c 2 and greater or equal to \c 16. The \c hardness parameter must be in
/// range <tt>[0, 1]<\tt> and is used to determine the solidness of the tip texture. If set to \c 0,
/// the texture will be constructed from a gaussian function with mean <tt>(dimension / 2,
/// dimension / 2)</tt> and sigma \c kGaussianSigma, and if set to \c 1, texture will be constructed
/// from circumscribing square with dimension that is equal to the given \c dimension.
- (LTGLTexture *)roundTipWithDimension:(NSUInteger)dimension hardness:(CGFloat)hardness;

@end

NS_ASSUME_NONNULL_END
