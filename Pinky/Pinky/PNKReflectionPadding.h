// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

namespace pnk {
  /// Parameters for symmetric padding.
  struct SymmetricPadding {
    NSUInteger width;
    NSUInteger height;
  };
} // namespace pnk

/// Kernel that performs a symmetric reflection padding of textures. Padding is done in a manner
/// such that the value at the border is not repeated, i.e. <tt>dcb|abcdefgh|gfe</tt>. Padding is
/// done up to the size of the original input in each side, larger paddings require multiple passes.
@interface PNKReflectionPadding : NSObject <PNKUnaryImageKernel>

/// Initializes a new kernel that runs on \c device and applies \c padding to the width and height
/// of each channel.
- (instancetype)initWithDevice:(id<MTLDevice>)device inputIsArray:(BOOL)inputIsArray
                   paddingSize:(pnk::SymmetricPadding)padding NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputTexture as
/// input. Output is written asynchronously to \c outputTexture.
///
/// The number of channels in \c inputTexture and \c outputTexture must be equal. \c inputTexture
/// width and height must be larger than the corresponding parameters in \c padding. The width and
/// height of \c outputTexture must be exactly those of \c inputTexture with the addition of twice
/// the padding in each dimension.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage.
///
/// The number of channels in \c inputImage and \c outputImage must be equal. \c inputImage width
/// and height must be larger than the corresponding parameters in \c padding. The width and height
/// of \c outputImage must be exactly those of \c inputImage with the addition of twice the padding
/// in each dimension.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage;

/// Padding to apply.
@property (readonly, nonatomic) pnk::SymmetricPadding padding;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
