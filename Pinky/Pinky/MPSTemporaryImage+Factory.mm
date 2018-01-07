// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "MPSTemporaryImage+Factory.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Category for conveniently creating \c MPSImage objects.
@implementation MPSTemporaryImage (Factory)

+ (MPSTemporaryImage *)pnk_imageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                           format:(MPSImageFeatureChannelFormat)format
                                            width:(NSUInteger)width height:(NSUInteger)height
                                         channels:(NSUInteger)channels {
  auto descriptor = [MPSImageDescriptor imageDescriptorWithChannelFormat:format width:width
                                                                  height:height
                                                         featureChannels:channels];
  return [MPSTemporaryImage temporaryImageWithCommandBuffer:buffer imageDescriptor:descriptor];
}

+ (MPSTemporaryImage *)pnk_imageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                           format:(MPSImageFeatureChannelFormat)format
                                             size:(MTLSize)size {
  return [MPSTemporaryImage pnk_imageWithCommandBuffer:buffer format:format width:size.width
                                                height:size.height channels:size.depth];
}

+ (MPSTemporaryImage *)pnk_unorm8ImageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                                  width:(NSUInteger)width height:(NSUInteger)height
                                               channels:(NSUInteger)channels {
  return [MPSTemporaryImage pnk_imageWithCommandBuffer:buffer
                                                format:MPSImageFeatureChannelFormatUnorm8
                                                 width:width height:height channels:channels];
}

+ (MPSTemporaryImage *)pnk_unorm8ImageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                                   size:(MTLSize)size {
  return [MPSTemporaryImage pnk_unorm8ImageWithCommandBuffer:buffer width:size.width
                                                      height:size.height channels:size.depth];
}

+ (MPSTemporaryImage *)pnk_float16ImageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                                   width:(NSUInteger)width height:(NSUInteger)height
                                                channels:(NSUInteger)channels {
  return [MPSTemporaryImage pnk_imageWithCommandBuffer:buffer
                                                format:MPSImageFeatureChannelFormatFloat16
                                                 width:width height:height channels:channels];
}

+ (MPSTemporaryImage *)pnk_float16ImageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                                    size:(MTLSize)size {
  return [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer width:size.width
                                                       height:size.height channels:size.depth];
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END

