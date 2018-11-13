// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Processor for image inpainting.
///
/// @note This processor can only be used on GPU Generation 3 and up. Trying to initialize it on a
/// simulator or on GPU Generation 1 or 2 will return \c nil.
///
/// @note This processor creates multiple buffers for its process and is meant to be used by
/// repeatedly calling \c inpaintWithInput:mask:output:completion: without reinitialization of a new
/// processor at each call.
@interface PNKInpaintingProcessor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the processor with a URL to the model file. Returns \c nil in case it cannot load
/// the model from \c modelURL or when initialized on a simulator.
- (nullable instancetype)initWithNetworkModel:(NSURL *)modelURL error:(NSError **)error
    NS_DESIGNATED_INITIALIZER;

/// Inpaints an \c input area corresponding to non-zero values of \c mask while storing the result
/// in \c output. The operation is performed asynchronously; \c completion is called on its
/// completion.
///
/// @param input a pixel buffer of a supported type. Supported pixel formats include
/// <tt>kCVPixelFormatType_OneComponent8, kCVPixelFormatType_32BGRA,
/// kCVPixelFormatType_OneComponent16Half and kCVPixelFormatType_64RGBAHalf</tt>. \c input should
/// be Metal compatible (IOSurface backed).
///
/// @param mask a single-channel pixel buffer of a supported type. Supported pixel formats include
/// \c kCVPixelFormatType_OneComponent8 and \c kCVPixelFormatType_OneComponent16Half. \c mask must
/// have the same size as \c input. \c mask must be Metal compatible (IOSurface backed). \c mask
/// must contain at least one non-zero pixel.
///
/// @param output a pixel buffer of the same type and size as \c input. \c output must be Metal
/// compatible (IOSurface backed).
///
/// @param completion a block called on an arbitrary queue when the rendering to \c output is
/// completed. Note that writing to \c input or \c mask as well as reading from \c output prior to
/// \c completion being called will lead to undefined behaviour.
- (void)inpaintWithInput:(CVPixelBufferRef)input mask:(CVPixelBufferRef)mask
                  output:(CVPixelBufferRef)output
              completion:(LTCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
