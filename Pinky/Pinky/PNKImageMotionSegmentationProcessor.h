// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Processor for creating a multi-layer segmentation map of an image.
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
/// \c segmentWithInput:output: are left to the user of this class.
API_AVAILABLE(ios(10.0))
@interface PNKImageMotionSegmentationProcessor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the processor with a URL to the network model file. Returns \c nil in case it cannot
/// load the network model from \c networkModelURL, when initialized on a simulator or an
/// unsupported GPU.
- (nullable instancetype)initWithNetworkModel:(NSURL *)networkModelURL
                                        error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/// Create a multi-layer segmentation map of \c input.
///
/// @param input a pixel buffer of a supported type. Supported pixel formats include
/// \c kCVPixelFormatType_32BGRA and kCVPixelFormatType_64RGBAHalf. \c input should be Metal
/// compatible (IOSurface backed).
///
/// @param output a pixel buffer with a single channel and a supported type. Supported pixel formats
/// include \c kCVPixelFormatType_OneComponent8 and \c kCVPixelFormatType_OneComponent16Half.
/// \c output size must equal the \c input size. \c output should be Metal compatible (IOSurface
/// backed).
-(void)segmentWithInput:(CVPixelBufferRef)input output:(CVPixelBufferRef)output;

@end

NS_ASSUME_NONNULL_END
