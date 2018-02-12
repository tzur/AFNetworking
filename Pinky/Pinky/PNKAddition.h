// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Kernel that performs the addition (sum) operation on two textures.
API_AVAILABLE(ios(10.0))
@interface PNKAddition : NSObject <PNKBinaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device.
- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputImage
/// and \c secondaryInputImage as input. Output is written asynchronously to \c outputImage.
///
/// Sizes of \c primaryInputImage, \c secondaryInputImage and \c outputImage must be the same.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage
                  outputImage:(MPSImage *)outputImage;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
