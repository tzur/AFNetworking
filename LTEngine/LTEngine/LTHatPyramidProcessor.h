// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTPyramidProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Processor for creating an image pyramid out of an input image. It extends \c LTPyramidProcessor
/// by offering a smoothing kernel consistent with the classical hat filter pyramid from Adelson's
/// article <tt>(E. Adelson, C. Anderson, RCA Engineer 29, 33-41 (1984))</tt>. The smoothing is
/// performed by applying a direct 5x5 hat kernel on the higher resolution texture.
@interface LTHatPyramidProcessor : LTPyramidProcessor

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with an input and a set of outputs. All textures must use
/// \c LTTextureInterpolationNearest as the interpolation method for both min and mag filters.
/// It's recommended to set the input min/mag filters first and then use <tt>LTPyramidProcessor's
/// levelsForInput:</tt> to generate the output textures before calling this initializer.
- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray<LTTexture *> *)outputs
    NS_DESIGNATED_INITIALIZER;

/// Convenience initializer that creates an output array using <tt>LTPyramidProcessor's
/// levelsForInput:</tt> with the maximal number of pyramid levels.
- (instancetype)initWithInput:(LTTexture *)input;

@end

NS_ASSUME_NONNULL_END
