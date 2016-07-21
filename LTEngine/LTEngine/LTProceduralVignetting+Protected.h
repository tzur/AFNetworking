// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

NS_ASSUME_NONNULL_BEGIN

/// Accessor for protected members of \c LTProceduralVignetting.
@interface LTProceduralVignetting()

/// Initializes the processor with \c vertexSource \c fragmentSource and \c output texture.
///
/// @note: \c fragmentSource should contain the uniforms from LTProceduralVignetting.fsh: spread,
/// corner, transition, noiseAmplitude, noiseChannelMixer, distanceShift
- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource andOutput:(LTTexture *)output;

// Computes the distance shift that is used to correct aspect ratio in the shader.
// Aspect ratio is corrected by zeroing the longer dimension near the center, so non-zero part
// of both dimensions is equal. Such strategy (instead of simple scaling) is needed in order to
// preserve the correct transition behaviour.
- (LTVector2)computeDistanceShift:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
