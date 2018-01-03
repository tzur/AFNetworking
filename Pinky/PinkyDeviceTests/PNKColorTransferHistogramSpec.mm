// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferHistogram.h"

#import <Accelerate/Accelerate.h>
#import <LTEngine/LTOpenCVExtensions.h>

#import "PNKColorTransferTestUtils.h"

static NSArray<NSArray<NSNumber *> *> *PNKHistogramFromBuffer(id<MTLBuffer> buffer) {
  auto histograms = @[[NSMutableArray array], [NSMutableArray array], [NSMutableArray array]];

  uint *content = (uint *)buffer.contents;
  for (NSUInteger i = 0; i < buffer.length / 4 / sizeof(float); ++i) {
    [histograms[0] addObject:@(content[i * 4])];
    [histograms[1] addObject:@(content[i * 4 + 1])];
    [histograms[2] addObject:@(content[i * 4 + 2])];
  }

  return histograms;
}

static NSArray<NSArray<NSNumber *> *> *PNKHistogramOfMat(const cv::Mat3f &mat, NSUInteger bins,
                                                         LTVector3 minValue, LTVector3 maxValue) {
  std::vector<cv::Mat1f> channels;
  cv::split(mat, channels);

  auto histograms = @[[NSMutableArray array], [NSMutableArray array], [NSMutableArray array]];
  for (NSUInteger i = 0; i < 3; ++i) {
    const auto &channel = channels[i];
    std::vector<vImagePixelCount> histogram(bins, 0);
    vImage_Buffer vBuffer = {
      .data = (void *)channel.data,
      .height = (vImagePixelCount)channel.rows,
      .width = (vImagePixelCount)channel.cols,
      .rowBytes = channel.step[0]
    };

    vImageHistogramCalculation_PlanarF(&vBuffer, histogram.data(), (uint)bins,
                                       minValue.data()[i], maxValue.data()[i], 0);
    for (auto count : histogram) {
      [histograms[i] addObject:@(count)];
    }
  }

  return histograms;
}

DeviceSpecBegin(PNKColorTransferHistogram)

static const NSUInteger kHistogramBins = 32;
static const NSUInteger kInputSize = 31337;

