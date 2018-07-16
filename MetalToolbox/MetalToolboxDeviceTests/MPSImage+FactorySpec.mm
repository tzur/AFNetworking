// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MPSImage+Factory.h"

#import "MTBImagePropertiesExamples.h"

DeviceSpecBegin(MPSImage_Factory)

static NSUInteger kWidth = 5;
static NSUInteger kHeight = 4;
static NSUInteger kChannels = 3;

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

itShouldBehaveLike(kMTBImagePropertiesExamples, ^{
  auto image = [MPSImage mtb_imageWithDevice:device format:MPSImageFeatureChannelFormatUnorm8
                                       width:kWidth height:kHeight channels:kChannels];

  return @{
    kMTBImagePropertiesExamplesImage: image,
    kMTBImagePropertiesExamplesWidth: @(kWidth),
    kMTBImagePropertiesExamplesHeight: @(kHeight),
    kMTBImagePropertiesExamplesFeatureChannels: @(kChannels),
    kMTBImagePropertiesExamplesPixelFormat: @(MTLPixelFormatRGBA8Unorm)
  };
});

itShouldBehaveLike(kMTBImagePropertiesExamples, ^{
  auto image = [MPSImage mtb_imageWithDevice:device format:MPSImageFeatureChannelFormatUnorm8
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
  auto image = [MPSImage mtb_unorm8ImageWithDevice:device width:kWidth height:kHeight
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
  auto image = [MPSImage mtb_unorm8ImageWithDevice:device size:{kWidth, kHeight, kChannels}];

  return @{
    kMTBImagePropertiesExamplesImage: image,
    kMTBImagePropertiesExamplesWidth: @(kWidth),
    kMTBImagePropertiesExamplesHeight: @(kHeight),
    kMTBImagePropertiesExamplesFeatureChannels: @(kChannels),
    kMTBImagePropertiesExamplesPixelFormat: @(MTLPixelFormatRGBA8Unorm)
  };
});

itShouldBehaveLike(kMTBImagePropertiesExamples, ^{
  auto image = [MPSImage mtb_float16ImageWithDevice:device width:kWidth height:kHeight
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
  auto image = [MPSImage mtb_float16ImageWithDevice:device size:{kWidth, kHeight, kChannels}];

  return @{
    kMTBImagePropertiesExamplesImage: image,
    kMTBImagePropertiesExamplesWidth: @(kWidth),
    kMTBImagePropertiesExamplesHeight: @(kHeight),
    kMTBImagePropertiesExamplesFeatureChannels: @(kChannels),
    kMTBImagePropertiesExamplesPixelFormat: @(MTLPixelFormatRGBA16Float)
  };
});

DeviceSpecEnd
