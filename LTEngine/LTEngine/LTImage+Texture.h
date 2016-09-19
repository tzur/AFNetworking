// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Category for loading a \c UIImage directly to \c LTTexture, without allocating an intermediary
/// buffer between the two.
@interface LTImage (Texture)

/// Allocates and fills a texture with the given \c image, without using an intermediary buffer.
+ (LTTexture *)textureWithImage:(UIImage *)image;

/// Allocates and fills a texture with the given \c image, without using an intermediary buffer. If
/// \c backgroundColor is set, the output texture will first be filled with the given color and then
/// the image will be drawn over it using normal blending mode. Otherwise no filling will be made
/// prior to the drawing, potentially preserving the transparency of the image.
+ (LTTexture *)textureWithImage:(UIImage *)image
                backgroundColor:(nullable UIColor *)backgroundColor;

/// Loads the given \c image to the given \c texture. The texture must be of the same size and
/// properties of the \c image.
+ (void)loadImage:(UIImage *)image toTexture:(LTTexture *)texture;

/// Loads the given \c image to the given \c texture. The texture must be of the same size and
/// properties of the \c image. If \c backgroundColor is set, the output texture will first be
/// filled with the given color and then the image will be drawn over it using normal blending mode.
/// Otherwise no filling will be made prior to the drawing, potentially preserving the transparency
/// of the image.
+ (void)loadImage:(UIImage *)image toTexture:(LTTexture *)texture
  backgroundColor:(nullable UIColor *)backgroundColor;

@end

NS_ASSUME_NONNULL_END
