// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Kernel that does channel-wise concatenation of textures.
@interface PNKConcatenation : NSObject <PNKBinaryImageKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and concatenates images/textures.
- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputImage
/// and \c secondaryInputImage as input. Output is written asynchronously to \c outputImage.
/// Primary input, secondary input and output images must have the same width and height. The
/// \c featureChannels properties of primary and secondary input image must fit the respective
/// values provided on kernel initializion. The \c featureChannels property of output image must
/// equal the sum of the aforementioned values.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage
                  outputImage:(MPSImage *)outputImage;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c primaryInputTexture
/// and \c secondaryInputTexture as input. Output is written asynchronously to \c outputTexture.
/// Primary input, secondary input and output textures must have the same width and height. The
/// \c arrayLength of \c primaryInputTexture must equal
/// <tt>ceil(primaryInputFeatureChannels/4)</tt>. The \c arrayLength of \c secondaryInputTexture
/// must equal <tt>ceil(secondaryInputFeatureChannel/4)</tt>. The \c arrayLength of \c outputTexture
/// must equal <tt>ceil((primaryInputFeatureChannels + secondaryInputFeatureChannels)/4)</tt>.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
          primaryInputTexture:(id<MTLTexture>)primaryInputTexture
        secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                outputTexture:(id<MTLTexture>)outputTexture;

/// Determines the maximal number of channels that may be read from the primary input. The actual
/// primary input region is determined by the primary input given to the encode method.
- (MTLRegion)primaryInputRegionForOutputSize:(MTLSize)outputSize;

/// Determines the maximal number of channels that may be read from the secondary input. The actual
/// secondary input region is determined by the primary input given to the encode method.
- (MTLRegion)secondaryInputRegionForOutputSize:(MTLSize)outputSize;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
