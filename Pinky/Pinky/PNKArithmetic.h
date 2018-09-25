// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

/// Kernel that performs basic arithmetic per-pixel operations on two textures.
@interface PNKArithmetic : NSObject <PNKBinaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and performs \c operation.
- (instancetype)initWithDevice:(id<MTLDevice>)device operation:(pnk::ArithmeticOperation)operation
    NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputImage
/// and \c secondaryInputImage as input. Output is written asynchronously to \c outputImage.
///
/// Sizes of \c primaryInputImage, \c secondaryInputImage and \c outputImage must be the same.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage
                  outputImage:(MPSImage *)outputImage;

@end

NS_ASSUME_NONNULL_END
