// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Kernel that performs the addition (sum) operation on two textures.
@interface PNKAddition : NSObject <PNKBinaryImageKernel>

/// Initializes a new kernel that runs on \c device.
- (instancetype)initWithDevice:(id<MTLDevice>)device withInputIsArray:(BOOL)inputIsArray
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputTexture
/// and \c secondaryInputTexture as input. Output is written asynchronously to \c outputTexture.
///
/// Sizes of \c primaryInputTexture, \c secondaryInputTexture and \c outputTexture must be the same.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
          primaryInputTexture:(id<MTLTexture>)primaryInputTexture
        secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

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
