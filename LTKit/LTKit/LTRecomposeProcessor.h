// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@protocol LTDistributionSamplerFactory;

/// Dimension to recompose across.
typedef NS_ENUM(NSUInteger, LTRecomposeDecimationDimension) {
  LTRecomposeDecimationDimensionHorizontal = 0,
  LTRecomposeDecimationDimensionVertical,
};

/// Processor for recomposing an image by decimating some of its lines (either vertically or
/// horizontally). This process is user-assisted, given the supplied \c mask that marks important
/// areas in the image (white) against areas that can be discarded (black).
///
/// @note for performance and design reasons, this processor doesn't change the size of the output
/// texture (which is sized as the \c input texture), but draws the result from (0, 0) and keeps
/// unused area of the output texture untouched. Therefore, additional cropping may be needed post
/// processing.
@interface LTRecomposeProcessor : LTImageProcessor

/// Initializes with an input image, a mask with the same size as \c input and an output texture.
/// The given mask controls what parts of the image should be kept when decimating the image.
- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask output:(LTTexture *)output;

/// Refreshes the internal mask cache. One must call this method if the mask contents has been
/// changed after initialization.
- (void)setMaskUpdated;

/// Dimension the image will be decimated on. The default value is \c
/// LTRecomposeDecimationDimensionHorizontal if \c input.size.height > input.size.width, otherwise
/// \c LTRecomposeDecimationDimensionVertical. Setting this value will truncate \c linesToDecimate
/// to its maximal possible value, if needed.
@property (nonatomic) LTRecomposeDecimationDimension decimationDimension;

/// Number of lines to decimate across the \c decimationDimension. This value must be in the range
/// \c (0, input.size.[width|height]), where [width|height] is set according to \c
/// decimationDimension. The default value is \c 0.
@property (nonatomic) NSUInteger linesToDecimate;

@end

@interface LTRecomposeProcessor (ForTesting)

/// Sampler factory to use when creating sampler for sampling lines to decimate. Default value is \c
/// LTInverseTransformSamplerFactory.
@property (nonatomic) id<LTDistributionSamplerFactory> samplerFactory;

@end
