// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Processor for upsampling of images created by an NPR style transfer processor to the resolution
/// of the original image.
///
/// @note This processor uses the GPU and can only be used on device. Trying to initialize it on a
/// simulator will return \c nil.
///
/// @important The processor is NOT thread safe and synchronization of the calls to
/// \c upsampleStylizedImage:withGuide:output: are left to the user of this class.
@interface PNKStyleUpsampleProcessor : NSObject

/// Initializes the processor with a URL to the model file describing the parameters of the specific
/// style. Returns \c nil in case it cannot load the model from \c modelURL or when initialized
/// on a simulator.
- (nullable instancetype)initWithModel:(NSURL *)modelURL error:(NSError **)error
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Upsample the stylized \c image to be the same size as \c guide. Upsampling method and parameters
/// are specific to the style model given to the initializer. Using this processor to downsample
/// will result in a simple bilinear interpolation.
///
/// @param image A stylized image returned from the NPR processor using the same model given to the
/// initializer. This buffer must have \c kCVPixelFormatType_32BGRA pixel format.
///
/// @param guide The guide for upsampling \c image. Should be the original input image used to
/// create \c image to achieve the intended behavior, but can be any guiding image for other
/// effects. The pixel format of this buffer must be one of <tt>kCVPixelFormatType_OneComponent8,
/// kCVPixelFormatType_32BGRA, kCVPixelFormatType_OneComponent16Half and
/// kCVPixelFormatType_64RGBAHalf</tt>.
///
/// @param output A pixel buffer to write the upsampled result into. The pixel buffer must be the
/// same size as \c guide and \c kCVPixelFormatType_32BGRA pixel format.
- (void)upsampleStylizedImage:(CVPixelBufferRef)image withGuide:(CVPixelBufferRef)guide
                       output:(CVPixelBufferRef)output;

@end

NS_ASSUME_NONNULL_END
