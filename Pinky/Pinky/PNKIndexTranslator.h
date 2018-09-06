// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

/// Kernel that translates each pixel value of the input image into another value according to a
/// translation table. The input pixel values are converted to the \c uchar type (with scaling for
/// floating-point channel formats and clamping to the \c [0, 255] range for all formats). The
/// converted values are translated using a user-provided translation table of 256 entries.
API_AVAILABLE(ios(10.0))
@interface PNKIndexTranslator : NSObject <PNKUnaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new kernel that runs on \c device and translates pixel values according to
/// \c translationTable. \c translationTable must have exactly \c 256 entries that cover all \c 256
/// values of \c uchar.
- (instancetype)initWithDevice:(id<MTLDevice>)device
              translationTable:(const std::array<uchar, 256> &)translationTable
    NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as input.
/// Output is written asynchronously to \c outputImage. \c inputImage and \c outputImage must have
/// the same width and height. Both \c inputImage and \c outputImage must have a single feature
/// channel.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage
                  outputImage:(MPSImage *)outputImage;

@end

NS_ASSUME_NONNULL_END
