// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// Extension augmenting the \c LTTexture class with convenience methods for copying the content of
/// the receiving texture into an axis-aligned rectangular subregion of another texture or another
/// already bound render target. The result is undefined if the pixel format of the receiver does
/// not equal the pixel format of the render target.
///
/// @important Calls to the convenience methods result in the creation and destruction of OpenGL
/// objects. Hence, the methods are not intended for high-frequency usage (e.g. every display link
/// frame). If copying needs to be performed with high frequency, hold an \c LTTextureBlitter
/// instead.
@interface LTTexture (RectCopying)

/// Copies the entire content of this instance to the given \c rect, provided in normalized
/// coordinates. A render target must be bound before calling this method.
- (void)copyToNormalizedRect:(CGRect)rect;

/// Copies the given \c rect, given in normalized coordinates, of the content of this instance to
/// the given \c targetRect, given in normalized coordinates. A render target must be bound before
/// calling this method.
- (void)copyNormalizedRect:(CGRect)rect toNormalizedRect:(CGRect)targetRect;

/// Copies the given \c rect, given in normalized coordinates, of the content of this instance to
/// the given \c targetRect, given in normalized coordinates, of the given \c texture.
- (void)copyNormalizedRect:(CGRect)rect toNormalizedRect:(CGRect)targetRect
                 ofTexture:(LTTexture *)texture;

/// Copies the entire content of this instance to the given \c rect, provided in floating-point
/// pixel units of this instance, of the given \c texture.
- (void)copyToRect:(CGRect)rect ofTexture:(LTTexture *)texture;

/// Copies the given \c rect, given in floating-point pixel units of this instance, of the content
/// of this instance to the given \c targetRect, given in floating-point pixel units of the given
/// \c texture.
- (void)copyRect:(CGRect)rect toRect:(CGRect)targetRect ofTexture:(LTTexture *)texture;

@end

NS_ASSUME_NONNULL_END
