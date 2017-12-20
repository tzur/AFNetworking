// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferMinAndMax.h"

#import "MPSImage+Factory.h"
#import "MPSTemporaryImage+Factory.h"
#import "PNKAvailability.h"
#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKColorTransferMinAndMax ()

/// Device to encode kernel operations.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Compiled state of kernel that resets given buffers to the maximum and minimum float values.
@property (readonly, nonatomic) id<MTLComputePipelineState> resetMinMaxState;

/// Array of compiled states of kernel that performs the first stage in the reduction, finding the
/// minimum and maximum values per each threadgroup in the given buffers, after applying a 3x3
/// transformation in-situ.
@property (readonly, nonatomic, nullable) NSArray<id<MTLComputePipelineState>>
    *findMinMaxPerThreadgroupStates;

/// Compiled state of kernel that performs the second stage in the reduction, finding the minimum
/// and maximum values in the given buffers, which are expected to contain the minimum and maximum
/// values per threadgroup that were found in the first stage of the reduction.
@property (readonly, nonatomic, nullable) id<MTLComputePipelineState> findMinMaxState;

/// Intermediate buffer for holding the minimum values found in each threadgroup.
@property (readonly, nonatomic, nullable) id<MTLBuffer> minValuesPerThreadgroupBuffer;

/// Intermediate buffer for holding the maximum values found in each threadgroup.
@property (readonly, nonatomic, nullable) id<MTLBuffer> maxValuesPerThreadgroupBuffer;

/// Finds the minimum and maximum pixel values in a given buffer. Faster than our metal
/// implementation even when applying the transformation on a separate kernel writing the
/// intermediate result to a temporary buffer, but available only on iOS 11.
@property (readonly, nonatomic, nullable) MPSImageStatisticsMinAndMax *mpsMinMax
    NS_AVAILABLE_IOS(11);

/// Compiled state of kernel that applies a given 3x3 transform on each pixel of a given texture.
@property (readonly, nonatomic, nullable) id<MTLComputePipelineState> applyTransformState;

/// Compiled state of kernel for merging the minimum and maximum pixel values found by \c mpsMinMax
/// for each buffer.
@property (readonly, nonatomic, nullable) id<MTLComputePipelineState> mergeMinMaxState;

/// Intermediate buffers holding the minimum and maximum values found in each buffer by
/// \c mpsMinMax
@property (readonly, nonatomic, nullable) NSArray<MPSImage *> *mpsMinMaxResults;

@end

@implementation PNKColorTransferMinAndMax

static const NSUInteger kTemporaryBufferElements = 16384;

- (instancetype)initWithDevice:(id<MTLDevice>)device
                    inputSizes:(nonnull NSArray<NSNumber *> *)inputSizes {
  LTParameterAssert(inputSizes.count, @"Invalid input sizes, must be non-empty");
  for (NSNumber *size in inputSizes) {
    LTParameterAssert(size.integerValue > 0, @"Invalid input size (%ld), must be greater than zero",
                      (long)size.integerValue);
  }

  if (self = [super init]) {
    _device = device;
    _inputSizes = inputSizes;
    [self createComputeStates];
  }
  return self;
}

- (void)createComputeStates {
  _resetMinMaxState = PNKCreateComputeState(self.device, @"resetMinMax");

  if (@available(iOS 11.0, *)) {
    if (PNKSupportsMTLDevice(self.device)) {
      [self createFastCompuateStatesAndBuffers];
      return;
    }
  }

  [self createSlowComputeStatesAndBuffers];
}

- (void)createSlowComputeStatesAndBuffers {
  _findMinMaxState = PNKCreateComputeState(self.device, @"findMinMax");

  auto constants = [[MTLFunctionConstantValues alloc] init];
  auto findMinMaxStates = [NSMutableArray array];
  for (NSNumber *inputSize in self.inputSizes) {
    uint size = (uint)inputSize.unsignedIntegerValue;
    [constants setConstantValue:&size type:MTLDataTypeUInt withName:@"kInputSize"];
    auto state =
        PNKCreateComputeStateWithConstants(self.device, @"findMinMaxPerThreadgroup", constants);
    [findMinMaxStates addObject:state];
  }
  _findMinMaxPerThreadgroupStates = findMinMaxStates;

  _minValuesPerThreadgroupBuffer = [self createTemporaryBuffer];
  _maxValuesPerThreadgroupBuffer = [self createTemporaryBuffer];
}

