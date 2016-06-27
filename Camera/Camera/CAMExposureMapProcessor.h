// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import <LTEngine/LTOneShotImageProcessor.h>

NS_ASSUME_NONNULL_BEGIN

/// Processor for calculating the "well-exposedness" of an image in each pixel. Used in HDR Fusion.
/// Based on part of the scoring used in <tt>Mertens, T., Kautz, J., & Van Reeth, F. (2007).
/// Exposure fusion.</tt>
@interface CAMExposureMapProcessor : LTOneShotImageProcessor

/// Initializes with an input and an output texture.
///
/// @note \c output texture must be the same size as \c input and be of type
/// \c LTGLPixelFormatR16Float.
///
/// @note \c input texture must use \c LTTextureInterpolationNearest for both min and mag filters.
- (instancetype)initWithTexture:(LTTexture *)input output:(LTTexture *)output;

@end

NS_ASSUME_NONNULL_END
