// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

MPSImage *PNKImageMake(id<MTLDevice> device, MPSImageFeatureChannelFormat format,
                       NSUInteger width, NSUInteger height, NSUInteger channels) {
  auto imageDescriptor = [MPSImageDescriptor imageDescriptorWithChannelFormat:format width:width
                                                                       height:height
                                                              featureChannels:channels];
  return [[MPSImage alloc] initWithDevice:device imageDescriptor:imageDescriptor];
}

MPSImage *PNKImageMakeUnorm(id<MTLDevice> device, NSUInteger width, NSUInteger height,
                            NSUInteger channels) {
  return PNKImageMake(device, MPSImageFeatureChannelFormatUnorm8, width, height, channels);
}

NS_ASSUME_NONNULL_END
