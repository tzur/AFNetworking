// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Processor for creating a mask of sky areas in an image.
///
/// @note This processor uses the GPU and can only be used on device. Trying to initialize it on a
/// simulator will return \c nil.
///
/// @note Works on GPU Family 2 and up.
///
/// @note This processor creates multiple buffers for its process and is meant to be used by
/// continuously calling \c segmentWithInput:output:completion: without reinitialization of a new
/// processor at each call. Consecutive calls with similar sized inputs result in faster rendering.
///
/// @important The processor is NOT thread safe and synchronization of the calls to
/// \c segmentWithInput:output:completion: are left to the user of this class.
@interface PNKSuperSkySegmentationProcessor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the processor with a URL to the network model file. Returns \c nil in case it cannot
/// load the network model from \c networkModelURL, when initialized on a simulator or an
/// unsupported GPU.
- (nullable instancetype)initWithNetworkModel:(NSURL *)networkModelURL
                                        error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/// Create a segmentation mask corresponding to skies in \c input.
///
/// @param input a pixel buffer of a supported type. Supported pixel formats include
/// <tt>kCVPixelFormatType_OneComponent8, kCVPixelFormatType_32BGRA,
/// kCVPixelFormatType_OneComponent16Half and kCVPixelFormatType_64RGBAHalf</tt>. \c input should
/// be Metal compatible (IOSurface backed).
///
/// @param output a pixel buffer with a single channel and a supported type. Supported pixel formats
/// include <tt>kCVPixelFormatType_OneComponent8 and kCVPixelFormatType_OneComponent16Half</tt>.
/// \c output size must be exactly the size returned when calling \c outputSizeWithInputSize: with
/// \c input. \c output should be Metal compatible (IOSurface backed).
///
/// @param completion a block called on an arbitrary queue when the rendering to \c output is
/// completed. Note that writing to \c input or reading from \c output prior to \c completion being
/// called will lead to undefined behaviour.
- (void)segmentWithInput:(CVPixelBufferRef)input output:(CVPixelBufferRef)output
              completion:(LTCompletionBlock)completion;

/// Returns the output buffer size for an input of size \c size when calling
/// \c segmentWithInput:output:completion:.
- (CGSize)outputSizeWithInputSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
