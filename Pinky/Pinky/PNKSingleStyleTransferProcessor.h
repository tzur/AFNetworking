// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Processor for NPR by transferring of a single predetermined style onto any other image.
///
/// @note This processor uses the GPU and can only be used on device. Trying to initialize it on a
/// simulator will return \c nil.
///
/// @note This processor creates multiple buffers for its process and is meant to be used by
/// continuously calling \c stylizeWithInput: without reinitialization of a new processor at each
/// call.
///
/// @important The processor is NOT thread safe and synchronization of the calls to
/// \c stylizeWithInput: are left to the user of this class.
@interface PNKSingleStyleTransferProcessor : NSObject

/// Initializes the processor with a URL to the model file describing the specific style. Returns
/// \c nil in case it cannot load the model from \c modelURL or when initialized on a simulator.
- (nullable instancetype)initWithModel:(NSURL *)modelURL error:(NSError **)error
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Apply the style transfer to \c input.
///
/// @param input a pixel buffer of a supported type. Supported pixel buffers formats currently
/// include <tt>kCVPixelFormatType_OneComponent8, kCVPixelFormatType_32BGRA,
/// kCVPixelFormatType_OneComponent16Half and kCVPixelFormatType_64RGBAHalf</tt>. \c input should
/// be Metal compatible (IOSurface backed).
///
/// @return A pixel buffer with a stylized version of \c input. The buffer has a size of
/// \c stylizedOutputSize and \c kCVPixelFormatType_32BGRA pixel format.
- (lt::Ref<CVPixelBufferRef>)stylizeWithInput:(CVPixelBufferRef)input;

/// Size of the images returned when calling \c stylizeWithInput:.
@property (readonly, nonatomic) CGSize stylizedOutputSize;

@end

NS_ASSUME_NONNULL_END