__block id<MTLDevice> device;
__block id<MTLCommandQueue> commandQueue;
__block id<MTLCommandBuffer> commandBuffer;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    auto histogram = [[PNKColorTransferHistogram alloc]
                      initWithDevice:device histogramBins:kHistogramBins inputSize:kInputSize];
    expect(histogram.inputSize).to.equal(kInputSize);
    expect(histogram.histogramBins).to.equal(kHistogramBins);
  });

  it(@"should raise if initialized with zero input size", ^{
    expect(^{
      __unused auto histogram = [[PNKColorTransferHistogram alloc]
                                 initWithDevice:device histogramBins:kHistogramBins inputSize:0];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if initialized with invalid number of bins", ^{
    expect(^{
      auto tooManyBins = PNKColorTransferHistogram.maxSupportedHistogramBins + 1;
      __unused auto histogram = [[PNKColorTransferHistogram alloc]
                                 initWithDevice:device histogramBins:tooManyBins
                                 inputSize:kInputSize];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      __unused auto histogram = [[PNKColorTransferHistogram alloc]
                                 initWithDevice:device histogramBins:1 inputSize:kInputSize];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"correctness", ^{
  __block id<MTLBuffer> inputBuffer;
  __block id<MTLBuffer> transformBuffer;
  __block id<MTLBuffer> histogramBuffer;
  __block id<MTLBuffer> minValueBuffer;
  __block id<MTLBuffer> maxValueBuffer;
  __block cv::Mat3f inputMat;
  __block PNKColorTransferHistogram *histogram;

  beforeEach(^{
    cv::Mat4b inputByteMat = LTLoadMat(self.class, @"ColorTransferHistogramInput.png");
    inputMat.create(1, kInputSize);
    std::transform(inputByteMat.begin(), inputByteMat.begin() + kInputSize, inputMat.begin(),
                   [](cv::Vec4b value) {
                     return (cv::Vec3f)LTVector4(value).rgb();
                   });
    inputBuffer = PNKCreateBufferFromMat(device, inputMat);
    transformBuffer = PNKCreateBufferFromTransformMat(device, cv::Mat1f::eye(3, 3));
    histogramBuffer = [device newBufferWithLength:kHistogramBins * 4 * sizeof(uint)
                                          options:MTLResourceStorageModeShared];

    minValueBuffer = [device newBufferWithBytes:LTVector4(0).data() length:4 * sizeof(float)
                                        options:MTLResourceStorageModeShared];
    maxValueBuffer = [device newBufferWithBytes:LTVector4(1).data() length:4 * sizeof(float)
                                        options:MTLResourceStorageModeShared];

    histogram = [[PNKColorTransferHistogram alloc]
                 initWithDevice:device histogramBins:kHistogramBins inputSize:kInputSize];
  });

  it(@"should compute histogram", ^{
    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:inputBuffer
                     transformBuffer:transformBuffer minValueBuffer:minValueBuffer
                      maxValueBuffer:maxValueBuffer histogramBuffer:histogramBuffer];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto expected = PNKHistogramOfMat(inputMat, kHistogramBins, LTVector3(0), LTVector3(1));
    auto histograms = PNKHistogramFromBuffer(histogramBuffer);
    expect(histograms).to.equal(expected);
  });

  it(@"should compute histogram of a small buffer", ^{
    static const NSUInteger kSmallInputSize = 10;
    auto smallInputMat = inputMat.colRange(0, (int)kSmallInputSize);
    inputBuffer = PNKCreateBufferFromMat(device, smallInputMat);
    histogram = [[PNKColorTransferHistogram alloc]
                 initWithDevice:device histogramBins:kHistogramBins inputSize:kSmallInputSize];

    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:inputBuffer
                     transformBuffer:transformBuffer minValueBuffer:minValueBuffer
                      maxValueBuffer:maxValueBuffer histogramBuffer:histogramBuffer];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto expected = PNKHistogramOfMat(smallInputMat, kHistogramBins, LTVector3(0), LTVector3(1));
    auto histograms = PNKHistogramFromBuffer(histogramBuffer);
    expect(histograms).to.equal(expected);
  });

  it(@"should compute histogram with non identity rotation", ^{
    cv::Mat1f rotation = (cv::Mat1f(3, 3) << 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0);
    auto transformBuffer = PNKCreateBufferFromTransformMat(device, rotation);

    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:inputBuffer
                     transformBuffer:transformBuffer minValueBuffer:minValueBuffer
                      maxValueBuffer:maxValueBuffer histogramBuffer:histogramBuffer];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto expected = PNKHistogramOfMat(inputMat, kHistogramBins, LTVector3(0), LTVector3(1));
    auto histograms = PNKHistogramFromBuffer(histogramBuffer);
    expect(histograms).to.equal(@[expected[1], expected[2], expected[0]]);
  });

  it(@"should compute histogram with non canonical range", ^{
    LTVector3 minValue(0.1, 0.2, 0.3);
    LTVector3 maxValue(0.9, 0.8, 0.7);
    std::copy(minValue.data(), minValue.data() + 3, (float *)minValueBuffer.contents);
    std::copy(maxValue.data(), maxValue.data() + 3, (float *)maxValueBuffer.contents);

    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:inputBuffer
                     transformBuffer:transformBuffer minValueBuffer:minValueBuffer
                      maxValueBuffer:maxValueBuffer histogramBuffer:histogramBuffer];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto expected = PNKHistogramOfMat(inputMat, kHistogramBins, minValue, maxValue);
    auto histograms = PNKHistogramFromBuffer(histogramBuffer);
    expect(histograms).to.equal(expected);
  });

  it(@"should compute histograms with different number of bins", ^{
    auto transformBuffer = PNKCreateBufferFromTransformMat(device, cv::Mat1f::eye(3, 3));

    auto minBins = 2;
    auto maxBins = PNKColorTransferHistogram.maxSupportedHistogramBins;
    for (NSUInteger i = minBins; i <= maxBins; i += (maxBins - minBins) / 10) {
      @autoreleasepool {
        auto histogram = [[PNKColorTransferHistogram alloc]
                          initWithDevice:device histogramBins:i inputSize:kInputSize];
        histogramBuffer = [device newBufferWithLength:i * 4 * sizeof(uint)
                                              options:MTLResourceStorageModeShared];

        commandBuffer = [commandQueue commandBuffer];
        [histogram encodeToCommandBuffer:commandBuffer inputBuffer:inputBuffer
                         transformBuffer:transformBuffer minValueBuffer:minValueBuffer
                          maxValueBuffer:maxValueBuffer histogramBuffer:histogramBuffer];

        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];

        auto expected = PNKHistogramOfMat(inputMat, i, LTVector3(0), LTVector3(1));
        auto histograms = PNKHistogramFromBuffer(histogramBuffer);
        expect(histograms).to.equal(expected);
      }
    }
  });
});

DeviceSpecEnd
