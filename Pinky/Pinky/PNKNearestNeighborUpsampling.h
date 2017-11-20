// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Kernel that preforms a nearest neighbor upsampling operation on the input.
@interface PNKNearestNeighborUpsampling : NSObject <PNKUnaryImageKernel>

/// Initializes a new kernel that runs on \c device and magnifies its input by a factor of
/// \c magnificationFactor in both width and height. Depth is unchanged.
///
/// \c magnificationFactor must be greater than 1.
- (instancetype)initWithDevice:(id<MTLDevice>)device
          inputFeatureChannels:(NSUInteger)inputFeatureChannels
           magnificationFactor:(NSUInteger)magnificationFactor NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputTexture as
/// input. Output is written asynchronously to \c outputTexture. \c inputTexture.arrayLength must be
/// equal to \c outputTexture.arrayLength. \c outputTexture.width must be equal to
/// \c inputTexture.width multiplied by \c magnificationFactor. \c outputTexture.height must be
/// equal to \c inputTexture.height multiplied by \c magnificationFactor.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 inputTexture:(id<MTLTexture>)inputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage. \c inputImage.arrayLength must be equal to
/// \c outputImage.arrayLength. \c outputImage.width must be equal to \c inputImage.width multiplied
/// by \c magnificationFactor. \c outputImage.height must be equal to \c inputImage.height
/// multiplied by \c magnificationFactor.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage;

/// Magnification to apply.
@property (readonly, nonatomic) NSUInteger magnificationFactor;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
