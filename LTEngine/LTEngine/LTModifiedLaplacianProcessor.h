// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTOneShotImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Processor that creates a score map using the normalized modified laplacian filter. The result is
/// a grayscale image such that whiter pixels indicate areas of higher contrast and in particular
/// areas in focus. The filter is normalized by the number of gradient samples (8) in order to allow
/// full range in 8 bit precision outputs.
@interface LTModifiedLaplacianProcessor : LTOneShotImageProcessor

/// Initializes with an \c input texture and an \c output texture of the same size.
///
/// @param input must use \c LTTextureInterpolationNearest for both min and mag filters.
///
/// @param output must be a single channel texture. \c output precision may impact results since
/// the modified laplacian operator is not limited to the range of the original \input texture.
///
/// @param pixelStep determines the distance of the neighbours from the center pixel used in the
/// calculation of the modified laplacian
- (instancetype)initWithTexture:(LTTexture *)input
                         output:(LTTexture *)output
                  pixelStepSize:(float)pixelStep NS_DESIGNATED_INITIALIZER;

/// Convenience initializer for using the default of <tt>pixelStep == 1</tt>.
- (instancetype)initWithTexture:(LTTexture *)input output:(LTTexture *)output;

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
