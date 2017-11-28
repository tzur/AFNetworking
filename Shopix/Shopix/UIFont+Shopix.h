// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Category for creating screen size adaptable fonts.
@interface UIFont (Shopix)

/// Returns a new font with size relative to the screen height specified by \c ratio. The font
/// size is limited by \c minSize and \c maxSize. \c weight specify the font weight.
+ (UIFont *)spx_fontWithSizeRatio:(CGFloat)ratio minSize:(NSUInteger)minSize
                          maxSize:(NSUInteger)maxSize weight:(UIFontWeight)weight;

/// Returns a new regular weighted font with size relative to the screen height specified by
/// \c ratio. The font size is limited by \c minSize and \c maxSize.
+ (UIFont *)spx_standardFontWithSizeRatio:(CGFloat)ratio minSize:(NSUInteger)minSize
                                  maxSize:(NSUInteger)maxSize;

@end

NS_ASSUME_NONNULL_END
