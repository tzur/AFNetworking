// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferHistogramSpecification.h"

#import "PNKColorTransferCDF.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKColorTransferHistogramSpecification ()

/// Device to encode kernel operations.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Compiled state of kernel that performs the histogram specification.
@property (readonly, nonatomic) id<MTLComputePipelineState> histogramSpecificationBufferState;

@end

@implementation PNKColorTransferHistogramSpecification

- (instancetype)initWithDevice:(id<MTLDevice>)device histogramBins:(NSUInteger)histogramBins
                 dampingFactor:(float)dampingFactor {
  LTParameterAssert(histogramBins > 1, @"Invalid histogram bins (%lu), must be greater than 1",
                    (unsigned long)histogramBins);
  LTParameterAssert(dampingFactor > 0 && dampingFactor <= 1,
                    @"Invalid damping factor (%g), must be in range (0,1]", dampingFactor);

  if (self = [super init]) {
    _device = device;
    _histogramBins = histogramBins;
    _dampingFactor = dampingFactor;

    [self createComputeState];
  }

  return self;
}

- (void)createComputeState {
  auto constants = @[
    [MTBFunctionConstant ushortConstantWithValue:self.histogramBins name:@"kHistogramBins"],
    [MTBFunctionConstant floatConstantWithValue:self.dampingFactor name:@"kDampingFactor"],
    [MTBFunctionConstant ushortConstantWithValue:PNKColorTransferCDF.inverseCDFScaleFactor
                                            name:@"kInverseCDFScaleFactor"]
  ];

  _histogramSpecificationBufferState =
      PNKCreateComputeState(self.device, @"histogramSpecificationBuffer", constants);
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   dataBuffer:(id<MTLBuffer>)dataBuffer
              transformBuffer:(id<MTLBuffer>)transformBuffer
               minValueBuffer:(id<MTLBuffer>)minValueBuffer
               maxValueBuffer:(id<MTLBuffer>)maxValueBuffer
              inputCDFBuffers:(NSArray<id<MTLBuffer>> *)inputCDFBuffers
   referenceInverseCDFBuffers:(NSArray<id<MTLBuffer>> *)referenceInverseCDFBuffers {
  LTParameterAssert(transformBuffer.length >= 12 * sizeof(float),
                    @"Invalid transfrom buffer length (%lu): must be at least %lu bytes",
                    (unsigned long)transformBuffer.length, 12 * sizeof(float));

  LTParameterAssert(minValueBuffer.length >= 4 * sizeof(float),
                    @"Invalid min value buffer length (%lu): must be %lu",
                    (unsigned long)minValueBuffer.length, 4 * sizeof(float));
  LTParameterAssert(maxValueBuffer.length >= 4 * sizeof(float),
                    @"Invalid max value buffer length (%lu): must be %lu",
                    (unsigned long)maxValueBuffer.length, 4 * sizeof(float));

  LTParameterAssert(inputCDFBuffers.count == 3,
                    @"Invalid inputCDFBuffers: expected 3 buffers, got %lu",
                    (unsigned long)inputCDFBuffers.count);
  LTParameterAssert(referenceInverseCDFBuffers.count == 3,
                    @"Invalid referenceInverseCDFBuffers: expected 3 buffers, got %lu",
                    (unsigned long)referenceInverseCDFBuffers.count);

  auto inputCDFBufferLength = self.histogramBins * sizeof(float);
  auto referenceInverseCDFBufferLength =
      self.histogramBins * PNKColorTransferCDF.inverseCDFScaleFactor * sizeof(float);
  for (NSUInteger i = 0; i < 3; ++i) {
    LTParameterAssert(inputCDFBuffers[i].length >= inputCDFBufferLength,
                      @"Invalid length for inputCDFBuffers[%lu]: expected %lu, got %lu",
                      (unsigned long)i, (unsigned long)inputCDFBufferLength,
                      (unsigned long)inputCDFBuffers[i].length);
    LTParameterAssert(referenceInverseCDFBuffers[i].length >= referenceInverseCDFBufferLength,
                      @"Invalid length for referenceInverseCDFBuffers[%lu]: expected %lu, got %lu",
                      (unsigned long)i, (unsigned long)referenceInverseCDFBufferLength,
                      (unsigned long)referenceInverseCDFBuffers[i].length);
  }

  auto buffers = [[@[dataBuffer, transformBuffer, minValueBuffer, maxValueBuffer]
                   arrayByAddingObjectsFromArray:inputCDFBuffers]
                   arrayByAddingObjectsFromArray:referenceInverseCDFBuffers];
  MTBComputeDispatchWithDefaultThreads(self.histogramSpecificationBufferState, commandBuffer,
                                       buffers, @"histogramSpecification",
                                       dataBuffer.length / (4 * sizeof(float)));
}

@end

NS_ASSUME_NONNULL_END
