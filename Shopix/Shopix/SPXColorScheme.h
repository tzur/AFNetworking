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
                  greyedTextColor:(UIColor *)greyedTextColor
                  backgroundColor:(UIColor *)backgroundColor NS_DESIGNATED_INITIALIZER;

/// Main app color.
@property (readonly, nonatomic) UIColor *mainColor;

/// Regular bright text color.
@property (readonly, nonatomic) UIColor *textColor;

/// Dark text color for bright backgrounds.
@property (readonly, nonatomic) UIColor *darkTextColor;

/// Greyed out text color.
@property (readonly, nonatomic) UIColor *greyedTextColor;

/// General views background color.
@property (readonly, nonatomic) UIColor *backgroundColor;

@end

NS_ASSUME_NONNULL_END
