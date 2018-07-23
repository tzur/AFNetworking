// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Class of objects providing methods for copying the content of an \c LTTexture, the so-called
/// \c sourceTexture, into an axis-aligned rectangular subregion of another texture, the so-called
/// \c targetTexture, or another already bound render target. The result is undefined if the pixel
/// format of the \c sourceTexture does not equal the pixel format of the \c targetTexture or the
/// bound render target, respectively.
@interface LTTextureBlitter : NSObject

/// Copies the entire content of the given \c texture to the given \c rect, provided in normalized
/// coordinates. A render target must be bound while calling this method.
- (void)copyTexture:(LTTexture *)texture toNormalizedRect:(CGRect)rect;

/// Copies the given \c rect, given in normalized coordinates, of the content of the given\c texture
/// to the given \c targetRect, given in normalized coordinates. A render target must be bound while
/// calling this method.
- (void)copyNormalizedRect:(CGRect)rect ofTexture:(LTTexture *)texture
          toNormalizedRect:(CGRect)targetRect;

/// Copies the given \c rect, given in normalized coordinates, of the content of the given
/// \c sourceTexture to the given \c targetRect, given in normalized coordinates, in the given
/// \c targetTexture.
- (void)copyNormalizedRect:(CGRect)rect ofTexture:(LTTexture *)sourceTexture
          toNormalizedRect:(CGRect)targetRect ofTexture:(LTTexture *)targetTexture;

/// Copies the entire content of the given \c sourceTexture to the given \c rect, provided in
/// floating-point pixel units, in the given \c targetTexture.
- (void)copyTexture:(LTTexture *)sourceTexture toRect:(CGRect)rect
          ofTexture:(LTTexture *)targetTexture;

/// Copies the given \c rect, given in floating-point pixel units, of the content of the given
/// \c sourceTexture to the given \c targetRect, given in floating-point pixel units, in the given
/// \c targetTexture.
- (void)copyRect:(CGRect)rect ofTexture:(LTTexture *)sourceTexture toRect:(CGRect)targetRect
       ofTexture:(LTTexture *)targetTexture;

@end

NS_ASSUME_NONNULL_END