- (id<MTLBuffer>)createTemporaryBuffer {
  auto bufferLength = kTemporaryBufferElements * 4 * sizeof(float);
  return [self.device newBufferWithLength:bufferLength options:MTLResourceStorageModePrivate];
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputBuffers:(NSArray<id<MTLBuffer>> *)inputBuffers
              transformBuffer:(nullable id<MTLBuffer>)transformBuffer
               minValueBuffer:(id<MTLBuffer>)minValueBuffer
               maxValueBuffer:(id<MTLBuffer>)maxValueBuffer {
  PNKComputeDispatch(self.resetMinMaxState, commandBuffer, @[minValueBuffer, maxValueBuffer], @[],
                     @"resetMinMax", {1, 1, 1}, {1, 1, 1});

  if (@available(iOS 11.0, *)) {
    if (PNKSupportsMTLDevice(self.device)) {
      [self mpsEncodeToCommandBuffer:commandBuffer inputBuffers:inputBuffers
                     transformBuffer:transformBuffer minValueBuffer:minValueBuffer
                      maxValueBuffer:maxValueBuffer];
      return;
    }
  }

  [self computeEncodeToCommandBuffer:commandBuffer inputBuffers:inputBuffers
                     transformBuffer:transformBuffer minValueBuffer:minValueBuffer
                      maxValueBuffer:maxValueBuffer];
}

- (void)computeEncodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                        inputBuffers:(NSArray<id<MTLBuffer>> *)inputBuffers
                     transformBuffer:(nullable id<MTLBuffer>)transformBuffer
                      minValueBuffer:(id<MTLBuffer>)minValueBuffer
                      maxValueBuffer:(id<MTLBuffer>)maxValueBuffer {
  for (NSUInteger i = 0; i < inputBuffers.count; ++i) {
    PNKComputeDispatchWithDefaultThreads(self.resetMinMaxState, commandBuffer,
                                         @[self.minValuesPerThreadgroupBuffer,
                                           self.maxValuesPerThreadgroupBuffer],
                                         @"resetMinMax temporaryValueBuffers",
                                         kTemporaryBufferElements);

    PNKComputeDispatchWithDefaultThreads(self.findMinMaxPerThreadgroupStates[i], commandBuffer,
                                         @[inputBuffers[i], transformBuffer,
                                           self.minValuesPerThreadgroupBuffer,
                                           self.maxValuesPerThreadgroupBuffer],
                                         @"findMinMaxPerThreadgroup",
                                         self.inputSizes[i].unsignedIntegerValue / 2);

    PNKComputeDispatchWithDefaultThreads(self.findMinMaxState, commandBuffer,
                                         @[self.minValuesPerThreadgroupBuffer,
                                           self.maxValuesPerThreadgroupBuffer,
                                           minValueBuffer, maxValueBuffer],
                                         @"findMinMax", kTemporaryBufferElements / 2);
  }
}

- (void)createFastCompuateStatesAndBuffers NS_AVAILABLE_IOS(11) {
  _applyTransformState = PNKCreateComputeState(self.device, @"applyTransformOnTexture");
  _mergeMinMaxState = PNKCreateComputeState(self.device, @"mergeMinMax");
  _mpsMinMax = [[MPSImageStatisticsMinAndMax alloc] initWithDevice:self.device];
  auto mpsMinMaxResults = [NSMutableArray array];
  for (NSUInteger i = 0; i < self.inputSizes.count; ++i) {
    auto result = [MPSImage pnk_imageWithDevice:self.device
                                         format:MPSImageFeatureChannelFormatFloat32
                                           size:{2, 1, 4}];
    [mpsMinMaxResults addObject:result];
  }
  _mpsMinMaxResults = mpsMinMaxResults;
}

- (void)mpsEncodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                    inputBuffers:(NSArray<id<MTLBuffer>> *)inputBuffers
                 transformBuffer:(nullable id<MTLBuffer>)transformBuffer
                  minValueBuffer:(id<MTLBuffer>)minValueBuffer
                  maxValueBuffer:(id<MTLBuffer>)maxValueBuffer NS_AVAILABLE_IOS(11) {
  for (NSUInteger i = 0; i < inputBuffers.count; ++i) {
    NSUInteger inputSize = self.inputSizes[i].unsignedIntegerValue;
    NSUInteger width = std::min((NSUInteger)1024, inputSize);
    NSUInteger height = (inputSize + width - 1) / width;
    NSUInteger bytesPerRow = width * 4 * sizeof(float);
    auto descriptor = [MTLTextureDescriptor
                       texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA32Float
                       width:width height:height mipmapped:NO];
    auto inputTexture = [inputBuffers[i] newTextureWithDescriptor:descriptor offset:0
                                                      bytesPerRow:bytesPerRow];
    auto transformedInput = [MPSTemporaryImage
                             pnk_imageWithDevice:self.device
                             format:MPSImageFeatureChannelFormatFloat32
                             width:width height:height channels:4];

    PNKComputeDispatchWithDefaultThreads(self.applyTransformState, commandBuffer,
                                         @[transformBuffer],
                                         @[inputTexture, transformedInput.texture],
                                         @"applyTransform", {width, height, 4});

    [self.mpsMinMax encodeToCommandBuffer:commandBuffer sourceImage:transformedInput
                         destinationImage:self.mpsMinMaxResults[i]];

    PNKComputeDispatch(self.mergeMinMaxState, commandBuffer, @[minValueBuffer, maxValueBuffer],
                       @[self.mpsMinMaxResults[i].texture], @"mergeMinMax", {1, 1, 1}, {1, 1, 1});
  }
}

@end

#endif

NS_ASSUME_NONNULL_END
