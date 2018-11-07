// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKUnitRangeNormalization.h"

static const int kImageWidth = 16;
static const int kImageHeight = 15;
static const int kFeatureChannels = 3;

DeviceSpecBegin(PNKUnitRangeNormalization)

__block id<MTLDevice> device;
__block PNKUnitRangeNormalization *rescaler;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  rescaler = [[PNKUnitRangeNormalization alloc] initWithDevice:device];
});

afterEach(^{
  device = nil;
  rescaler = nil;
});

context(@"parameter validation", ^{
  __block id<MTLCommandBuffer> commandBuffer;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];
  });

  afterEach(^{
    commandBuffer = nil;
  });

  it(@"should raise when input image width does not fit output image width", ^{
    MTLSize inputSize{kImageWidth, kImageHeight, kFeatureChannels};
    MTLSize outputSize{kImageWidth + 1, kImageHeight, kFeatureChannels};

    auto inputImage = [MPSImage mtb_float16ImageWithDevice:device size:inputSize];
    auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
    expect(^{
      [rescaler encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input image height does not fit output image height", ^{
    MTLSize inputSize{kImageWidth, kImageHeight, kFeatureChannels};
    MTLSize outputSize{kImageWidth, kImageHeight + 1, kFeatureChannels};

    auto inputImage = [MPSImage mtb_float16ImageWithDevice:device size:inputSize];
    auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
    expect(^{
      [rescaler encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input image channel count does not fit output image channel count", ^{
    MTLSize inputSize{kImageWidth, kImageHeight, kFeatureChannels};
    MTLSize outputSize{kImageWidth, kImageHeight, kFeatureChannels + 1};

    auto inputImage = [MPSImage mtb_float16ImageWithDevice:device size:inputSize];
    auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
    expect(^{
      [rescaler encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input image texture type is MTLTextureType2DArray", ^{
    auto descriptor = [MTLTextureDescriptor
                       texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Float
                       width:kImageWidth height:kImageHeight mipmapped:NO];
    descriptor.textureType = MTLTextureType2DArray;
    auto inputTexture = [device newTextureWithDescriptor:descriptor];
    auto inputImage = [[MPSImage alloc] initWithTexture:inputTexture
                                        featureChannels:kFeatureChannels];
    auto outputImage = [MPSImage mtb_float16ImageWithDevice:device width:kImageWidth
                                                     height:kImageHeight channels:kFeatureChannels];
    expect(^{
      [rescaler encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when output image texture type is MTLTextureType2DArray", ^{
    auto descriptor = [MTLTextureDescriptor
                       texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Float
                       width:kImageWidth height:kImageHeight mipmapped:NO];
    descriptor.textureType = MTLTextureType2DArray;
    auto outputTexture = [device newTextureWithDescriptor:descriptor];
    auto outputImage = [[MPSImage alloc] initWithTexture:outputTexture
                                         featureChannels:kFeatureChannels];
    auto inputImage = [MPSImage mtb_float16ImageWithDevice:device width:kImageWidth
                                                    height:kImageHeight channels:kFeatureChannels];
    expect(^{
      [rescaler encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"rescaling", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    static const float kMinValue = 2;
    static const float kMaxValue = 5;

    cv::Mat3hf inputMat(kImageHeight, kImageWidth);
    cv::Mat3hf expectedMat(kImageHeight, kImageWidth);
    for (int i = 0; i < kImageHeight; ++i) {
      for (int j = 0; j < kImageWidth; ++j) {
        float scaledValue = ((float)(i + j)) / (kImageWidth + kImageHeight - 2);
        for (int k = 0; k < 3; ++k) {
          inputMat.at<cv::Vec3hf>(i, j)[k] = (half_float::half)
              ((k + 1) * (kMinValue + (kMaxValue - kMinValue) * scaledValue));
          expectedMat.at<cv::Vec3hf>(i, j)[k] = (half_float::half)scaledValue;
        }
      }
    }

    return @{
      kPNKKernelExamplesKernel: rescaler,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @3,
      kPNKKernelExamplesOutputWidth: @(kImageWidth),
      kPNKKernelExamplesOutputHeight: @(kImageHeight),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat),
      kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
    };
  });
});

DeviceSpecEnd
