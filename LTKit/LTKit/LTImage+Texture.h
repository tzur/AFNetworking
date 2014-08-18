// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage.h"

@class LTTexture;

/// Category for loading a \c UIImage directly to \c LTTexture, without allocating an intermediary
/// buffer between the two.
@interface LTImage (Texture)

/// Allocates and fills a texture with the given \c image, without using an intermediary buffer.
+ (LTTexture *)textureWithImage:(UIImage *)image;

@end
