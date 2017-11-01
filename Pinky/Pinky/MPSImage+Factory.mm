// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "MPSImage+Factory.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Category for conveniently creating \c MPSImage objects.
@implementation MPSImage (Factory)

+ (MPSImage *)pnk_imageWithDevice:(id<MTLDevice>)device
                           format:(MPSImageFeatureChannelFormat)format
                            width:(NSUInteger)width height:(NSUInteger)height
                         channels:(NSUInteger)channels {
  auto descriptor = [MPSImageDescriptor imageDescriptorWithChannelFormat:format width:width
                                                                  height:height
                                                         featureChannels:channels];
  return [[MPSImage alloc] initWithDevice:device imageDescriptor:descriptor];
}

+ (MPSImage *)pnk_imageWithDevice:(id<MTLDevice>)device
                           format:(MPSImageFeatureChannelFormat)format
                             size:(MTLSize)size {
  return [MPSImage pnk_imageWithDevice:device format:format
                                 width:size.width height:size.height channels:size.depth];
}

+ (MPSImage *)pnk_unorm8ImageWithDevice:(id<MTLDevice>)device
                                  width:(NSUInteger)width height:(NSUInteger)height
                               channels:(NSUInteger)channels {
  return [MPSImage pnk_imageWithDevice:device format:MPSImageFeatureChannelFormatUnorm8
                                 width:width height:height channels:channels];
}

+ (MPSImage *)pnk_unorm8ImageWithDevice:(id<MTLDevice>)device
                                   size:(MTLSize)size {
  return [MPSImage pnk_imageWithDevice:device format:MPSImageFeatureChannelFormatUnorm8
                                 width:size.width height:size.height channels:size.depth];
}

+ (MPSImage *)pnk_float16ImageWithDevice:(id<MTLDevice>)device
                                   width:(NSUInteger)width height:(NSUInteger)height
                                channels:(NSUInteger)channels {
  return [MPSImage pnk_imageWithDevice:device format:MPSImageFeatureChannelFormatFloat16
                                 width:width height:height channels:channels];
}

+ (MPSImage *)pnk_float16ImageWithDevice:(id<MTLDevice>)device
                                    size:(MTLSize)size {
  return [MPSImage pnk_imageWithDevice:device format:MPSImageFeatureChannelFormatFloat16
                                 width:size.width height:size.height channels:size.depth];
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
