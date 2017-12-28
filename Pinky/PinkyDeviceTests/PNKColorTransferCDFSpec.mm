// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferCDF.h"

#import <LTKit/LTRandom.h>

#import "PNKColorTransferTestUtils.h"

typedef std::vector<uint> Histogram;

static const NSUInteger kRandomSeed = 1337;

static cv::Mat1i PNKRandomHistogram(NSUInteger pixels, NSUInteger channels, NSUInteger bins) {
  auto random = [[LTRandom alloc] initWithSeed:kRandomSeed];
  cv::Mat1i histogram = cv::Mat1i::zeros((int)channels, (int)bins);
  for (NSUInteger c = 0; c < channels; ++c) {
    for (NSUInteger i = 0; i < pixels; ++i) {
      histogram((int)c, (int)[random randomUnsignedIntegerBelow:(uint)bins])++;
    }
  }

  return histogram;
}

static id<MTLBuffer> PNKCreateBufferFromHistograms(id<MTLDevice> device,
                                                   const cv::Mat1i &histograms) {
  LTParameterAssert(histograms.rows == 3);
  auto buffer = [device newBufferWithLength:histograms.cols * 4 * sizeof(uint)
                                    options:MTLResourceStorageModeShared];
  for (int i = 0; i < histograms.cols; ++i) {
    ((uint *)buffer.contents + i * 4)[0] = histograms(0, i);
    ((uint *)buffer.contents + i * 4)[1] = histograms(1, i);
    ((uint *)buffer.contents + i * 4)[2] = histograms(2, i);
  }

  return buffer;
}

static cv::Mat1f PNKCDFsForHistograms(const cv::Mat1i &histograms) {
  cv::Mat1f cdfs(histograms.size());
  for (int c = 0; c < histograms.rows; ++c) {
    auto histogram = histograms.row(c);
    auto cdf = cdfs.row(c);
    auto totalPixels = std::accumulate(histogram.begin(), histogram.end(), 0);
    std::transform(histogram.begin(), histogram.end(), cdf.begin(), [totalPixels](auto count) {
      return (float)count / totalPixels;
    });

    std::partial_sum(cdf.begin(), cdf.end(), cdf.begin());

  }
  return cdfs;
}

static cv::Mat1f PNKInvertCDFs(const cv::Mat1f &cdfs, const Floats &minValue,
                               const Floats &maxValue) {
  cv::Mat1f inverseCDFs =
      cv::Mat1f::zeros(cdfs.rows, cdfs.cols * (int)PNKColorTransferCDF.inverseCDFScaleFactor);

  for (int c = 0; c < cdfs.rows; ++c) {
    auto cdf = cdfs.row(c);
    auto inverseCDF = inverseCDFs.row(c);
    auto rangeLength = maxValue[c] - minValue[c];

    for (int i = 0; i < inverseCDF.cols; ++i) {
      float v = (float)i / (inverseCDF.cols - 1);

      float minIndex = cdf.cols - 1;
      for (int j = 0; j < cdf.cols; ++j) {
        if (cdf(0, j) > v) {
          if (j == 0) {
            minIndex = j;
          } else {
            float a = cdf(0, j - 1);
            float b = cdf(0, j);
            float alpha = (v - a) / (b - a);
            minIndex = j - 1 + alpha;
          }
          break;
        }
      }

      auto inverseIndex = (float)minIndex / (cdf.cols - 1);
      inverseCDF(0, i) = minValue[c] + inverseIndex * rangeLength;
    }
  }

  return inverseCDFs;
}

