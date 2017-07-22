// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

/// Kernel that performs the addition (sum) operation on two textures.
@interface PNKAddition : NSObject <PNKBinaryKernel>

/// Initializes a new kernel that runs on \c device.
- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputTexture
/// and \c secondaryInputTexture as input. Output is written asynchronously to \c outputTexture.
///
/// Sizes of \c primaryInputTexture, \c secondaryInputTexture and \c outputTexture must be the same.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
          primaryInputTexture:(id<MTLTexture>)primaryInputTexture
        secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

@end

NS_ASSUME_NONNULL_END
