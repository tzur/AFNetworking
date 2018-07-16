// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MPSImage+Factory.h"

NS_ASSUME_NONNULL_BEGIN

/// Category for conveniently creating \c MPSImage objects.
@implementation MPSImage (Factory)

+ (MPSImage *)mtb_imageWithDevice:(id<MTLDevice>)device format:(MPSImageFeatureChannelFormat)format
                            width:(NSUInteger)width height:(NSUInteger)height
                         channels:(NSUInteger)channels {
  auto descriptor = [MPSImageDescriptor imageDescriptorWithChannelFormat:format width:width
                                                                  height:height
                                                         featureChannels:channels];
  return [[MPSImage alloc] initWithDevice:device imageDescriptor:descriptor];
}

+ (MPSImage *)mtb_imageWithDevice:(id<MTLDevice>)device format:(MPSImageFeatureChannelFormat)format
                             size:(MTLSize)size {
  return [MPSImage mtb_imageWithDevice:device format:format
                                 width:size.width height:size.height channels:size.depth];
}

+ (MPSImage *)mtb_unorm8ImageWithDevice:(id<MTLDevice>)device width:(NSUInteger)width
                                 height:(NSUInteger)height channels:(NSUInteger)channels {
  return [MPSImage mtb_imageWithDevice:device format:MPSImageFeatureChannelFormatUnorm8 width:width
                                height:height channels:channels];
}

+ (MPSImage *)mtb_unorm8ImageWithDevice:(id<MTLDevice>)device size:(MTLSize)size {
  return [MPSImage mtb_imageWithDevice:device format:MPSImageFeatureChannelFormatUnorm8
                                 width:size.width height:size.height channels:size.depth];
}

+ (MPSImage *)mtb_float16ImageWithDevice:(id<MTLDevice>)device width:(NSUInteger)width
                                  height:(NSUInteger)height channels:(NSUInteger)channels {
  return [MPSImage mtb_imageWithDevice:device format:MPSImageFeatureChannelFormatFloat16
                                 width:width height:height channels:channels];
}

+ (MPSImage *)mtb_float16ImageWithDevice:(id<MTLDevice>)device
                                    size:(MTLSize)size {
  return [MPSImage mtb_imageWithDevice:device format:MPSImageFeatureChannelFormatFloat16
                                 width:size.width height:size.height channels:size.depth];
}

@end

NS_ASSUME_NONNULL_END
