// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct PaddingSize;
};

/// Kernel that crops a rectangular area from the input image.
API_AVAILABLE(ios(10.0))
@interface PNKCrop : NSObject <PNKUnaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and crops a rectangular area from the input
/// image. The crop margins are defined by the \c margins parameter.
- (instancetype)initWithDevice:(id<MTLDevice>)device margins:(pnk::PaddingSize)margins
    NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage. \c outputImage must have width and height
/// that match the \c inputImage width and hight after substracting the corressponding margins as
/// defined by \c paddingSize. The number of channels in \c inputImage and \c outputImage must be
/// equal.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage;

@end

NS_ASSUME_NONNULL_END
