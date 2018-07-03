// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferHistogramSpecification.h"

#import <Accelerate/Accelerate.h>
#import <LTEngine/LTColorTransferProcessor.h>
#import <LTEngine/LTOpenCVExtensions.h>

#import "PNKColorTransferCDF.h"
#import "PNKColorTransferHistogram.h"
#import "PNKColorTransferTestUtils.h"

@interface LTColorTransferProcessor ()
- (void)histogramSpecificationOnInput:(const Floats &)input inputCDF:(const Floats &)inputCDF
                  inverseReferenceCDF:(const Floats &)inverseReferenceCDF
                                range:(std::pair<float, float>)range target:(Floats *)target;
@end

static cv::Mat3f PNKLoadAndFlattenMat(Class classInBundle, NSString *name) {
  cv::Mat4b byteMat = LTLoadMat(classInBundle, name);

  cv::Mat3f floatMat(1, (int)byteMat.total());
  std::transform(byteMat.begin(), byteMat.end(), floatMat.begin(), [](auto value) {
   return (cv::Vec3f)LTVector4(value).rgb();
  });

  return floatMat;
}

static Floats PNKFloatsFromBuffer(id<MTLBuffer> buffer) {
  auto mat = PNKMatFromBuffer(buffer);
  return Floats(mat.begin(), mat.end());
}

static cv::Mat3f PNKTestHistogramSpecification(const cv::Mat3f inputMat,
                                               NSArray<id<MTLBuffer>> *inputCDFBuffers,
                                               NSArray<id<MTLBuffer>> *referenceInverseCDFBuffers,
                                               const Floats &minValue, const Floats &maxValue) {
  std::vector<cv::Mat1f> inputChannels, targetChannels;
  cv::split(inputMat, inputChannels);

  auto processor = [[LTColorTransferProcessor alloc] init];
  for (NSUInteger i = 0; i < inputCDFBuffers.count; ++i) {
    Floats input(inputChannels[i].begin(), inputChannels[i].end());
    Floats target(input.size());
    auto range = std::make_pair(minValue[i], maxValue[i]);

    auto inputCDF = PNKFloatsFromBuffer(inputCDFBuffers[i]);
    auto referenceInverseCDF = PNKFloatsFromBuffer(referenceInverseCDFBuffers[i]);

    [processor histogramSpecificationOnInput:input inputCDF:inputCDF
                         inverseReferenceCDF:referenceInverseCDF range:range target:&target];
    targetChannels.push_back(cv::Mat1f(inputChannels[i].rows, inputChannels[i].cols,
                                       target.data()).clone());
  }

  cv::Mat3f target;
  cv::merge(targetChannels, target);
  return target;
}

@interface PNKColorTransferHistogramSpecificationBuffers : NSObject
@property (readonly, nonatomic) id<MTLBuffer> input;
@property (readonly, nonatomic) id<MTLBuffer> reference;
@property (readonly, nonatomic) id<MTLBuffer> transform;
@property (readonly, nonatomic) id<MTLBuffer> minValue;
@property (readonly, nonatomic) id<MTLBuffer> maxValue;
@property (readonly, nonatomic) id<MTLBuffer> inputHistogram;
@property (readonly, nonatomic) id<MTLBuffer> referenceHistogram;
@property (readonly, nonatomic) NSArray<id<MTLBuffer>> *inputCDFs;
@property (readonly, nonatomic) NSArray<id<MTLBuffer>> *referenceInverseCDFs;
@end

@implementation PNKColorTransferHistogramSpecificationBuffers

