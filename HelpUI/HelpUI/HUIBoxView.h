// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

NS_ASSUME_NONNULL_BEGIN

/// View that shows the help box template. It has a top view which displays \c title, \c body
/// and icon (given by \c iconURL), and a content area.
///
/// This box top view is displayed using a view that has "BoxTop" accessibility identifier.
@interface HUIBoxView : UIView

/// Returns the wanted height for a \c HUIBoxView that contains the given \c title, \c body, and
/// \c iconURL for a given \c boxWidth. The returned height is also affected by the
/// \c contentAspectRatio property of \c HUISettings that determines the content area height.
+ (CGFloat)boxHeightForTitle:(nullable NSString *)title body:(nullable NSString *)body
                     iconURL:(nullable NSURL *)iconURL width:(CGFloat)boxWidth;

/// Title of this box.
@property (strong, nonatomic, nullable) NSString *title;

/// Additional textual description, shown below the \c title.
@property (strong, nonatomic, nullable) NSString *body;

/// The URL of the icon that is presented next to the \c title.
@property (strong, nonatomic, nullable) NSURL *iconURL;

/// Container view where the actual content should be placed.
@property (readonly, nonatomic) UIView *contentView;

@end

NS_ASSUME_NONNULL_END
