// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTImageProcessor.h"

@class LTTexture;

NS_ASSUME_NONNULL_BEGIN

/// Block for getting the multiplicative factor for each laplacian level in the reconstruction
/// process.
typedef float (^LTLaplacianLevelBoostBlock)(NSUInteger currentLevel);

/// Reconstructs a laplacian pyramid into a texture the size of the finest level in the pyramid.
/// This processor allows for linear detail manipulation by multiplying each laplacian level with
/// a scalar factor which is a function of the level in which it is operating.
@interface LTLaplacianPyramidReconstructProcessor : LTImageProcessor

/// Initializes with a laplacian pyramid representation of an image and a boosting function to
/// determine the multiplication factor for each laplacian level.
///
/// @param laplacianPyramid an array representation of the laplacian pyramid as created by
/// processors such as \c LTLaplacianPyramidProcessor and \c LTLaplacianFusionProcessor.
///
/// @param output the resulting image, the same size as the finest level of \c laplacianPyramid.
///
/// @param inPlaceProcessing when \c YES the pyramid reconstruction overwrites the data in the
/// \c laplacianPyramid array in order to create texture. In this case the \c process method must
/// not be called more than once. This excludes <tt>laplacianPyramid.firstObject</tt> which always
/// remains unchanged. When \c NO it utilizes auxiliary textures and does not change the content of
/// \c laplacianPyramid. setting \c inPlaceProcessing to \c NO is useful when the boosting function
/// used in the processor has parameters that can be modified by an external caller (i.e. for screen
/// processing).
///
/// @param boostingFunction a block with the current level operated on as input which returns a
/// scalar factor by which the current laplacian level will be multiplied before reconstruction.
/// This block will be called with values in the range <tt>[1, laplacianPyramid.count - 1]</tt>.
- (instancetype)initWithLaplacianPyramid:(NSArray<LTTexture *> *)laplacianPyramid
                           outputTexture:(LTTexture *)output
                       inPlaceProcessing:(BOOL)inPlaceProcessing
                        boostingFunction:(LTLaplacianLevelBoostBlock)boostingFunction
    NS_DESIGNATED_INITIALIZER;

/// Convenience initializer that uses the identity function for \c boostingFunction.
- (instancetype)initWithLaplacianPyramid:(NSArray<LTTexture *> *)laplacianPyramid
                           outputTexture:(LTTexture *)output
                       inPlaceProcessing:(BOOL)inPlaceProcessing;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
