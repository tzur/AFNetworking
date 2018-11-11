// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Category for EnlightUI fonts.
@interface UIFont (EnlightUI)

+ (UIFont *)eui_mainLabelFontWithSize:(CGFloat)size;
+ (UIFont *)eui_secondaryLabelFontWithSize:(CGFloat)size;
+ (UIFont *)eui_mainTextFontWithSize:(CGFloat)size;
+ (UIFont *)eui_additionalsFontWithSize:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
