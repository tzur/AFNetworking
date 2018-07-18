// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MPSTemporaryImage+Factory.h"

#import "MTBImagePropertiesExamples.h"

DeviceSpecBegin(MPSTemporaryImage_Factory)

static NSUInteger kWidth = 5;
static NSUInteger kHeight = 4;
static NSUInteger kChannels = 3;

__block id<MTLCommandBuffer> commandBuffer;

beforeEach(^{
  auto device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
});

afterEach(^{
  commandBuffer = nil;
});

itShouldBehaveLike(kMTBImagePropertiesExamples, ^{
  auto image = [MPSTemporaryImage mtb_temporaryImageWithCommandBuffer:commandBuffer
                                                      format:MPSImageFeatureChannelFormatUnorm8
                                                       width:kWidth height:kHeight
                                                    channels:kChannels];

  return @{
    kMTBImagePropertiesExamplesImage: image,
    kMTBImagePropertiesExamplesWidth: @(kWidth),
    kMTBImagePropertiesExamplesHeight: @(kHeight),
    kMTBImagePropertiesExamplesFeatureChannels: @(kChannels),
    kMTBImagePropertiesExamplesPixelFormat: @(MTLPixelFormatRGBA8Unorm)
  };
});

itShouldBehaveLike(kMTBImagePropertiesExamples, ^{
  auto image = [MPSTemporaryImage mtb_temporaryImageWithCommandBuffer:commandBuffer
                format:MPSImageFeatureChannelFormatUnorm8 size:{kWidth, kHeight, kChannels}];

  return @{
    kMTBImagePropertiesExamplesImage: image,
    kMTBImagePropertiesExamplesWidth: @(kWidth),
    kMTBImagePropertiesExamplesHeight: @(kHeight),
    kMTBImagePropertiesExamplesFeatureChannels: @(kChannels),
    kMTBImagePropertiesExamplesPixelFormat: @(MTLPixelFormatRGBA8Unorm)
  };
});

itShouldBehaveLike(kMTBImagePropertiesExamples, ^{
  auto image = [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                                                                      width:kWidth
                                                                     height:kHeight
                                                                   channels:kChannels];

  return @{
    kMTBImagePropertiesExamplesImage: image,
    kMTBImagePropertiesExamplesWidth: @(kWidth),
    kMTBImagePropertiesExamplesHeight: @(kHeight),
    kMTBImagePropertiesExamplesFeatureChannels: @(kChannels),
    kMTBImagePropertiesExamplesPixelFormat: @(MTLPixelFormatRGBA8Unorm)
  };
});

itShouldBehaveLike(kMTBImagePropertiesExamples, ^{
  auto image = [MPSTemporaryImage mtb_unorm8TemporaryImageWithCommandBuffer:commandBuffer
                size:{kWidth, kHeight, kChannels}];

  return @{
    kMTBImagePropertiesExamplesImage: image,
    kMTBImagePropertiesExamplesWidth: @(kWidth),
    kMTBImagePropertiesExamplesHeight: @(kHeight),
    kMTBImagePropertiesExamplesFeatureChannels: @(kChannels),
    kMTBImagePropertiesExamplesPixelFormat: @(MTLPixelFormatRGBA8Unorm)
  };
});

itShouldBehaveLike(kMTBImagePropertiesExamples, ^{
  auto image = [MPSTemporaryImage mtb_float16TemporaryImageWithCommandBuffer:commandBuffer
                                                                       width:kWidth
                                                                      height:kHeight
                                                                    channels:kChannels];

  return @{
    kMTBImagePropertiesExamplesImage: image,
    kMTBImagePropertiesExamplesWidth: @(kWidth),
    kMTBImagePropertiesExamplesHeight: @(kHeight),
    kMTBImagePropertiesExamplesFeatureChannels: @(kChannels),
    kMTBImagePropertiesExamplesPixelFormat: @(MTLPixelFormatRGBA16Float)
  };
});

itShouldBehaveLike(kMTBImagePropertiesExamples, ^{
  auto image = [MPSTemporaryImage mtb_float16TemporaryImageWithCommandBuffer:commandBuffer
                size:{kWidth, kHeight, kChannels}];

  return @{
    kMTBImagePropertiesExamplesImage: image,
    kMTBImagePropertiesExamplesWidth: @(kWidth),
    kMTBImagePropertiesExamplesHeight: @(kHeight),
    kMTBImagePropertiesExamplesFeatureChannels: @(kChannels),
    kMTBImagePropertiesExamplesPixelFormat: @(MTLPixelFormatRGBA16Float)
  };
});

DeviceSpecEnd
