// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Value class for the subscription screen generic colors.
@interface SPXColorScheme : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with all the colors theme.
- (instancetype)initWithMainColor:(UIColor *)mainColor
                        textColor:(UIColor *)textColor
                    darkTextColor:(UIColor *)darkTextColor
                  grayedTextColor:(UIColor *)grayedTextColor
                  backgroundColor:(UIColor *)backgroundColor NS_DESIGNATED_INITIALIZER;

/// Main app color.
@property (readonly, nonatomic) UIColor *mainColor;

/// Main app gradient colors. Must have at least two elements. Defaults to
/// <tt>[mainColor, mainColor]</tt>.
@property (copy, nonatomic) NSArray<UIColor *> *mainGradientColors;

/// Main mutli-app gradient colors. Must have at least two elements. Defaults to
/// <tt>[mainColor, mainColor]</tt>.
@property (copy, nonatomic) NSArray<UIColor *> *multiAppGradientColors;

/// Regular bright text color.
@property (readonly, nonatomic) UIColor *textColor;

/// Dark text color for bright backgrounds.
@property (readonly, nonatomic) UIColor *darkTextColor;

/// Grayed out text color.
@property (readonly, nonatomic) UIColor *grayedTextColor;

/// General views background color.
@property (readonly, nonatomic) UIColor *backgroundColor;

/// Border color. \c nil if there is no border.
@property (strong, nonatomic, nullable) UIColor *borderColor;

@end

NS_ASSUME_NONNULL_END