- (instancetype)initWithDevice:(id<MTLDevice>)device inputMat:(const cv::Mat3f &)inputMat
                  referenceMat:(const cv::Mat3f &)referenceMat
                 histogramBins:(NSUInteger)histogramBins {
  if (self = [super init]) {
    _transform = PNKCreateBufferFromTransformMat(device, cv::Mat1f::eye(3, 3));
    _minValue = [device newBufferWithBytes:LTVector4(0).data() length:4 * sizeof(float)
                                   options:MTLResourceStorageModeShared];
    _maxValue = [device newBufferWithBytes:LTVector4(1).data() length:4 * sizeof(float)
                                   options:MTLResourceStorageModeShared];
    _inputHistogram = [device newBufferWithLength:histogramBins * 4 * sizeof(uint)
                                          options:MTLResourceStorageModeShared];
    _referenceHistogram = [device newBufferWithLength:histogramBins * 4 * sizeof(uint)
                                              options:MTLResourceStorageModeShared];

    auto inputCDFBuffers = [NSMutableArray array];
    auto referenceInverseCDFBuffers = [NSMutableArray array];
    auto cdfBufferLength = histogramBins * sizeof(float);
    auto inverseCDFBufferLength = cdfBufferLength * PNKColorTransferCDF.inverseCDFScaleFactor;
    for (NSUInteger i = 0; i < 3; ++i) {
      auto inputCDFBuffer = [device newBufferWithLength:cdfBufferLength
                                                options:MTLResourceStorageModeShared];
      auto referenceInverseCDFBuffer = [device newBufferWithLength:inverseCDFBufferLength
                                                           options:MTLResourceStorageModeShared];
      [inputCDFBuffers addObject:inputCDFBuffer];
      [referenceInverseCDFBuffers addObject:referenceInverseCDFBuffer];
    }

    _inputCDFs = inputCDFBuffers;
    _referenceInverseCDFs = referenceInverseCDFBuffers;

    _input = PNKCreateBufferFromMat(device, inputMat);
    _reference = PNKCreateBufferFromMat(device, referenceMat);
  }

  return self;
}

@end

DeviceSpecBegin(PNKColorTransferHistogramSpecification)

