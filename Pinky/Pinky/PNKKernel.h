// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Protocol implemented by kernels operating on a single input texture.
@protocol PNKUnaryKernel <NSObject>

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage;

/// Determines which region of the \c inputImage will be read by
/// \c encodeToCommandBuffer:inputImage:outputImage: when the kernel runs. \c outputSize should
/// be the size of the full (untiled) output image. The region of the full (untiled) input image
/// that will be read is returned. All kernel parameters should be set prior to calling this method
/// in order to receive the correct region.
- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize;

/// Determines the size of \c outputImage that fits the size of \c inputImage. All kernel
/// parameters should be set prior to calling this method in order to receive the correct size.
- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize;

/// Number of feature channels per pixel in the input image. \c 0 iff the kernel allows for
/// undetermined number of feature channels.
@property (readonly, nonatomic) NSUInteger inputFeatureChannels;

@end

/// Protocol implemented by kernels operating on two input textures.
@protocol PNKBinaryKernel <NSObject>

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputImage
/// and \c secondaryInputImage as input. Output is written asynchronously to \c outputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage
                  outputImage:(MPSImage *)outputImage;

/// Determines which region of the \c primaryInputImage will be read by
/// \c encodeToCommandBuffer:primaryInputImage:secondaryInputImage:outputImage: when the kernel
/// runs. \c outputSize should be the size of the full (untiled) output image. The region of the
/// full (untiled) primary input image that will be read is returned. All kernel parameters should
/// be set prior to calling this method in order to receive the correct region.
- (MTLRegion)primaryInputRegionForOutputSize:(MTLSize)outputSize;

/// Determines which region of the \c secondaryInputImage will be read by
/// \c encodeToCommandBuffer:primaryInputImage:secondaryInputImage:outputImage: when the kernel
/// runs. \c outputSize should be the size of the full (untiled) output image. The region of the
/// full (untiled) secondary input image that will be read is returned. All kernel parameters should
/// be set prior to calling this method in order to receive the correct region.
- (MTLRegion)secondaryInputRegionForOutputSize:(MTLSize)outputSize;

/// Determines the size of \c outputImage that fits the sizes of \c primaryInputImage and
/// \c secondaryInputImage. All kernel parameters should be set prior to calling this method in
/// order to receive the correct size.
- (MTLSize)outputSizeForPrimaryInputSize:(MTLSize)primaryInputSize
                      secondaryInputSize:(MTLSize)secondaryInputSize;

/// Number of feature channels per pixel in the primary input image. \c 0 iff the kernel allows for
/// undetermined number of feature channels.
@property (readonly, nonatomic) NSUInteger primaryInputFeatureChannels;

/// Number of feature channels per pixel in the secondary input image. \c 0 iff the kernel allows
/// for undetermined number of feature channels.
@property (readonly, nonatomic) NSUInteger secondaryInputFeatureChannels;

@end

/// Protocol implemented by kernels operating on a single input texture and supporting \c MTLTexture
/// as input in addition to \c MPSImage.
@protocol PNKUnaryImageKernel <PNKUnaryKernel>

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputTexture as
/// input. Output is written asynchronously to \c outputTexture.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

@end

/// Protocol implemented by kernels operating on two input textures and supporting \c MTLTexture
/// as inputs in addition to \c MPSImage.
@protocol PNKBinaryImageKernel <PNKBinaryKernel>

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputTexture
/// and \c secondaryInputTexture as input. Output is written asynchronously to \c outputTexture.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
          primaryInputTexture:(id<MTLTexture>)primaryInputTexture
        secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
