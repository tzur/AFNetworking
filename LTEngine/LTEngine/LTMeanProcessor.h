// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTOneShotImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Processor for calculating the weighted mean of an array of textures.
///
/// @note The supported size of the input array is in the range
/// <tt>[2, GL_MAX_TEXTURE_IMAGE_UNITS]</tt>.
///
/// @note The alpha channel of the output will always be \c 1.
@interface LTMeanProcessor : LTOneShotImageProcessor

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with an \c input array of at least 2 textures and up to
/// \c GL_MAX_TEXTURE_IMAGE_UNITS textures. Textures are expected to be RGBA so that the Alpha
/// channel is the weight of the RGB pixels.
- (instancetype)initWithInputTextures:(NSArray<LTTexture *> *)input output:(LTTexture *)output
    NS_DESIGNATED_INITIALIZER;

/// Initializes and creates an output texture with the properties of the first texture in the array.
- (instancetype)initWithInputTextures:(NSArray<LTTexture *> *)input;

@end

NS_ASSUME_NONNULL_END
