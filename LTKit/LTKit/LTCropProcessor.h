// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTImageProcessor.h"

@class LTTexture;

/// This class is used for performing crop related operations on the image. The manipulations can be
/// categorized into the three following categories: crop, rotate, perspective mapping.
@interface LTCropProcessor : LTImageProcessor

/// Initializes the processor with the given input texture.
- (instancetype)initWithInput:(LTTexture *)input;

/// Returns the most recent processing output.
///
/// @note This texture might have different dimensions according to the rotation and cropping that
/// were performed.
@property (readonly, nonatomic) LTTexture *outputTexture;

/// If \c YES, the processor will crop the texture according to the \c cropRectangle. Otherwise,
/// only rotation and flipping will be performed.
@property (nonatomic) BOOL applyCrop;

/// If \c YES, the image will be flipped around the Y axis.
@property (nonatomic) BOOL flipHorizontal;

/// If \c YES, the image will be flipped around the X axis.
@property (nonatomic) BOOL flipVertical;

/// Number of 90 degrees clockwise rotations that should be applied.
@property (nonatomic) NSInteger rotations;

/// Rectangle defining the area to crop (in pixels), in a coordinate system reflecting the input
/// after the rotations and flips according to the processor's properties.
///
/// @note The rectangle will be automatically updated when the \c rotations, \c flipHorizontal, and
/// \c flipVertical properties are updated, to reflect the same area in the input image.
@property (nonatomic) CGRect cropRectangle;

@end
