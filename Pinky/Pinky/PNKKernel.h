// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Protocol implemented by kernels operating on a single input texture.
@protocol PNKBasicUnaryKernel <NSObject>

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

/// Protocol implemented by kernels operating on a single input texture without any additional
/// input parameters.
@protocol PNKUnaryKernel <PNKBasicUnaryKernel>

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage;

@end

/// Protocol implemented by kernels operating on a single input texture and an arbitrary number of
/// input parameters that must fit the parameters named in \c inputParameterKernelNames.
@protocol PNKParametricUnaryKernel <PNKBasicUnaryKernel>

/// Sets the kernel parameters using \c inputParameters and then encodes the operation performed by
/// the kernel to \c commandBuffer using \c inputImage as input. Output is written asynchronously to
/// \c outputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage
              inputParameters:(NSDictionary<NSString *, NSObject *> *)inputParameters
                  outputImage:(MPSImage *)outputImage;

/// Returns an array of names of input parameters that the kernel expects to receive in a
/// \c encodeToCommandBuffer:inputImage:inputParameters:outputImage: call.
- (NSArray<NSString *> *)inputParameterKernelNames;

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

NS_ASSUME_NONNULL_END
