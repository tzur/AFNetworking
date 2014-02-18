// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@class LTTexture;

/// Possible directions of the Fourier transform to execute.
typedef NS_ENUM(NSUInteger, LTFFTTransformDirection) {
  LTFFTTransformDirectionForward = 0,
  LTFFTTransformDirectionInverse,
};

/// Defines what outputs should be normalized by the input size when executing inverse transform.
typedef NS_OPTIONS(NSUInteger, LTFFTNormalization) {
  LTFFTTransformNormalizeReal = 1 << 0,
  LTFFTTransformNormalizeImag = 1 << 1
};

/// Holds two separate real and imaginary data, to use with the FFT processor.
typedef struct {
  cv::Mat1f real;
  cv::Mat1f imag;
} LTSplitComplexMat;

/// Class for holding split complex output, as returned from the processor.
@interface LTSplitComplexOutput : NSObject <LTImageProcessorOutput>

/// Initializes with a single texture.
- (instancetype)initWithSplitComplexMat:(LTSplitComplexMat)splitComplexMat;

/// Output texture.
@property (readonly, nonatomic) LTSplitComplexMat splitComplexMat;

@end

/// Processor for executing FFT on the CPU. The input and output are given as a two split planes:
/// one for the real part and one for the imaginary part. Since the transform doesn't normalize by
/// default when executing an inverse transform, the normalization is being taken care as an
/// additional step. Therefore, it is possible to avoid normalization and  gain a possible
/// performance boost.
@interface LTFFTProcessor : NSObject <LTImageProcessor>

/// Initializes with a real input (so the imaginary part is considered all zeroed) and a complex
/// output struct.
- (instancetype)initWithRealInput:(const cv::Mat1f &)realInput output:(LTSplitComplexMat *)output;

/// Initializes with a complex input and a complex output structs.
- (instancetype)initWithInput:(LTSplitComplexMat)input output:(LTSplitComplexMat *)output;

/// Direction of the Fourier transform to execute. Default value is LTFFTTransformDirectionForward.
@property (nonatomic) LTFFTTransformDirection transformDirection;

/// Specifies which outputs should be normalized by the input size when executing an inverse
/// transform. By default, both real and imag planes will be normalized.
@property (nonatomic) LTFFTNormalization normalization;

@end
