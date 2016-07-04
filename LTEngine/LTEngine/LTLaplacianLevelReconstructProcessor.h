// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTOneShotImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Processor that reconstructs an image in a gaussian pyramid level from its laplacian pyramid
/// level representation and lower resolution gaussian pyramid level (one level higher).
/// The processor also allows boosting the laplacian representation level to create a detail
/// enhancement operation.
@interface LTLaplacianLevelReconstructProcessor : LTOneShotImageProcessor

/// Initializer for reconstructing a gaussian pyramid level from the laplacian pyramid level and
/// lower resolution gaussian level. Reconstruction is done while applying a boost to the laplacian
/// details level for details enhancement or supression. No explicit clipping is done to results.
/// Does the inverse operation of \c LTLaplacianLevelConstructProcessor.
///
/// @param baseLaplacianLevel Laplacian pyramid level of the same size as the resulting gaussian
/// level. Texture is exepcted to be of floating point data type.
///
/// @param baseLaplacianLevelBoost a scalar multiplied onto the base laplacian level (detail level).
/// Set this parameter to \c 1 in order to keep the details level unchanged.
///
/// @param higherLevel Gaussian pyramid level, one level higher (smaller) than
/// \c baseLaplacianLevel. Texture min and mag interpolation filters must be set to
/// \c LTTextureInterpolationNearest.
///
/// @param outputTexture the resulting gaussian level, the same size as \c baseLaplacianLevel.
- (instancetype) initWithBaseLaplacianLevel:(LTTexture *)baseLaplacianLevel
                    baseLaplacianLevelBoost:(CGFloat)baseLevelBoost
                        higherGaussianLevel:(LTTexture *)higherGaussianLevel
                              outputTexture:(LTTexture *)outputTexture NS_DESIGNATED_INITIALIZER;

/// Convenience initializer for reconstructing the gaussian pyramid level without any enhancement or
/// supression of the details level.
- (instancetype) initWithBaseLaplacianLevel:(LTTexture *)baseLaplacianLevel
                        higherGaussianLevel:(LTTexture *)higherGaussianLevel
                              outputTexture:(LTTexture *)outputTexture;

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