__block id<MTLDevice> device;
__block id<MTLCommandBuffer> commandBuffer;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    auto histogramSpecification = [[PNKColorTransferHistogramSpecification alloc]
                                   initWithDevice:device histogramBins:32 dampingFactor:1];
    expect(histogramSpecification.histogramBins).to.equal(32);
    expect(histogramSpecification.dampingFactor).to.equal(1);
  });

  it(@"should raise if initialized with invalid number of bins", ^{
    expect(^{
      __unused auto histogramSpecification =
          [[PNKColorTransferHistogramSpecification alloc]
           initWithDevice:device histogramBins:0 dampingFactor:0.5];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      __unused auto histogramSpecification =
          [[PNKColorTransferHistogramSpecification alloc]
           initWithDevice:device histogramBins:1 dampingFactor:0.5];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if initialized with invalid damping factor", ^{
    expect(^{
      __unused auto histogramSpecification =
          [[PNKColorTransferHistogramSpecification alloc]
           initWithDevice:device histogramBins:32 dampingFactor:0];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      __unused auto histogramSpecification =
          [[PNKColorTransferHistogramSpecification alloc]
           initWithDevice:device histogramBins:32 dampingFactor:1 + 1e-6];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"correctness", ^{
  static const NSUInteger kHistogramBins = 32;
  static const float kDampingFactor = 1;

  __block cv::Mat3f inputMat;
  __block cv::Mat3f referenceMat;
  __block PNKColorTransferHistogramSpecificationBuffers *buffers;
  __block PNKColorTransferHistogramSpecification *histogramSpecification;

  beforeEach(^{
    inputMat = PNKLoadAndFlattenMat(self.class, @"ColorTransferHistogramSpecificationInput.png");
    referenceMat =
        PNKLoadAndFlattenMat(self.class, @"ColorTransferHistogramSpecificationReference.png");
    buffers = [[PNKColorTransferHistogramSpecificationBuffers alloc]
               initWithDevice:device inputMat:inputMat referenceMat:referenceMat
               histogramBins:kHistogramBins];

    auto histogram = [[PNKColorTransferHistogram alloc]
                      initWithDevice:device histogramBins:kHistogramBins
                      inputSize:inputMat.total()];
    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:buffers.input
                     transformBuffer:buffers.transform minValueBuffer:buffers.minValue
                      maxValueBuffer:buffers.maxValue histogramBuffer:buffers.inputHistogram];

    histogram = [[PNKColorTransferHistogram alloc]
                 initWithDevice:device histogramBins:kHistogramBins
                 inputSize:referenceMat.total()];
    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:buffers.reference
                     transformBuffer:buffers.transform minValueBuffer:buffers.minValue
                      maxValueBuffer:buffers.maxValue histogramBuffer:buffers.referenceHistogram];

    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:kHistogramBins];
    [cdf encodeToCommandBuffer:commandBuffer inputHistogramBuffer:buffers.inputHistogram
      referenceHistogramBuffer:buffers.referenceHistogram minValueBuffer:buffers.minValue
                maxValueBuffer:buffers.maxValue cdfBuffers:buffers.inputCDFs
             inverseCDFBuffers:buffers.referenceInverseCDFs];

    histogramSpecification = [[PNKColorTransferHistogramSpecification alloc]
                              initWithDevice:device histogramBins:kHistogramBins
                              dampingFactor:kDampingFactor];
  });

  afterEach(^{
    buffers = nil;
  });

  it(@"should perform histogram specification", ^{
    [histogramSpecification
     encodeToCommandBuffer:commandBuffer dataBuffer:buffers.input transformBuffer:buffers.transform
     minValueBuffer:buffers.minValue maxValueBuffer:buffers.maxValue
     inputCDFBuffers:buffers.inputCDFs referenceInverseCDFBuffers:buffers.referenceInverseCDFs];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    expect(commandBuffer.error).to.beNil();

    auto result = PNKMatFromRGBBuffer(buffers.input);
    auto expected = PNKTestHistogramSpecification(inputMat, buffers.inputCDFs,
                                                  buffers.referenceInverseCDFs,
                                                  {0, 0, 0}, {1, 1, 1});
    expect($(result)).to.beCloseToMatWithin($(expected), 1e-4);
  });

  it(@"should perform histogram specification with non identity rotation", ^{
    cv::Mat1f rotation = (cv::Mat1f(3, 3) << 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0);
    auto transformBuffer = PNKCreateBufferFromTransformMat(device, rotation);

    [histogramSpecification
     encodeToCommandBuffer:commandBuffer dataBuffer:buffers.input transformBuffer:transformBuffer
     minValueBuffer:buffers.minValue maxValueBuffer:buffers.maxValue
     inputCDFBuffers:buffers.inputCDFs referenceInverseCDFBuffers:buffers.referenceInverseCDFs];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    expect(commandBuffer.error).to.beNil();

    auto result = PNKMatFromRGBBuffer(buffers.input);
    cv::cvtColor(inputMat, inputMat, cv::COLOR_RGB2BGR);
    auto expected = PNKTestHistogramSpecification(inputMat, buffers.inputCDFs,
                                                  buffers.referenceInverseCDFs,
                                                  {0, 0, 0}, {1, 1, 1});
    cv::cvtColor(expected, expected, cv::COLOR_RGB2BGR);
    expect($(result)).to.beCloseToMatWithin($(expected), 1e-4);
  });

  it(@"should perform histogram specification with different damping factor", ^{
    histogramSpecification = [[PNKColorTransferHistogramSpecification alloc]
                              initWithDevice:device histogramBins:kHistogramBins
                              dampingFactor:0.75];
    [histogramSpecification
     encodeToCommandBuffer:commandBuffer dataBuffer:buffers.input transformBuffer:buffers.transform
     minValueBuffer:buffers.minValue maxValueBuffer:buffers.maxValue
     inputCDFBuffers:buffers.inputCDFs referenceInverseCDFBuffers:buffers.referenceInverseCDFs];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    expect(commandBuffer.error).to.beNil();

    auto result = PNKMatFromRGBBuffer(buffers.input);
    auto expected = PNKTestHistogramSpecification(inputMat, buffers.inputCDFs,
                                                  buffers.referenceInverseCDFs,
                                                  {0, 0, 0}, {1, 1, 1});
    expected = inputMat * 0.25 + expected * 0.75;
    expect($(result)).to.beCloseToMatWithin($(expected), 1e-4);
  });

  it(@"should perform histogram specification with with non-canonic range", ^{
    Floats minValue = {0.1, 0.2, 0.3};
    Floats maxValue = {0.9, 0.8, 0.7};
    std::copy(minValue.begin(), minValue.end(), (float *)buffers.minValue.contents);
    std::copy(maxValue.begin(), maxValue.end(), (float *)buffers.maxValue.contents);

    auto histogram = [[PNKColorTransferHistogram alloc]
                      initWithDevice:device histogramBins:kHistogramBins
                      inputSize:inputMat.total()];
    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:buffers.input
                     transformBuffer:buffers.transform minValueBuffer:buffers.minValue
                      maxValueBuffer:buffers.maxValue histogramBuffer:buffers.inputHistogram];

    histogram = [[PNKColorTransferHistogram alloc]
                 initWithDevice:device histogramBins:kHistogramBins
                 inputSize:referenceMat.total()];
    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:buffers.reference
                     transformBuffer:buffers.transform minValueBuffer:buffers.minValue
                      maxValueBuffer:buffers.maxValue histogramBuffer:buffers.referenceHistogram];

    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:kHistogramBins];
    [cdf encodeToCommandBuffer:commandBuffer inputHistogramBuffer:buffers.inputHistogram
      referenceHistogramBuffer:buffers.referenceHistogram minValueBuffer:buffers.minValue
                maxValueBuffer:buffers.maxValue cdfBuffers:buffers.inputCDFs
             inverseCDFBuffers:buffers.referenceInverseCDFs];

    histogramSpecification = [[PNKColorTransferHistogramSpecification alloc]
                              initWithDevice:device histogramBins:kHistogramBins
                              dampingFactor:kDampingFactor];

    [histogramSpecification
     encodeToCommandBuffer:commandBuffer dataBuffer:buffers.input transformBuffer:buffers.transform
     minValueBuffer:buffers.minValue maxValueBuffer:buffers.maxValue
     inputCDFBuffers:buffers.inputCDFs referenceInverseCDFBuffers:buffers.referenceInverseCDFs];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    expect(commandBuffer.error).to.beNil();

    auto result = PNKMatFromRGBBuffer(buffers.input);
    auto expected = PNKTestHistogramSpecification(inputMat, buffers.inputCDFs,
                                                  buffers.referenceInverseCDFs, minValue, maxValue);
    expect($(result)).to.beCloseToMatWithin($(expected), 1e-4);
  });

  it(@"should perform histogram specification with a smaller number of bins", ^{
    static const NSUInteger kHistogramBins = 15;
    buffers = [[PNKColorTransferHistogramSpecificationBuffers alloc]
               initWithDevice:device inputMat:inputMat referenceMat:referenceMat
               histogramBins:kHistogramBins];

    auto histogram = [[PNKColorTransferHistogram alloc]
                      initWithDevice:device histogramBins:kHistogramBins
                      inputSize:inputMat.total()];
    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:buffers.input
                     transformBuffer:buffers.transform minValueBuffer:buffers.minValue
                      maxValueBuffer:buffers.maxValue histogramBuffer:buffers.inputHistogram];

    histogram = [[PNKColorTransferHistogram alloc]
                 initWithDevice:device histogramBins:kHistogramBins
                 inputSize:referenceMat.total()];
    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:buffers.reference
                     transformBuffer:buffers.transform minValueBuffer:buffers.minValue
                      maxValueBuffer:buffers.maxValue histogramBuffer:buffers.referenceHistogram];

    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:kHistogramBins];
    [cdf encodeToCommandBuffer:commandBuffer inputHistogramBuffer:buffers.inputHistogram
      referenceHistogramBuffer:buffers.referenceHistogram minValueBuffer:buffers.minValue
                maxValueBuffer:buffers.maxValue cdfBuffers:buffers.inputCDFs
             inverseCDFBuffers:buffers.referenceInverseCDFs];

    histogramSpecification = [[PNKColorTransferHistogramSpecification alloc]
                              initWithDevice:device histogramBins:kHistogramBins
                              dampingFactor:kDampingFactor];

    [histogramSpecification
     encodeToCommandBuffer:commandBuffer dataBuffer:buffers.input transformBuffer:buffers.transform
     minValueBuffer:buffers.minValue maxValueBuffer:buffers.maxValue
     inputCDFBuffers:buffers.inputCDFs referenceInverseCDFBuffers:buffers.referenceInverseCDFs];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    expect(commandBuffer.error).to.beNil();

    auto result = PNKMatFromRGBBuffer(buffers.input);
    auto expected = PNKTestHistogramSpecification(inputMat, buffers.inputCDFs,
                                                  buffers.referenceInverseCDFs,
                                                  {0, 0, 0}, {1, 1, 1});
    expect($(result)).to.beCloseToMatWithin($(expected), 1e-4);
  });

  it(@"should perform histogram specification with a larger number of bins", ^{
    static const NSUInteger kHistogramBins = 1016;
    buffers = [[PNKColorTransferHistogramSpecificationBuffers alloc]
               initWithDevice:device inputMat:inputMat referenceMat:referenceMat
               histogramBins:kHistogramBins];

    auto histogram = [[PNKColorTransferHistogram alloc]
                      initWithDevice:device histogramBins:kHistogramBins
                      inputSize:inputMat.total()];
    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:buffers.input
                     transformBuffer:buffers.transform minValueBuffer:buffers.minValue
                      maxValueBuffer:buffers.maxValue histogramBuffer:buffers.inputHistogram];

    histogram = [[PNKColorTransferHistogram alloc]
                 initWithDevice:device histogramBins:kHistogramBins
                 inputSize:referenceMat.total()];
    [histogram encodeToCommandBuffer:commandBuffer inputBuffer:buffers.reference
                     transformBuffer:buffers.transform minValueBuffer:buffers.minValue
                      maxValueBuffer:buffers.maxValue histogramBuffer:buffers.referenceHistogram];

    auto cdf = [[PNKColorTransferCDF alloc] initWithDevice:device histogramBins:kHistogramBins];
    [cdf encodeToCommandBuffer:commandBuffer inputHistogramBuffer:buffers.inputHistogram
      referenceHistogramBuffer:buffers.referenceHistogram minValueBuffer:buffers.minValue
                maxValueBuffer:buffers.maxValue cdfBuffers:buffers.inputCDFs
             inverseCDFBuffers:buffers.referenceInverseCDFs];

    histogramSpecification = [[PNKColorTransferHistogramSpecification alloc]
                              initWithDevice:device histogramBins:kHistogramBins
                              dampingFactor:kDampingFactor];

    [histogramSpecification
     encodeToCommandBuffer:commandBuffer dataBuffer:buffers.input transformBuffer:buffers.transform
     minValueBuffer:buffers.minValue maxValueBuffer:buffers.maxValue
     inputCDFBuffers:buffers.inputCDFs referenceInverseCDFBuffers:buffers.referenceInverseCDFs];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    expect(commandBuffer.error).to.beNil();

    auto result = PNKMatFromRGBBuffer(buffers.input);
    auto expected = PNKTestHistogramSpecification(inputMat, buffers.inputCDFs,
                                                  buffers.referenceInverseCDFs,
                                                  {0, 0, 0}, {1, 1, 1});
    expect($(result)).to.beCloseToMatWithin($(expected), 1e-4);
  });
});

DeviceSpecEnd