DeviceSpecBegin(PNKColorTransferCDF)

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
    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:32];
    expect(cdf.histogramBins).to.equal(32);
  });

  it(@"should raise if initialized with an invalid number of bins", ^{
    expect(^{
      __unused auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:0];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      __unused auto cdf = [[PNKColorTransferCDF alloc]
                           initWithDevice:device
                           histogramBins:PNKColorTransferCDF.maxSupportedHistogramBins + 1];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"correctness", ^{
  static const NSUInteger kNumChannels = 3;
  static const NSUInteger kHistogramBins = 10;
  static const NSUInteger kInputPixels = 31337;
  static const NSUInteger kReferencePixels = 41337;
  static const cv::Mat1i kInputHistogram =
      PNKRandomHistogram(kInputPixels, kNumChannels, kHistogramBins);
  static const cv::Mat1i kReferenceHistogram =
      PNKRandomHistogram(kReferencePixels, kNumChannels, kHistogramBins);

  __block id<MTLBuffer> inputHistogramBuffer;
  __block id<MTLBuffer> referenceHistogramBuffer;
  __block id<MTLBuffer> minValueBuffer;
  __block id<MTLBuffer> maxValueBuffer;
  __block NSMutableArray<id<MTLBuffer>> *inputCDFBuffers;
  __block NSMutableArray<id<MTLBuffer>> *referenceInverseCDFBuffers;

  beforeEach(^{
    inputHistogramBuffer = PNKCreateBufferFromHistograms(device, kInputHistogram);
    referenceHistogramBuffer = PNKCreateBufferFromHistograms(device, kReferenceHistogram);

    minValueBuffer = [device newBufferWithBytes:LTVector4(0).data() length:4 * sizeof(float)
                                        options:MTLResourceStorageModeShared];
    maxValueBuffer = [device newBufferWithBytes:LTVector4(1).data() length:4 * sizeof(float)
                                        options:MTLResourceStorageModeShared];

    inputCDFBuffers = [NSMutableArray array];
    referenceInverseCDFBuffers = [NSMutableArray array];
    auto cdfBufferLength = kHistogramBins * sizeof(float);
    auto inverseCDFBufferLength = cdfBufferLength * PNKColorTransferCDF.inverseCDFScaleFactor;
    for (NSUInteger i = 0; i < kNumChannels; ++i) {
      auto inputCDFBuffer = [device newBufferWithLength:cdfBufferLength
                                                options:MTLResourceStorageModeShared];
      auto referenceInverseCDFBuffer = [device newBufferWithLength:inverseCDFBufferLength
                                                           options:MTLResourceStorageModeShared];
      [inputCDFBuffers addObject:inputCDFBuffer];
      [referenceInverseCDFBuffers addObject:referenceInverseCDFBuffer];
    }
  });

  it(@"should calculate correct cdf from input histogram", ^{
    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:kHistogramBins];

    [cdf encodeToCommandBuffer:commandBuffer inputHistogramBuffer:inputHistogramBuffer
      referenceHistogramBuffer:referenceHistogramBuffer minValueBuffer:minValueBuffer
                maxValueBuffer:maxValueBuffer cdfBuffers:inputCDFBuffers
             inverseCDFBuffers:referenceInverseCDFBuffers];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto expected = PNKCDFsForHistograms(kInputHistogram);
    for (NSUInteger i = 0; i < inputCDFBuffers.count; ++i) {
      auto inputCDF = PNKMatFromBuffer(inputCDFBuffers[i]);
      expect($(inputCDF)).to.beCloseToMatWithin($(expected.row((int)i)), 1e-3);
    }
  });

  it(@"should calculate correct inverse cdf from reference histogram", ^{
    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:kHistogramBins];

    [cdf encodeToCommandBuffer:commandBuffer inputHistogramBuffer:inputHistogramBuffer
      referenceHistogramBuffer:referenceHistogramBuffer minValueBuffer:minValueBuffer
                maxValueBuffer:maxValueBuffer cdfBuffers:inputCDFBuffers
             inverseCDFBuffers:referenceInverseCDFBuffers];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto expected = PNKInvertCDFs(PNKCDFsForHistograms(kReferenceHistogram), {0, 0, 0}, {1, 1, 1});
    for (int i = 0; i < (int)referenceInverseCDFBuffers.count; ++i) {
      auto referenceInverseCDF = PNKMatFromBuffer(referenceInverseCDFBuffers[i]);
      expect($(referenceInverseCDF)).to.beCloseToMatWithin($(expected.row(i)), 1e-3);
    }
  });

  it(@"should calculate correct cdf and inverse cdf with non canonical range", ^{
    Floats minValue = {0.1, 0.2, 0.3, 0};
    Floats maxValue = {0.8, 0.9, 0.7, 1};

    minValueBuffer = [device newBufferWithBytes:minValue.data() length:4 * sizeof(float)
                                        options:MTLResourceStorageModeShared];
    maxValueBuffer = [device newBufferWithBytes:maxValue.data() length:4 * sizeof(float)
                                        options:MTLResourceStorageModeShared];

    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:kHistogramBins];

    [cdf encodeToCommandBuffer:commandBuffer inputHistogramBuffer:inputHistogramBuffer
      referenceHistogramBuffer:referenceHistogramBuffer minValueBuffer:minValueBuffer
                maxValueBuffer:maxValueBuffer cdfBuffers:inputCDFBuffers
             inverseCDFBuffers:referenceInverseCDFBuffers];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto expectedInputCDF = PNKCDFsForHistograms(kInputHistogram);
    auto expectedReferenceInverseCDF =
        PNKInvertCDFs(PNKCDFsForHistograms(kReferenceHistogram), minValue, maxValue);
    for (int i = 0; i < (int)inputCDFBuffers.count; ++i) {
      auto inputCDF = PNKMatFromBuffer(inputCDFBuffers[i]);
      auto referenceInverseCDF = PNKMatFromBuffer(referenceInverseCDFBuffers[i]);
      expect($(inputCDF)).to.beCloseToMatWithin($(expectedInputCDF.row(i)), 1e-3);
      expect($(referenceInverseCDF))
          .to.beCloseToMatWithin($(expectedReferenceInverseCDF.row(i)), 1e-3);
    }
  });

  it(@"should calculate correct cdf and inverse cdf when some of the bins are empty", ^{
    static const cv::Mat1i kInputHistogram = (cv::Mat1i(kNumChannels, kHistogramBins) <<
      4067, 4366, 0, 4898, 0, 6636, 2476, 2150, 2248, 4496,
      0, 0, 5503, 7091, 5866, 9434, 2005, 703, 294, 441,
      5900, 3789, 4450, 6645, 4365, 3317, 2131, 740, 0, 0);

    static const cv::Mat1i kReferenceHistogram = (cv::Mat1i(kNumChannels, kHistogramBins) <<
      5315, 662, 0, 2456, 2622, 2276, 3816, 0, 1683, 12507,
      0, 13109, 4083, 4913, 2831, 2056, 1456, 1141, 754, 994,
      19035, 4058, 2443, 2332, 1959, 945, 438, 127, 0, 0);

    inputHistogramBuffer = PNKCreateBufferFromHistograms(device, kInputHistogram);
    referenceHistogramBuffer = PNKCreateBufferFromHistograms(device, kReferenceHistogram);

    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:kHistogramBins];

    [cdf encodeToCommandBuffer:commandBuffer inputHistogramBuffer:inputHistogramBuffer
      referenceHistogramBuffer:referenceHistogramBuffer minValueBuffer:minValueBuffer
                maxValueBuffer:maxValueBuffer cdfBuffers:inputCDFBuffers
             inverseCDFBuffers:referenceInverseCDFBuffers];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto expectedInputCDF = PNKCDFsForHistograms(kInputHistogram);
    auto expectedReferenceInverseCDF =
        PNKInvertCDFs(PNKCDFsForHistograms(kReferenceHistogram), {0, 0, 0}, {1, 1, 1});
    for (int i = 0; i < (int)inputCDFBuffers.count; ++i) {
      auto inputCDF = PNKMatFromBuffer(inputCDFBuffers[i]);
      auto referenceInverseCDF = PNKMatFromBuffer(referenceInverseCDFBuffers[i]);
      expect($(inputCDF)).to.beCloseToMatWithin($(expectedInputCDF.row(i)), 1e-3);
      expect($(referenceInverseCDF))
          .to.beCloseToMatWithin($(expectedReferenceInverseCDF.row(i)), 1e-3);
    }
  });

  it(@"should calculate correct cdf and inverse cdf with smaller number of bins", ^{
    static const NSUInteger kHistogramBins = 3;
    static const cv::Mat1i kInputHistogram =
        PNKRandomHistogram(kInputPixels, kNumChannels, kHistogramBins);
    static const cv::Mat1i kReferenceHistogram =
        PNKRandomHistogram(kReferencePixels, kNumChannels, kHistogramBins);

    inputHistogramBuffer = PNKCreateBufferFromHistograms(device, kInputHistogram);
    referenceHistogramBuffer = PNKCreateBufferFromHistograms(device, kReferenceHistogram);

    inputCDFBuffers = [NSMutableArray array];
    referenceInverseCDFBuffers = [NSMutableArray array];
    auto cdfBufferLength = kHistogramBins * sizeof(float);
    auto inverseCDFBufferLength = cdfBufferLength * PNKColorTransferCDF.inverseCDFScaleFactor;
    for (NSUInteger i = 0; i < kNumChannels; ++i) {
      auto inputCDFBuffer = [device newBufferWithLength:cdfBufferLength
                                                options:MTLResourceStorageModeShared];
      auto referenceInverseCDFBuffer = [device newBufferWithLength:inverseCDFBufferLength
                                                           options:MTLResourceStorageModeShared];
      [inputCDFBuffers addObject:inputCDFBuffer];
      [referenceInverseCDFBuffers addObject:referenceInverseCDFBuffer];
    }

    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:kHistogramBins];

    [cdf encodeToCommandBuffer:commandBuffer inputHistogramBuffer:inputHistogramBuffer
      referenceHistogramBuffer:referenceHistogramBuffer minValueBuffer:minValueBuffer
                maxValueBuffer:maxValueBuffer cdfBuffers:inputCDFBuffers
             inverseCDFBuffers:referenceInverseCDFBuffers];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto expectedInputCDF = PNKCDFsForHistograms(kInputHistogram);
    auto expectedReferenceInverseCDF =
        PNKInvertCDFs(PNKCDFsForHistograms(kReferenceHistogram), {0, 0, 0}, {1, 1, 1});
    for (int i = 0; i < (int)inputCDFBuffers.count; ++i) {
      auto inputCDF = PNKMatFromBuffer(inputCDFBuffers[i]);
      auto referenceInverseCDF = PNKMatFromBuffer(referenceInverseCDFBuffers[i]);
      expect($(inputCDF)).to.beCloseToMatWithin($(expectedInputCDF.row(i)), 1e-3);
      expect($(referenceInverseCDF))
          .to.beCloseToMatWithin($(expectedReferenceInverseCDF.row(i)), 1e-3);
    }
  });

  it(@"should calcuate correct cdf and inverse with larger number of bins", ^{
    static const NSUInteger kHistogramBins = PNKColorTransferCDF.maxSupportedHistogramBins - 30;
    static const cv::Mat1i kInputHistogram =
        PNKRandomHistogram(kInputPixels, kNumChannels, kHistogramBins);
    static const cv::Mat1i kReferenceHistogram =
        PNKRandomHistogram(kReferencePixels, kNumChannels, kHistogramBins);

    inputHistogramBuffer = PNKCreateBufferFromHistograms(device, kInputHistogram);
    referenceHistogramBuffer = PNKCreateBufferFromHistograms(device, kReferenceHistogram);

    inputCDFBuffers = [NSMutableArray array];
    referenceInverseCDFBuffers = [NSMutableArray array];
    auto cdfBufferLength = kHistogramBins * sizeof(float);
    auto inverseCDFBufferLength = cdfBufferLength * PNKColorTransferCDF.inverseCDFScaleFactor;
    for (NSUInteger i = 0; i < kNumChannels; ++i) {
      auto inputCDFBuffer = [device newBufferWithLength:cdfBufferLength
                                                options:MTLResourceStorageModeShared];
      auto referenceInverseCDFBuffer = [device newBufferWithLength:inverseCDFBufferLength
                                                           options:MTLResourceStorageModeShared];
      [inputCDFBuffers addObject:inputCDFBuffer];
      [referenceInverseCDFBuffers addObject:referenceInverseCDFBuffer];
    }

    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:kHistogramBins];

    [cdf encodeToCommandBuffer:commandBuffer inputHistogramBuffer:inputHistogramBuffer
      referenceHistogramBuffer:referenceHistogramBuffer minValueBuffer:minValueBuffer
                maxValueBuffer:maxValueBuffer cdfBuffers:inputCDFBuffers
             inverseCDFBuffers:referenceInverseCDFBuffers];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto expectedInputCDF = PNKCDFsForHistograms(kInputHistogram);
    auto expectedReferenceInverseCDF =
        PNKInvertCDFs(PNKCDFsForHistograms(kReferenceHistogram), {0, 0, 0}, {1, 1, 1});
    for (int i = 0; i < (int)inputCDFBuffers.count; ++i) {
      auto inputCDF = PNKMatFromBuffer(inputCDFBuffers[i]);
      auto referenceInverseCDF = PNKMatFromBuffer(referenceInverseCDFBuffers[i]);
      expect($(inputCDF)).to.beCloseToMatWithin($(expectedInputCDF.row(i)), 1e-3);
      expect($(referenceInverseCDF))
          .to.beCloseToMatWithin($(expectedReferenceInverseCDF.row(i)), 1e-3);
    }
  });
});

DeviceSpecEnd
