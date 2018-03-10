// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

NS_ASSUME_NONNULL_BEGIN

/// Cell for showing a visual resource inside the help view.
@interface HUIResourceCell : UICollectionViewCell

/// Returns the wanted height for \c HUIResourceCell that contains the given \c title, \c body and
/// \c iconURL, for a given \c cellWidth.
+ (CGFloat)cellHeightForTitle:(nullable NSString *)title body:(nullable NSString *)body
                      iconURL:(nullable NSURL *)iconURL width:(CGFloat)cellWidth;

@end

NS_ASSUME_NONNULL_END
