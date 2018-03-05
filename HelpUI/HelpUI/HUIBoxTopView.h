// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

NS_ASSUME_NONNULL_BEGIN

/// View that displays a top box of a help box. This view may contain a main title, an icon and an
/// additional text body.
///
/// \c title is displayed using a view that has "Title" accessibility identifier.
/// \c body is displayed using a view that has "Body" accessibility identifier.
/// \c body is displayed using a view that has "Icon" accessibility identifier.
@interface HUIBoxTopView : UIView

/// Returns the wanted height for a \c HUIBoxTopView that contains the given \c title, \c body and
/// \c iconURL for a given \c boxTopWidth.
+ (CGFloat)boxTopHeightForTitle:(nullable NSString *)title body:(nullable NSString *)body
                        iconURL:(nullable NSURL *)iconURL width:(CGFloat)boxTopWidth;

/// Title of the view. The text in the title view is set with the string that is returned from
/// invoking \c uppercaseString method on this property.
@property (strong, nonatomic, nullable) NSString *title;

/// Additional textual description, shown below the \c title.
@property (strong, nonatomic, nullable) NSString *body;

/// The URL of the icon that is presented next to the \c title.
@property (strong, nonatomic, nullable) NSURL *iconURL;

@end

NS_ASSUME_NONNULL_END
