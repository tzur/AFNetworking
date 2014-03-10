// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Data structure for holding complex plane as two split matrices: real and imaginary.
@interface LTSplitComplexMat : NSObject

/// Initializes with two empty, uninitialized matrices.
- (instancetype)init;

/// Initializes with a real and imaginary matrix.
///
/// @note designated initializer.
- (instancetype)initWithReal:(const cv::Mat1f &)real imag:(const cv::Mat1f &)imag;

/// Real matrix.
@property (readonly, nonatomic) cv::Mat1f &real;

/// Imaginary matrix.
@property (readonly, nonatomic) cv::Mat1f &imag;

@end
