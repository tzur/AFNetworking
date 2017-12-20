// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferMinAndMax.h"

#import "PNKColorTransferTestUtils.h"

static LTVector3 PNKVectorFromBuffer(id<MTLBuffer> buffer) {
  LTParameterAssert(buffer.length == 4 * sizeof(float));
  float *content = (float *)buffer.contents;
  return LTVector3(content[0], content[1], content[2]);
}

SpecBegin(PNKColorTransferMinAndMax)

__block id<MTLDevice> device;
__block id<MTLCommandBuffer> commandBuffer;
__block id<MTLBuffer> minValue;
__block id<MTLBuffer> maxValue;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];

  minValue = [device newBufferWithLength:4 * sizeof(float) options:MTLResourceStorageModeShared];
  maxValue = [device newBufferWithLength:4 * sizeof(float) options:MTLResourceStorageModeShared];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    auto minmax = [[PNKColorTransferMinAndMax alloc] initWithDevice:device
                                                         inputSizes:@[@1024, @1337]];
    expect(minmax.inputSizes).to.equal(@[@1024, @1337]);
  });

  it(@"should raise if initialized with empty sizes array", ^{
    expect(^{
      __unused auto minmax = [[PNKColorTransferMinAndMax alloc]
                              initWithDevice:device inputSizes:@[]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if initialized with invalid sizes", ^{
    expect(^{
      __unused auto minmax = [[PNKColorTransferMinAndMax alloc]
                              initWithDevice:device inputSizes:@[@1024, @0]];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      __unused auto minmax = [[PNKColorTransferMinAndMax alloc]
                              initWithDevice:device inputSizes:@[@-1, @1337]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"single input", ^{
  static const NSUInteger kInputSize = 31337;

  __block id<MTLBuffer> inputBuffer;
  __block PNKColorTransferMinAndMax *minmax;

  beforeEach(^{
    cv::Mat3f input = cv::Mat3f::zeros(1, kInputSize);
    input(0, 11337) = cv::Vec3f(0.75, 0.25, -0.25);
    input(0, 21337) = cv::Vec3f(-0.35, 0.85, 0.25);
    input(0, 27337) = cv::Vec3f(0.25, -0.45, 0.95);
    inputBuffer = PNKCreateBufferFromMat(device, input);

    minmax = [[PNKColorTransferMinAndMax alloc] initWithDevice:device
                                                    inputSizes:@[@(kInputSize)]];
  });

  it(@"should find min and max without rotation", ^{
    auto transformBuffer = PNKCreateBufferFromTransformMat(device, cv::Mat1f::eye(3, 3));

    [minmax encodeToCommandBuffer:commandBuffer inputBuffers:@[inputBuffer]
                  transformBuffer:transformBuffer minValueBuffer:minValue maxValueBuffer:maxValue];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    expect(PNKVectorFromBuffer(minValue))
        .to.beCloseToLTVectorWithin(LTVector3(-0.35, -0.45, -0.25), 1e-3);
    expect(PNKVectorFromBuffer(maxValue))
        .to.beCloseToLTVectorWithin(LTVector3(0.75, 0.85, 0.95), 1e-3);
  });

  it(@"should find min and max with rotation", ^{
    cv::Mat1f rotation = (cv::Mat1f(3, 3) << 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0);
    auto transformBuffer = PNKCreateBufferFromTransformMat(device, rotation);

    [minmax encodeToCommandBuffer:commandBuffer inputBuffers:@[inputBuffer]
                  transformBuffer:transformBuffer minValueBuffer:minValue maxValueBuffer:maxValue];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    expect(PNKVectorFromBuffer(minValue))
        .to.beCloseToLTVectorWithin(LTVector3(-0.45, -0.25, -0.35), 1e-3);
    expect(PNKVectorFromBuffer(maxValue))
        .to.beCloseToLTVectorWithin(LTVector3(0.85, 0.95, 0.75), 1e-3);
  });

  it(@"should find min and max on a small input", ^{
    cv::Mat3f input = cv::Mat3f::zeros(1, 5);
    input(0, 0) = cv::Vec3f(0.75, 0.25, -0.25);
    input(0, 1) = cv::Vec3f(-0.35, 0.85, 0.25);
    input(0, 2) = cv::Vec3f(0.25, -0.45, 0.95);
    inputBuffer = PNKCreateBufferFromMat(device, input);

    auto transformBuffer = PNKCreateBufferFromTransformMat(device, cv::Mat1f::eye(3, 3));

    minmax = [[PNKColorTransferMinAndMax alloc] initWithDevice:device inputSizes:@[@(input.cols)]];
    [minmax encodeToCommandBuffer:commandBuffer inputBuffers:@[inputBuffer]
                  transformBuffer:transformBuffer minValueBuffer:minValue maxValueBuffer:maxValue];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    expect(PNKVectorFromBuffer(minValue))
        .to.beCloseToLTVectorWithin(LTVector3(-0.35, -0.45, -0.25), 1e-3);
    expect(PNKVectorFromBuffer(maxValue))
        .to.beCloseToLTVectorWithin(LTVector3(0.75, 0.85, 0.95), 1e-3);
  });
});

context(@"multiple inputs", ^{
  static const std::vector<NSUInteger> kInputSizes = {31337, 12345, 29112};

  __block NSArray<id<MTLBuffer>> *inputBuffers;
  __block PNKColorTransferMinAndMax *minmax;

  beforeEach(^{
    std::vector<cv::Mat3f> inputs(3);
    for (NSUInteger i = 0; i < inputs.size(); ++i) {
      inputs[i] = cv::Mat3f::zeros(1, (int)kInputSizes[i]);
    }

    inputs[0](0, 27337) = cv::Vec3f(0.75, 0.25, -0.25);
    inputs[1](0, 11337) = cv::Vec3f(-0.35, 0.85, 0.25);
    inputs[2](0, 21337) = cv::Vec3f(0.25, -0.45, 0.95);

    auto tempBuffers = [NSMutableArray array];
    for (auto &input : inputs) {
      [tempBuffers addObject:PNKCreateBufferFromMat(device, input)];
    }
    inputBuffers = [tempBuffers copy];

    auto sizes = @[@(kInputSizes[0]), @(kInputSizes[1]), @(kInputSizes[2])];
    minmax = [[PNKColorTransferMinAndMax alloc] initWithDevice:device inputSizes:sizes];
  });

  it(@"should find min and max without rotation", ^{
    auto transformBuffer = PNKCreateBufferFromTransformMat(device, cv::Mat1f::eye(3, 3));

    [minmax encodeToCommandBuffer:commandBuffer inputBuffers:inputBuffers
                  transformBuffer:transformBuffer minValueBuffer:minValue maxValueBuffer:maxValue];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    expect(PNKVectorFromBuffer(minValue))
        .to.beCloseToLTVectorWithin(LTVector3(-0.35, -0.45, -0.25), 1e-3);
    expect(PNKVectorFromBuffer(maxValue))
        .to.beCloseToLTVectorWithin(LTVector3(0.75, 0.85, 0.95), 1e-3);
  });

  it(@"should find min and max with rotation", ^{
    cv::Mat1f rotation = (cv::Mat1f(3, 3) << 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0);
    auto transformBuffer = PNKCreateBufferFromTransformMat(device, rotation);

    [minmax encodeToCommandBuffer:commandBuffer inputBuffers:inputBuffers
                  transformBuffer:transformBuffer minValueBuffer:minValue maxValueBuffer:maxValue];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    expect(PNKVectorFromBuffer(minValue))
        .to.beCloseToLTVectorWithin(LTVector3(-0.45, -0.25, -0.35), 1e-3);
    expect(PNKVectorFromBuffer(maxValue))
        .to.beCloseToLTVectorWithin(LTVector3(0.85, 0.95, 0.75), 1e-3);
  });
});

SpecEnd
