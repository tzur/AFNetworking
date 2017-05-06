// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTOneShotImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Processor that constructs a single level of a laplacian pyramid from the corresponding gaussian
/// pyramid levels (the same level and one level higher) and immediately fuses it into an existing
/// laplacian pyramid level by multiplying it with a given weight map and adding it to the existing
/// laplacian level.
@interface LTLaplacianLevelFusionProcessor : LTOneShotImageProcessor

/// Initializer for constructing a single laplacian pyramid level and fusing it into an existing
/// \c output laplacian level. The applied operation is equivalent to <tt>output +=
/// baseLevelWeightMap * (baseGaussianLevel + pyrUp(higherGaussianLevel))</tt> where \pyrUp is the
/// upsampling operation using the hat kernel such as in \LTHatPyramidProcessor.
///
/// @param baseGaussianLevel Gaussian pyramid level of the same size as the result laplacian level.
///
/// @param higherGaussianLevel Gaussian pyramid level one level higher (smaller). Texture min and
/// mag interpolation filters must be set to \c LTTextureInterpolationNearest. For example when
/// \c baseGaussianLevel is the highest (smallest) level in the pyramid then \c higherGaussianLevel
/// will be \c nil and the processor will skip the laplacian level construction and would only
/// multiply \c baseGaussianLevel itself with \c baseLevelWeightMap before adding it to \c output so
/// that the applied operation is equivalent to <tt>output += baseLevelWeightMap *
/// baseGaussianLevel</tt>.
///
/// @param baseLevelWeightMap the weights used for fusing the calculated laplacian level with the
/// existing output laplacian level. It is assumed that the weights are already normalized with any
/// other textures intended for the same blending process and no further scaling is done while
/// blending the resulting laplacian levels. Weight map texture must be a single channel half float
/// precision and of the same size as \c baseGaussianLevel.
///
/// @param output The blended laplacian level resulting from the \c += operation. Must be the
/// same size as \c baseGaussianLevel.
- (instancetype)initWithBaseGaussianLevel:(LTTexture *)baseGaussianLevel
                      higherGaussianLevel:(nullable LTTexture *)higherGaussianLevel
                          baseWeightLevel:(LTTexture *)baseLevelWeightMap
                         addToOutputLevel:(LTTexture *)output NS_DESIGNATED_INITIALIZER;

/// Convenience initializer for the highest level of the pyramid (where \c higherGaussianLevel is
/// \c nil).
- (instancetype)initWithBaseGaussianLevel:(LTTexture *)baseGaussianLevel
                          baseWeightLevel:(LTTexture *)baseLevelWeightMap
                         addToOutputLevel:(LTTexture *)output;

#pragma mark -
#pragma mark Inheritance initializers
#pragma mark -

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDrawer:(id<LTTextureDrawer>)drawer
                      strategy:(id<LTProcessingStrategy>)strategy
          andAuxiliaryTextures:(NSDictionary *)auxiliaryTextures NS_UNAVAILABLE;

- (instancetype)initWithDrawer:(id<LTTextureDrawer>)drawer
                 sourceTexture:(LTTexture *)sourceTexture
             auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                     andOutput:(LTTexture *)output NS_UNAVAILABLE;

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                               input:(LTTexture *)input andOutput:(LTTexture *)output
    NS_UNAVAILABLE;

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                   auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                           andOutput:(LTTexture *)output NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
