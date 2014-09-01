// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import <UIKit/UIColor.h>

@interface UIColor (Vector)

/// Returns the \c UIColor generated from the given rgba vector.
+ (UIColor *)lt_colorWithLTVector:(LTVector4)vector;

/// Returns the \c LTVector4 representation of the color.
@property (readonly, nonatomic) LTVector4 lt_ltVector;

/// Returns the \c cv::Vec4b representation of the color.
@property (readonly, nonatomic) cv::Vec4b lt_cvVector;

@end
