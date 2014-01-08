// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import <UIKit/UIColor.h>

@interface UIColor (GLKVector)

/// Returns the \c GLKVector4 representation of the color.
@property (readonly, nonatomic) GLKVector4 glkVector;

/// Returns the \c cv::Vec4b representation of the color.
@property (readonly, nonatomic) cv::Vec4b cvVector;

@end
