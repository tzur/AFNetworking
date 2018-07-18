// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MPSTemporaryImage+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MPSTemporaryImage (Factory)

+ (MPSTemporaryImage *)mtb_temporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                                    format:(MPSImageFeatureChannelFormat)format
                                                     width:(NSUInteger)width
                                                    height:(NSUInteger)height
                                                  channels:(NSUInteger)channels {
  auto descriptor = [MPSImageDescriptor imageDescriptorWithChannelFormat:format width:width
                                                                  height:height
                                                         featureChannels:channels];
  return [MPSTemporaryImage temporaryImageWithCommandBuffer:commandBuffer
                                            imageDescriptor:descriptor];
}

+ (MPSTemporaryImage *)mtb_temporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                                    format:(MPSImageFeatureChannelFormat)format
                                                      size:(MTLSize)size {
  return [MPSTemporaryImage mtb_temporaryImageWithCommandBuffer:commandBuffer format:format
                                                          width:size.width height:size.height
                                                       channels:size.depth];
}

+ (MPSTemporaryImage *)mtb_unorm8TemporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                                           width:(NSUInteger)width
                                                          height:(NSUInteger)height
                                                        channels:(NSUInteger)channels {
  return [MPSTemporaryImage mtb_temporaryImageWithCommandBuffer:commandBuffer
                                                         format:MPSImageFeatureChannelFormatUnorm8
                                                          width:width height:height
                                                       channels:channels];
}

+ (MPSTemporaryImage *)mtb_unorm8TemporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                                            size:(MTLSize)size {
  return [MPSTemporaryImage mtb_temporaryImageWithCommandBuffer:commandBuffer
                                                         format:MPSImageFeatureChannelFormatUnorm8
                                                          width:size.width height:size.height
                                                       channels:size.depth];
}

+ (MPSTemporaryImage *)
    mtb_float16TemporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                         width:(NSUInteger)width height:(NSUInteger)height
                                      channels:(NSUInteger)channels {
  return [MPSTemporaryImage mtb_temporaryImageWithCommandBuffer:commandBuffer
                                                format:MPSImageFeatureChannelFormatFloat16
                                                 width:width height:height channels:channels];
}

+ (MPSTemporaryImage *)
    mtb_float16TemporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                          size:(MTLSize)size {
  return [MPSTemporaryImage mtb_temporaryImageWithCommandBuffer:commandBuffer
                                                         format:MPSImageFeatureChannelFormatFloat16
                                                          width:size.width height:size.height
                                                       channels:size.depth];
}

@end

NS_ASSUME_NONNULL_END
