// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Protocol implemented by kernels operating on a single input texture.
@protocol PNKUnaryKernel <NSObject>

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputTexture as
/// input. Output is written asynchronously to \c outputTexture.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage;

/// Determines which region of the input texture will be read either by
/// \c encodeToCommandBuffer:inputTexture:outputTexture: or by
/// \c encodeToCommandBuffer:inputImage:outputImage: when the kernel runs. \c outputSize should
/// be the size of the full (untiled) output image. The region of the full (untiled) input image
/// that will be read is returned. All kernel parameters should be set prior to calling this method
/// in order to receive the correct region.
- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize;

/// \c YES iff the kernel expects texture of array type as input for encoding. Kernels only support
/// array or non-array types and not both.
@property (readonly, nonatomic) BOOL isInputArray;

@end

/// Protocol implemented by kernels operating on two input textures.
@protocol PNKBinaryKernel <NSObject>

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputTexture
/// and \c secondaryInputTexture as input. Output is written asynchronously to \c outputTexture.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
          primaryInputTexture:(id<MTLTexture>)primaryInputTexture
        secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputImage
/// and \c secondaryInputImage as input. Output is written asynchronously to \c outputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage
                  outputImage:(MPSImage *)outputImage;

/// Determines which region of the primary input texture will be read either by
/// \c encodeToCommandBuffer:primaryInputTexture:secondaryInputTexture:outputTexture: or by
/// \c encodeToCommandBuffer:primaryInputImage:secondaryInputImage:outputImage: when the kernel
/// runs. \c outputSize should be the size of the full (untiled) output image. The region of the
/// full (untiled) primary input image that will be read is returned. All kernel parameters should
/// be set prior to calling this method in order to receive the correct region.
- (MTLRegion)primaryInputRegionForOutputSize:(MTLSize)outputSize;

/// Determines which region of the secondary input texture will be read either by
/// \c encodeToCommandBuffer:primaryInputTexture:secondaryInputTexture:outputTexture: or by
/// \c encodeToCommandBuffer:primaryInputImage:secondaryInputImage:outputImage: when the kernel
/// runs. \c outputSize should be the size of the full (untiled) output image. The region of the
/// full (untiled) secondary input image that will be read is returned. All kernel parameters should
/// be set prior to calling this method in order to receive the correct region.
- (MTLRegion)secondaryInputRegionForOutputSize:(MTLSize)outputSize;

/// \c YES iff the kernel expects texture of array type as input for encoding. Kernels only support
/// array or non-array types and not both.
@property (readonly, nonatomic) BOOL isInputArray;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
