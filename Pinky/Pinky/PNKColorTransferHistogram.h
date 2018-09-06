// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

@protocol MTLBuffer;

/// Computes the histogram per each channel for a given \c MTLBuffer after a given \c 3x3 linear
/// transformation is applied on them. Input is expected to be Float RGBA, and the alpha channel is
/// ignored. The transformation is applied on the fly, such that the input buffer is left unchanged.
API_AVAILABLE(ios(10.0))
@interface PNKColorTransferHistogram : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c device, desired number of bins in the histogram, and number of
/// pixels in the buffer that will be given as input.
- (instancetype)initWithDevice:(id<MTLDevice>)device histogramBins:(NSUInteger)histogramBins
                     inputSize:(NSUInteger)inputSize NS_DESIGNATED_INITIALIZER;

/// Encodes the operations performed by the kernels to \c commandBuffer, using \c inputBuffer as
/// input while applying the \c 3x3 transformation in \c transformBuffer on the fly during the
/// calculation such that it is left unchanged. Output is written to \c histogramBuffer which is
/// expected to contain <tt>4 * histogramBins * sizeof(uint32_t)</tt>, where the fourth channel
/// exists due to Metal padding requirements and should be ignored. The bins are equally distributed
/// between the minimum and maximum values defined in \c minValueBuffer and \c maxValueBuffer, such
/// that every value is clamped between them for the purposes of histogram calculation.

/// @note \c minValueBuffer and \c maxValueBuffer must contain at least \c 4 floats, and the last
/// channel is ignored.
/// @note \c transformBuffer should represent a \c 3x3 float matrix in \c 12 floats due to padding,
/// such that each 4th float is ignored.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                  inputBuffer:(id<MTLBuffer>)inputBuffer
              transformBuffer:(id<MTLBuffer>)transformBuffer
               minValueBuffer:(id<MTLBuffer>)minValueBuffer
               maxValueBuffer:(id<MTLBuffer>)maxValueBuffer
              histogramBuffer:(id<MTLBuffer>)histogramBuffer;

/// Number of histogram entries, or "bins" for each channel.
@property (readonly, nonatomic) NSUInteger histogramBins;

/// Number of pixels in the input buffer that will be provided.
@property (readonly, nonatomic) NSUInteger inputSize;

/// Maximum supported number of histogram bins.
@property (class, readonly, nonatomic) NSUInteger maxSupportedHistogramBins;

@end

NS_ASSUME_NONNULL_END
