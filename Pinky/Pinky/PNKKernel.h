// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Protocol implemented by kernels operating on a single input texture.
@protocol PNKUnaryKernel <NSObject>

/// Calculates the output size of this kernel given \c inputSize;
- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputTexture as
/// input. Output is written asynchronously to \c outputTexture.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

@end

/// Protocol implemented by kernels operating on two input textures.
@protocol PNKBinaryKernel <NSObject>

/// Calculates the output size of this kernel given \c primaryInputSize and \c secondaryInputSize.
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
