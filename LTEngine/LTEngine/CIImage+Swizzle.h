// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

/// Category for swizzling the color components of a \c CIImage.
@interface CIImage (Swizzle)

/// Returns a swizzled image whose red and blue channels are switched, effectively converting an
/// \c RGBA image to a \c BGRA image and vice versa.
- (CIImage *)lt_swizzledImage;

@end

NS_ASSUME_NONNULL_END
