// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Protocol providing access to the basic information used by kernels operating on tensors in a
/// neural network. This protocol is meant to be used as a base for more concrete protocols and
/// should not be implemented directly.
@protocol PNKNeuralKernel <NSObject>

/// Width of the filter window.
@property (readonly, nonatomic) NSUInteger kernelWidth;

/// Height of the filter window.
@property (readonly, nonatomic) NSUInteger kernelHeight;

/// Number of feature channels per pixel in the input image.
@property (readonly, nonatomic) NSUInteger inputFeatureChannels;

/// Number of feature channels per pixel in the output image.
@property (readonly, nonatomic) NSUInteger outputFeatureChannels;

/// Output stride (downsampling factor) in the x dimension. The default value is 1.
@property (readonly, nonatomic) NSUInteger strideX;

/// Output stride (downsampling factor) in the y dimension. The default value is 1.
@property (readonly, nonatomic) NSUInteger strideY;

/// Number of groups input and output channels are divided into. The default value is 1, such that
/// all input channels are connected to all output channels. If groups is set to n, input is divided
/// into n groups with <tt>inputFeatureChannels / n</tt> channels in each group. Similarly output is
/// divided into n groups with <tt>outputFeatureChannels / n</tt> channels in each group. Each input
/// group is connected only to its corresponding output group. Both \c inputFeatureChannels and
/// \c outputFeatureChannels must be divisible by \c groups and number of channels in each group
/// must be a multiple of 4.
///
/// @note Groups lets you reduce the amount of parameters and computations used in the kernel. Given
/// the connectivity pattern, the number of parameters is reduced by a factor of \c groups compared
/// to the default value of 1.
@property (readonly, nonatomic) NSUInteger groups;

@end

/// Protocol implemented by kernels operating on a single input tensor in a neural network.
@protocol PNKUnaryNeuralKernel <PNKNeuralKernel>

/// Calculates the output size of this kernel given \c inputSize;
- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputTexture as
/// input. Output is written asynchronously to \c outputTexture.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

@end

/// Protocol implemented by kernels operating on a two input tensors in a neural network.
@protocol PNKBinaryNeuralKernel <PNKNeuralKernel>

/// Calculates the output size of this kernel given \c primaryInputSize and \c secondaryInputSize;
- (MTLSize)outputSizeForPrimaryInputSize:(MTLSize)primaryInputSize
                   forSecondaryInputSize:(MTLSize)secondaryInputSize;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputTexture
/// and \c secondaryInputTexture as input. Output is written asynchronously to \c outputTexture.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
          primaryInputTexture:(id<MTLTexture>)primaryInputTexture
        secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

@end

NS_ASSUME_NONNULL_END
