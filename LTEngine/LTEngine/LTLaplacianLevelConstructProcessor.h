// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTOneShotImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Processor that constructs a single level of a laplacian pyramid from the corresponding gaussian
/// pyramid levels (the same level and one level higher).
@interface LTLaplacianLevelConstructProcessor : LTOneShotImageProcessor

/// Initializes the processor for constructing a single laplacian pyramid level.
///
/// @param baseLevel Gaussian pyramid level of the same size as the resulting laplacian level.
///
/// @param higherLevel Gaussian pyramid level one level higher (smaller).
///
/// @param outputTexture Laplacian level result. Texture must be the same size as \c baseLevel
/// and be of floating point precision.
- (instancetype)initWithBaseGaussianLevel:(LTTexture *)baseLevel
                      higherGaussianLevel:(LTTexture *)higherLevel
                            outputTexture:(LTTexture *)outputTexture NS_DESIGNATED_INITIALIZER;

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
