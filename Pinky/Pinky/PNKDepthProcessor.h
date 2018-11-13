// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Processor for extracting depth map from a single input image.
///
/// @note This processor can only be used on GPU Generation 3 and up (on GPU Generation 2 running
/// this processor would take unreasonable time of more than 10 seconds while GPU Generation 1 does
/// not support MPS framework). Trying to initialize this processor on a simulator or on an
/// unsupported GPU will return \c nil.
@interface PNKDepthProcessor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the processor with a URL to the model file. Returns \c nil in case it cannot load
/// the model from \c modelURL, when initialized on a simulator or on GPU Generation 1 or 2.
- (nullable instancetype)initWithNetworkModel:(NSURL *)modelURL error:(NSError **)error
    NS_DESIGNATED_INITIALIZER;

/// Extracts depth map from \c input while storing the result in \c output. The operation is
/// performed asynchronously; \c completion is called on its completion.
///
/// @param input a pixel buffer of a supported type. Supported pixel formats include
/// <tt>kCVPixelFormatType_OneComponent8, kCVPixelFormatType_32BGRA,
/// kCVPixelFormatType_OneComponent16Half and kCVPixelFormatType_64RGBAHalf</tt>. \c input should
/// be Metal compatible (IOSurface backed).
///
/// @param output a pixel buffer with a single channel and a supported type. Supported pixel formats
/// include <tt>kCVPixelFormatType_OneComponent8 and kCVPixelFormatType_OneComponent16Half</tt>.
/// \c output size must be exactly the size returned when calling \c outputSizeWithInputSize: with
/// \c input. \c output should be Metal compatible (IOSurface backed). The resulting depth is
/// normalized to the [0, 1] range for half-float float \c output or to the [0, 255] range for byte
/// \c output resulting in relative depth scale.
///
/// @param completion a block called on an arbitrary queue when the rendering to \c output is
/// completed. Note that writing to \c input or \c mask as well as reading from \c output prior to
/// \c completion being called will lead to undefined behaviour.
- (void)extractDepthWithInput:(CVPixelBufferRef)input output:(CVPixelBufferRef)output
                   completion:(LTCompletionBlock)completion;

/// Returns the output buffer size for an input of size \c size when calling
/// \c segmentWithInput:output:completion:.
- (CGSize)outputSizeWithInputSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
