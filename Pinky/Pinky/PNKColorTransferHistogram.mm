// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferHistogram.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKColorTransferHistogram ()

/// Device to encode kernel operations.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Compiled state of kernel that performs the first stage in the reduction, computing the partial
/// histograms for each threadgroup, after applying a \c 3x3 tanformation on the fly.
@property (readonly, nonatomic) id<MTLComputePipelineState> computePartialHistogramsState;

/// Compiled state of kernel that performs the second stage in the reduction, merging all the
/// partial histograms computed in the first stage into a single histogram.
@property (readonly, nonatomic) id<MTLComputePipelineState> mergeHistogramsState;

/// Intermediate buffer for holding the partial histograms for each threadgroup.
@property (readonly, nonatomic) id<MTLBuffer> partialHistogramsBuffer;

/// Number of partial histograms computed on the first stage of the reduction.
@property (readonly, nonatomic) NSUInteger partialHistogramsCount;

@end

@implementation PNKColorTransferHistogram

/// Maximum number of histogram bins supported by the kernel, based on the available threadgroup
/// memory on the lower end devices.
static const uint kMaxHistogramBins = 1024;

/// Maximum total threadgroup memory allocation of devices with 16KB limit, since in some iOS and
/// tvOS feature sets, the driver may consume up to 32 bytes of a device's total threadgroup memory.
static const NSUInteger kMaxThreadgroupMemoryLength16K = (1 << 14) - 32;

/// Maximum total threadgroup memory allocation of devices with 32KB limit, since in some iOS and
/// tvOS feature sets, the driver may consume up to 32 bytes of a device's total threadgroup memory.
static const NSUInteger kMaxThreadgroupMemoryLength32K = (1 << 15) - 32;

- (instancetype)initWithDevice:(id<MTLDevice>)device histogramBins:(NSUInteger)histogramBins
                     inputSize:(NSUInteger)inputSize {
  LTParameterAssert(inputSize > 0, @"Invalid input size, must be greater than zero");
  LTParameterAssert(histogramBins >= 2 && histogramBins <= kMaxHistogramBins,
                    @"Invalid histogram bins (%lu), must be in range [2,%lu].",
                    (unsigned long)histogramBins, (unsigned long)kMaxHistogramBins);

  if (self = [super init]) {
    _device = device;
    _histogramBins = histogramBins;
    _inputSize = inputSize;
    [self createComputeStates];
    [self createBuffers];
  }
  return self;
}

- (void)createComputeStates {
  auto constants = @[
    [MTBFunctionConstant ushortConstantWithValue:self.histogramBins name:@"kHistogramBins"],
    [MTBFunctionConstant uintConstantWithValue:(uint)self.inputSize name:@"kInputSize"]
  ];

  _computePartialHistogramsState = self.isDeviceWithMaxThreadgroupMemoryOf32K ?
      PNKCreateComputeState(self.device, @"computePartialHistograms32K", constants) :
      PNKCreateComputeState(self.device, @"computePartialHistograms16K", constants);

  _partialHistogramsCount = self.computePartialHistogramsState.maxTotalThreadsPerThreadgroup;
  _mergeHistogramsState = self.partialHistogramsCount == 1024 ?
      PNKCreateComputeState(self.device, @"mergeHistograms1024", constants):
      PNKCreateComputeState(self.device, @"mergeHistograms512", constants);
}

- (BOOL)isDeviceWithMaxThreadgroupMemoryOf32K {
  if (@available(iOS 11.0, *)) {
    return self.device.maxThreadgroupMemoryLength >= kMaxThreadgroupMemoryLength32K;
  }
  return NO;
}

- (void)createBuffers {
  auto bufferLength = self.partialHistogramsCount * self.histogramBins * 4 * sizeof(uint);
  _partialHistogramsBuffer = [self.device newBufferWithLength:bufferLength
                                                      options:MTLResourceStorageModePrivate];
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                  inputBuffer:(id<MTLBuffer>)inputBuffer
              transformBuffer:(id<MTLBuffer>)transformBuffer
               minValueBuffer:(id<MTLBuffer>)minValueBuffer
               maxValueBuffer:(id<MTLBuffer>)maxValueBuffer
              histogramBuffer:(id<MTLBuffer>)histogramBuffer {
  auto *buffers = @[inputBuffer, transformBuffer, minValueBuffer, maxValueBuffer,
                    self.partialHistogramsBuffer];
  MTBComputeDispatch(self.computePartialHistogramsState, commandBuffer,
                     buffers, @"computePartialHistograms",
                     {self.numberOfThreadsPerThreadgroupForComputePartialHistograms, 1, 1},
                     {self.partialHistogramsCount, 1, 1});

  MTBComputeDispatch(self.mergeHistogramsState, commandBuffer,
                     @[self.partialHistogramsBuffer, histogramBuffer], @"mergeHistograms",
                     {self.partialHistogramsCount, 1, 1}, {self.histogramBins, 1, 1});
}

- (NSUInteger)numberOfThreadsPerThreadgroupForComputePartialHistograms {
  auto warpSize = self.computePartialHistogramsState.threadExecutionWidth;
  auto maxThreadsPerThreadgroup = self.computePartialHistogramsState.maxTotalThreadsPerThreadgroup;
  auto maxMemoryLength = self.isDeviceWithMaxThreadgroupMemoryOf32K ?
      kMaxThreadgroupMemoryLength32K : kMaxThreadgroupMemoryLength16K;

  auto sharedBufferElements = maxMemoryLength / 3 / sizeof(uint);
  NSUInteger maxNumberOfWarps = sharedBufferElements / self.histogramBins;
  return std::min(maxNumberOfWarps * warpSize, maxThreadsPerThreadgroup);
}

+ (NSUInteger)maxSupportedHistogramBins {
  return kMaxHistogramBins;
}

@end

NS_ASSUME_NONNULL_END
