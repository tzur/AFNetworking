// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

@protocol MTLBuffer;

/// Performs histogram specification operation on a given \c MTLBuffer, converting the pixels such
/// that the histogram matches the reference histogram on a given orthogonal basis (the change of
/// basis is performed on the fly, and the provided cumulative distribution function (CDF) of the
/// input and inverse CDF of the reference are assumed to be in this basis). Input is expected to be
/// float RGBA, and the alpha channel is ignored.
@interface PNKColorTransferHistogramSpecification : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c device, number of bins in the histograms the CDF and inverse CDF
/// were derived from, and a damping factor used for limiting the progress towards the reference's
/// palette in each iteration, increasing the chance of convergence.
- (instancetype)initWithDevice:(id<MTLDevice>)device histogramBins:(NSUInteger)histogramBins
                 dampingFactor:(float)dampingFactor NS_DESIGNATED_INITIALIZER;

/// Encodes the operations performed by the kernel to \c commandBuffer, using \c dataBuffer as
/// input/output, using the 3x3 change of basis transformation in \c transformBuffer to switch basis
/// (and back) on the fly. Specification is performed using the per-channel CDFs of the input and
/// inverse CDFs of the reference, both describing values uniformly distributed between the minimum
/// and maximum values provided in \c minValueBuffer and \c maxValueBuffer.
///
/// @note \c dataBuffer must contain float RGBA pixels, the alpha channel is ignored and exists only
/// due to Metal size and alignment requirements.
/// @note \c minValueBuffer and \c maxValueBuffer must contain at least \c 4 floats, and the last
/// channel is ignored.
/// @note \c transformBuffer should represent a \c 3x3 float matrix in \c 12 floats due to padding,
/// such that each 4th float is ignored.
/// @note \c inputCDFBuffers must contain \c 3 buffers of <tt>histogramBins * sizeof(float)</tt>
/// bytes.
/// @note \c referenceInverseCDFBuffers must contain \c 3 buffers of <tt>histogramBins *
/// inverseCDFScaleFactor * sizeof(float)</tt> bytes.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   dataBuffer:(id<MTLBuffer>)dataBuffer
              transformBuffer:(id<MTLBuffer>)transformBuffer
               minValueBuffer:(id<MTLBuffer>)minValueBuffer
               maxValueBuffer:(id<MTLBuffer>)maxValueBuffer
              inputCDFBuffers:(NSArray<id<MTLBuffer>> *)inputCDFBuffers
   referenceInverseCDFBuffers:(NSArray<id<MTLBuffer>> *)referenceInverseCDFBuffers;

/// Number of bins in the histograms the input CDF and reference inverse CDF were dervied from.
@property (readonly, nonatomic) NSUInteger histogramBins;

/// Damping factor for progress of each iteration towards the reference. Lower values yield smaller
/// steps towards the reference's palette in each iteration, but increase the chance of convergence.
/// Must be in range <tt>[0, 1]</tt>, default is \c 0.2.
@property (readonly, nonatomic) float dampingFactor;

@end

NS_ASSUME_NONNULL_END
