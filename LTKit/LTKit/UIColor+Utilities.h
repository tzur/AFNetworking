// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Various utilities for \c UIColor conversion and creation.
@interface UIColor (Utilities)

/// Returns an instance of \c UIColor associated with the given hex string. The string can be in one
/// of the following formats, where the hash sign is optional: {#RGB, #ARGB, #RRGGBB, #AARRGGBB}.
/// If the format is invalid, an exception will be thrown.
+ (UIColor *)lt_colorWithHex:(NSString *)hex;

/// Returns the hex string associated with the color, in #AARRGGBB format.
- (NSString *)lt_hexString;

/// Returns a linearly interpolated color between \c start and \c end colors, controlled by the
/// parameter \c t, which will be clamped to \c [0, 1]. The \c start and \c end colors must be
/// created with RGB colorspace.
+ (UIColor *)lt_lerpColorFrom:(UIColor *)start to:(UIColor *)end parameter:(CGFloat)t;

@end

NS_ASSUME_NONNULL_END
