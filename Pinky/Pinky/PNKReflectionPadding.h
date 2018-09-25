// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKKernel.h"
#import "PNKPaddingSize.h"

NS_ASSUME_NONNULL_BEGIN

/// Kernel that performs reflection padding of textures. Padding is done in a manner such that the
/// value at the border is not repeated, i.e. <tt>dcb|abcdefgh|gfe</tt>. Padding is done up to the
/// size of the original input in each direction, larger paddings require multiple passes.
@interface PNKReflectionPadding : NSObject <PNKUnaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and applies left, top, right and bottom padding
/// as defined by \c paddingSize.
- (instancetype)initWithDevice:(id<MTLDevice>)device paddingSize:(pnk::PaddingSize)paddingSize
    NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage.
///
/// The number of channels in \c inputImage and \c outputImage must be equal. \c inputImage width
/// and height must be larger than the corresponding parameters in \c padding. The width and height
/// of \c outputImage must be exactly those of \c inputImage with the addition of twice the padding
/// in each dimension.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage;

@end

NS_ASSUME_NONNULL_END
