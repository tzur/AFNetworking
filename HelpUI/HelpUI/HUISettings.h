// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

@class HUIItem;

/// Singleton for global settings that can be used by all of the HelpUI classes.
@interface HUISettings : NSObject

/// Returns the singleton instance.
+ (instancetype)instance;

- (instancetype)init NS_UNAVAILABLE;

/// Type for block that localizes an \c NSString.
typedef NSString *_Nullable(^HUILocalizationBlock)(NSString *);

/// Localizes the given \c text using the \c localizationBlock property. If \c localizationBlock is
/// \c nil, returns the given \c text.
- (NSString *)localize:(NSString *)text;

/// Used to localize strings. In case it is \c nil, no localization is done. Defaults to \c nil.
@property (nonatomic, nullable) HUILocalizationBlock localizationBlock;

/// Aspect ratio of the content of a help card. Defaults to \c 1.0.
@property (nonatomic) CGFloat contentAspectRatio;

/// Color for the background of the help view. Defaults to
/// <tt>[UIColor lt_colorWithHex:@"#000000"]</tt>
@property (strong, nonatomic) UIColor *helpViewBackgroundColor;

/// Color for the top of the help card title box gradient. Defaults to
/// <tt>[UIColor lt_colorWithHex:@"#202023"]</tt>
@property (strong, nonatomic) UIColor *titleBoxGradientTopColor;

/// Color for the bottom of the help card title box gradient. Defaults to
/// <tt>[UIColor lt_colorWithHex:@"#000000"]</tt>
@property (strong, nonatomic) UIColor *titleBoxGradientBottomColor;

/// Color for the icon of the help card title box. Defaults to
/// <tt>[UIColor lt_colorWithHex:@"#FFFFFF"]</tt>
@property (strong, nonatomic) UIColor *titleBoxIconColor;

/// Color for the highlighted icon of the help card title box. Defaults to
/// <tt>[UIColor lt_colorWithHex:@"#FFFFFF"]</tt>
@property (strong, nonatomic) UIColor *titleBoxHighlightedIconColor;

/// Color for the headline of the help card title box. Defaults to
/// <tt>[[UIColor lt_colorWithHex:@"#FFFFFF"] colorWithAlphaComponent:0.9]</tt>
@property (strong, nonatomic) UIColor *titleBoxHeadlineColor;

/// Color for the body of the help card title box. Defaults to
/// <tt>[[UIColor lt_colorWithHex:@"#FFFFFF"] colorWithAlphaComponent:0.8]</tt>
@property (strong, nonatomic) UIColor *titleBoxBodyColor;

/// Color for the background of the help card box. Defaults to
/// <tt>[UIColor lt_colorWithHex:@"#000000"]</tt>
@property (strong, nonatomic) UIColor *boxBackgroundColor;

/// Font weight for the headline of the help card title box. Defaults to \c UIFontWeightBold
@property (nonatomic) UIFontWeight titleBoxHeadlineFontWeight;

/// Font weight for the body of the help card title box. Defaults to \c UIFontWeightLight
@property (nonatomic) UIFontWeight titleBoxBodyFontWeight;

@end

NS_ASSUME_NONNULL_END
