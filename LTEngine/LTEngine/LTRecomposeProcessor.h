// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@protocol LTDistributionSamplerFactory;

@class LTTexture;

/// Processor for recomposing an image by decimating some of its lines (either vertically or
/// horizontally). This process is user-assisted, given the supplied \c mask that marks important
/// areas in the image (black) against areas that can be discarded (white).
///
/// @note for performance and design reasons, this processor doesn't change the size of the output
/// texture (which is sized as the \c input texture), but draws the result centered at the output
/// texture, keeping the unused area transparent. Therefore, additional cropping may be needed post
/// processing, as suggested by \c recomposedRect.
@interface LTRecomposeProcessor : LTImageProcessor

/// Initializes with an input image, a mask with the same size as \c input and an output texture.
/// The given mask controls what parts of the image should be kept when decimating the image.
- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask output:(LTTexture *)output;

/// Number of rows to decimate. This value must be in the range \c [0,input.size.height], default is
/// \c 0.
@property (nonatomic) NSUInteger rowsToDecimate;

/// Number of columns to decimate. This value must be in the range \c [0,input.size.width], default
/// is \c 0.
@property (nonatomic) NSUInteger colsToDecimate;

/// Returns the rectangle (in content coordiantes) containing the recomposed image inside the output
/// texture.
@property (readonly, nonatomic) CGRect recomposedRect;

@end

@interface LTRecomposeProcessor (ForTesting)

/// Sampler factory to use when creating sampler for sampling lines to decimate. Default value is \c
/// LTInverseTransformSamplerFactory.
@property (nonatomic) id<LTDistributionSamplerFactory> samplerFactory;

@end
