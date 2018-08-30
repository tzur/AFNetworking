// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferCDF.h"

#import <LTKit/NSArray+Functional.h>

#import "PNKColorTransferCDFConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKColorTransferCDF ()

/// Device to encode kernel operations.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Compiled state of kernel that calculates the PDF of each channel of a given multi-channel
/// histogram, and filtering it with a given gaussian kernel.
@property (readonly, nonatomic) id<MTLComputePipelineState> calculatePDFState;

/// Compiled state of kernel that calculates the CDF of each channel of a given multi-channel PDF.
@property (readonly, nonatomic) id<MTLComputePipelineState> calculateCDFState;

/// Array of compiled states of kernels that calculate the approximate inverse of a given CDF. Each
/// state corresponds to a different channel, using the minimum and maximum values for that specific
/// channel.
@property (readonly, nonatomic) NSArray<id<MTLComputePipelineState>> *calculateInverseCDFState;

/// Buffer holding the multi-channel smooth PDF computed from histogram, used to compute the CDF.
@property (readonly, nonatomic) id<MTLBuffer> pdfBuffer;

/// Buffer holding the small gaussian kernel used for smoothing the PDFs.
@property (readonly, nonatomic) id<MTLBuffer> pdfSmoothingKernelBuffer;

/// Array of intermediate buffers to contain the CDFs of the reference histograms, in order to
/// calculate their approximate inverse.
@property (readonly, nonatomic) NSArray<id<MTLBuffer>> *referenceCDFBuffers;

@end

@implementation PNKColorTransferCDF

/// Ratio between the number of samples in the inverse CDF and CDF, in order to achieve a
/// sufficiently close approximate of the inverse function. Should be power of two.
static const NSUInteger kInverseCDFScaleFactor = 16;

/// Minimum number of histogram bins supported by the kernel.
static const NSUInteger kMinHistogramBins = 4;

/// Maximum number of histogram bins supported by the kernel, based on the available threadgroup
/// memory on the lower end devices.
static const NSUInteger kMaxHistogramBins = PNK_COLOR_TRANSFER_CDF_MAX_SUPPORTED_HISTOGRAM_BINS;

/// Size of the gaussian kernel used for smoothing the PDFs. Must be odd.
static const NSUInteger kPDFSmoothingKernelSize = 7;

/// Sigma of the gaussian kernel used for smoothing the PDFs. Must be positive.
static const float kPDFSmoothingKernelSigma = 1;

- (instancetype)initWithDevice:(id<MTLDevice>)device histogramBins:(NSUInteger)histogramBins {
  LTParameterAssert(histogramBins >= kMinHistogramBins && histogramBins <= kMaxHistogramBins,
                    @"Invalid histogram bins (%lu), must be in range [%lu,%lu].",
                    (unsigned long)histogramBins, (unsigned long)kMinHistogramBins,
                    (unsigned long)kMaxHistogramBins);

  if (self = [super init]) {
    _device = device;
    _histogramBins = histogramBins;

    [self createComputeStates];
    [self createBuffers];
  }
  return self;
}

- (void)createComputeStates {
  auto constants = @[
    [MTBFunctionConstant ushortConstantWithValue:self.histogramBins name:@"kHistogramBins"],
    [MTBFunctionConstant ushortConstantWithValue:kPDFSmoothingKernelSize
                                            name:@"kPDFSmoothingKernelSize"]
  ];

  _calculateCDFState = PNKCreateComputeState(self.device, @"calculateCDF", constants);

  _calculatePDFState = PNKCreateComputeState(self.device, @"calculatePDF", constants);

  _calculateInverseCDFState = [@[@0, @1, @2] lt_map:^id(NSNumber *index) {
    auto inverseConstants = @[
      [MTBFunctionConstant ushortConstantWithValue:kInverseCDFScaleFactor
                                              name:@"kInverseCDFScaleFactor"],
      [MTBFunctionConstant ushortConstantWithValue:index.unsignedShortValue name:@"kChannel"]
    ];
    auto inverseCDFConstants = [constants arrayByAddingObjectsFromArray:inverseConstants];
    return PNKCreateComputeState(self.device, @"calculateInverseCDF", inverseCDFConstants);
  }];
}

- (void)createBuffers {
  auto buffers = [NSMutableArray array];
  auto bufferLength = self.histogramBins * sizeof(float);
  for (NSUInteger i = 0; i < 3; ++i) {
    [buffers addObject:[self.device newBufferWithLength:bufferLength
                                                options:MTLResourceStorageModePrivate]];
  }
  _referenceCDFBuffers = buffers;
  _pdfBuffer = [self.device newBufferWithLength:bufferLength options:MTLResourceStorageModePrivate];

  [self createPDFSmoothingKernelBuffer];
}

