// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Immutable class that calculates the frames for the subviews of \c HUIBoxTopView, and their
/// layout dependent properties (for example the attibuted strings of subviews that contains text).
/// The requirments for this layout are documented in file \c HelpUI_Design.jpg on Google Drive.
@interface HUIBoxTopLayout : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c bounds of the \c HUIBoxTopView and with the textual content of the
/// \c HUIBoxTopView (its \c title and \c body). The layout is affected by the existance of icon in
/// \c HUIBoxTopView, and thus the given \c hasIcon parameter should be \c YES if exists and \c NO
/// if doesn't.
- (instancetype)initWithBounds:(CGRect)bounds title:(nullable NSString *)title
                          body:(nullable NSString *)body hasIcon:(BOOL)hasIcon
    NS_DESIGNATED_INITIALIZER;

/// Calculated frame for the title of the \c HUIBoxTopView.
@property (readonly, nonatomic) CGRect titleFrame;

/// Calculated frame for the icon of the \c HUIBoxTopView.
@property (readonly, nonatomic) CGRect iconFrame;

/// Calculated frame for the body of the \c HUIBoxTopView.
@property (readonly, nonatomic) CGRect bodyFrame;

/// Intrinsic height for the \c HUIBoxTopView.
@property (readonly, nonatomic) CGFloat intrinsicHeight;

/// Attributed string for the title of the \c HUIBoxTopView. The \c string property of the
/// \c NSAttributedString is set with the string that is returned from invoking \c uppercaseString
/// method on the \c title given in the initializer. If the \c title given in the initializer is
/// \c nil the \c string property of this attributed string is an empty string.
@property (readonly, nonatomic) NSAttributedString *titleAttributedString;

/// Attributed string for the body of the \c HUIBoxTopView. If the \c body given in the initializer
/// is \c nil the \c string property of this attributed string is an empty string.
@property (readonly, nonatomic) NSAttributedString *bodyAttributedString;

@end

NS_ASSUME_NONNULL_END
