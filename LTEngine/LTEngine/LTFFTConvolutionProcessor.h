// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@class LTSplitComplexMat;

/// Processor for executing convolutions using Fourier transform. This is usually handy for
/// convolving with large kernels (> 11x11). Because of implementation details, the inputs'
/// dimensions must be a power of two.
@interface LTFFTConvolutionProcessor : LTImageProcessor

/// Initializes with two float operands and a float output matrix. All inputs should have the same
/// dimensions, which should be a power of two.
- (instancetype)initWithFirstOperand:(const cv::Mat1f &)first
                       secondOperand:(const cv::Mat1f &)second
                              output:(cv::Mat1f *)output;

/// Initializes with first already-transformed operand and second non-transformed operand. All
/// inputs should have the same dimensions, which should be a power of two.
- (instancetype)initWithFirstTransformedOperand:(LTSplitComplexMat *)firstTransformed
                                  secondOperand:(const cv::Mat1f &)second
                                         output:(cv::Mat1f *)output;

/// Should result be shifted back. If set to \c NO, the output will be cyclically translated to
/// (width / 2, height / 2). The default value is \c YES.
@property (nonatomic) BOOL shiftResult;

@end