- (void)createPDFSmoothingKernelBuffer {
  cv::Mat1f kernel = cv::getGaussianKernel(kPDFSmoothingKernelSize, kPDFSmoothingKernelSigma);
  _pdfSmoothingKernelBuffer = [self.device newBufferWithLength:kernel.total() * sizeof(float)
                                                       options:MTLResourceStorageModeShared];
  std::copy(kernel.begin(), kernel.end(), (float *)self.pdfSmoothingKernelBuffer.contents);
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
         inputHistogramBuffer:(id<MTLBuffer>)inputHistogramBuffer
     referenceHistogramBuffer:(id<MTLBuffer>)referenceHistogramBuffer
               minValueBuffer:(id<MTLBuffer>)minValueBuffer
               maxValueBuffer:(id<MTLBuffer>)maxValueBuffer
                   cdfBuffers:(NSArray<id<MTLBuffer>> *)cdfBuffers
            inverseCDFBuffers:(NSArray<id<MTLBuffer>> *)inverseCDFBuffers {
  NSUInteger minHistogramBuffersLength = self.histogramBins * 4 * sizeof(uint);
  LTParameterAssert(inputHistogramBuffer.length >= minHistogramBuffersLength,
                    @"Invalid input histogram buffer length (%lu): must be at greater than or "
                    "equal to %lu bytes", (unsigned long)inputHistogramBuffer.length,
                    (unsigned long)minHistogramBuffersLength);
  LTParameterAssert(referenceHistogramBuffer.length >= minHistogramBuffersLength,
                    @"Invalid reference histogram buffer length (%lu): must be greater than or "
                    "equal to %lu bytes", (unsigned long)referenceHistogramBuffer.length,
                    (unsigned long)minHistogramBuffersLength);

  LTParameterAssert(minValueBuffer.length >= 4 * sizeof(float),
                    @"Invalid min value buffer length (%lu): must be %lu",
                    (unsigned long)minValueBuffer.length, 4 * sizeof(float));
  LTParameterAssert(maxValueBuffer.length >= 4 * sizeof(float),
                    @"Invalid max value buffer length (%lu): must be %lu",
                    (unsigned long)maxValueBuffer.length, 4 * sizeof(float));

  LTParameterAssert(cdfBuffers.count == 3,
                    @"Invalid inputCDFBuffers: expected 3 buffers, got %lu",
                    (unsigned long)cdfBuffers.count);
  LTParameterAssert(inverseCDFBuffers.count == 3,
                    @"Invalid referenceInverseCDFBuffers: expected 3 buffers, got %lu",
                    (unsigned long)inverseCDFBuffers.count);

  for (NSUInteger i = 0; i < 3; ++i) {
    LTParameterAssert(cdfBuffers[i].length >= self.histogramBins * sizeof(float),
                      @"Invalid length for inputCDFBuffers[%lu]: expected %lu, got %lu",
                      (unsigned long)i, self.histogramBins * sizeof(float),
                      (unsigned long)cdfBuffers[i].length);
    LTParameterAssert(inverseCDFBuffers[i].length >=
                      self.histogramBins * kInverseCDFScaleFactor * sizeof(float),
                      @"Invalid length for referenceInverseCDFBuffers[%lu]: expected %lu, got %lu",
                      (unsigned long)i, self.histogramBins * kInverseCDFScaleFactor * sizeof(float),
                      (unsigned long)inverseCDFBuffers[i].length);
  }

  MTBComputeDispatchWithDefaultThreads(self.calculatePDFState, commandBuffer,
                                       @[inputHistogramBuffer, self.pdfSmoothingKernelBuffer,
                                         self.pdfBuffer],
                                       @"calculatePDF: input", self.histogramBins);

  MTBComputeDispatch(self.calculateCDFState, commandBuffer,
                     [@[self.pdfBuffer] arrayByAddingObjectsFromArray:cdfBuffers],
                     @"calculateCDF: input", {1, 1, 1}, {1, 1, 1});

  MTBComputeDispatchWithDefaultThreads(self.calculatePDFState, commandBuffer,
                                       @[referenceHistogramBuffer, self.pdfSmoothingKernelBuffer,
                                         self.pdfBuffer],
                                       @"calculatePDF: reference", self.histogramBins);
  MTBComputeDispatch(self.calculateCDFState, commandBuffer,
                     [@[self.pdfBuffer] arrayByAddingObjectsFromArray:self.referenceCDFBuffers],
                     @"calculateCDF: reference", {1, 1, 1}, {1, 1, 1});

  for (NSUInteger i = 0; i < 3; ++i) {
    auto buffers = @[self.referenceCDFBuffers[i], minValueBuffer,
                     maxValueBuffer, inverseCDFBuffers[i]];
    MTBComputeDispatchWithDefaultThreads(self.calculateInverseCDFState[i], commandBuffer,
                                         buffers, @"calculateInverseCDF: reference",
                                         self.histogramBins * kInverseCDFScaleFactor);
  }
}

+ (NSUInteger)inverseCDFScaleFactor {
  return kInverseCDFScaleFactor;
}

+ (NSUInteger)minSupportedHistogramBins {
  return kMinHistogramBins;
}

+ (NSUInteger)maxSupportedHistogramBins {
  return kMaxHistogramBins;
}

+ (NSUInteger)pdfSmoothingKernelSize {
  return kPDFSmoothingKernelSize;
}

+ (float)pdfSmoothingKernelSigma {
  return kPDFSmoothingKernelSigma;
}

@end

NS_ASSUME_NONNULL_END
