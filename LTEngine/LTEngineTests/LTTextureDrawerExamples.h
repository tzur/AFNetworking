// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureDrawer.h"

@class LTRotatedRect;

/// Texture drawers examples shared group name.
extern NSString * const kLTTextureDrawerExamples;

/// Class object, implementing the LTTextureDrawer protocol to test.
extern NSString * const kLTTextureDrawerClass;

/// Indicates whether the initialization tests should be skipped (for example, if the subclass has a
/// different designated initializer).
extern NSString * const kLTTextureDrawerSkipInitializationTests;

/// Returns a rotated subrect of the given \c cv::Mat.
cv::Mat4b LTRotatedSubrect(const cv::Mat4b input, LTRotatedRect *subrect);
