// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

@protocol MTLBuffer;

/// Computes the cumulative distribution functions (CDF) of the given input histogram and the
/// approximate inverse CDFs of the reference histogram. These histograms can be used to find for
/// every x <tt>x' such that CDF_r(x') = CDF_i(x)</tt>. Both histograms contain multiple
/// one-dimensional histograms (for each channel) and the alpha channel is ignored. The inverse CDFs
/// are represented by more values to reach a closer approximation of the inverse function.
///
/// @note The PDFs computed from the histograms in order to calculate the CDFs are filtered using a
/// small gaussian kernel to remove high-frequencies. Size and sigma parameters of this gaussian
/// kernel are fixed and can be read from \c pdfSmoothingKernelSize and \c pdfSmoothingKernelSigma
/// properties of this class.
@interface PNKColorTransferCDF : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c device and desired number of bins in the histogram used to
/// calculate the CDF from.
- (instancetype)initWithDevice:(id<MTLDevice>)device histogramBins:(NSUInteger)histogramBins
    NS_DESIGNATED_INITIALIZER;

/// Encodes the operations performed by the kernels to \c commandBuffer, calculating the CDFs of
/// the per-channel histograms in \c inputHistogramBuffer and inverse CDFs of the per-channel
/// histograms in \c referenceHistogramBuffer. Both histogram buffers are assumed to contain
/// <tt>4 * histogramBins uint32_t</tt>, where the fourth channel is ignored (Metal padding
/// requirements). The histogram bins are equally distributed between the per channel minimum and
/// maximum values defined in \c minValueBuffer and \c maxValueBuffer, which affects the inverse CDF
/// of the reference. The per channel CDF of the input is written to the three buffers provided in
/// \c cdfBuffers and the per channel inverse CDF of the reference is written to the three buffers
/// in \c inverseCDFBuffers.
///
/// @note \c cdfBuffers must contain \c 3 buffers of <tt>histogramBins * sizeof(float)</tt> bytes.
/// @note \c inverseCDFBuffers must contain \c 3 buffers of <tt>histogramBins *
/// inverseCDFScaleFactor * sizeof(float)</tt> bytes.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
         inputHistogramBuffer:(id<MTLBuffer>)inputHistogramBuffer
     referenceHistogramBuffer:(id<MTLBuffer>)referenceHistogramBuffer
               minValueBuffer:(id<MTLBuffer>)minValueBuffer
               maxValueBuffer:(id<MTLBuffer>)maxValueBuffer
                   cdfBuffers:(NSArray<id<MTLBuffer>> *)cdfBuffers
            inverseCDFBuffers:(NSArray<id<MTLBuffer>> *)inverseCDFBuffers;

/// Ratio between the number of samples in the inverse CDF and CDF, in order to achieve a
/// sufficiently close approximate of the inverse function.
@property (class, readonly, nonatomic) NSUInteger inverseCDFScaleFactor;

/// Number of histogram entries, or "bins" for each channel.
@property (readonly, nonatomic) NSUInteger histogramBins;

/// Minimum supported number of histogram bins.
@property (class, readonly, nonatomic) NSUInteger minSupportedHistogramBins;

/// Maximum supported number of histogram bins.
@property (class, readonly, nonatomic) NSUInteger maxSupportedHistogramBins;

/// Size of the gaussian kernel used for smoothing the PDFs.
@property (class, readonly, nonatomic) NSUInteger pdfSmoothingKernelSize;

/// Sigma of the gaussian kernel used for smoothing the PDFs.
@property (class, readonly, nonatomic) float pdfSmoothingKernelSigma;

@end

NS_ASSUME_NONNULL_END
