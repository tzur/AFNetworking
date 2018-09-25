// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

@class PNKStyleTransferState;

/// Processor for Non Photorealistic Rendering (NPR) by transferring pre-learnt styles onto any
/// other image.
///
/// @note This processor uses the GPU and can only be used on device. Trying to initialize it on a
/// simulator will return \c nil.
///
/// @note This processor creates multiple buffers for its process and is meant to be used by
/// repeatedly calling \c stylizeWithInput:styleWeights: without reinitialization of a new
/// processor at each call.
///
/// @important The processor is NOT thread safe and synchronization of the calls to
/// \c stylizeWithInput:styleWeights: are left to the user of this class.
@interface PNKStyleTransferProcessor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the processor with a URL to the model file describing the specific style. Returns
/// \c nil in case it cannot load the model from \c modelURL or when initialized on a simulator.
- (nullable instancetype)initWithModel:(NSURL *)modelURL error:(NSError **)error
    NS_DESIGNATED_INITIALIZER;

/// Returns a \c state that can later be used by \c stylizeWithState:output:styleIndex:completion:.
typedef void (^PNKStyleTransferCompletionBlock)(PNKStyleTransferState *state);

/// Apply onto \c input the style corresponding to \c styleIndex.
///
/// @param input a pixel buffer of a supported type. Supported pixel formats include
/// <tt>kCVPixelFormatType_OneComponent8, kCVPixelFormatType_32BGRA,
/// kCVPixelFormatType_OneComponent16Half and kCVPixelFormatType_64RGBAHalf</tt>. \c input should
/// be Metal compatible (IOSurface backed).
///
/// @param output a pixel buffer with the number of channels stated by \c stylizedOutputChannels and
/// a supported type. Supported pixel formats for single channel include
/// \c kCVPixelFormatType_OneComponent8 and \c kCVPixelFormatType_OneComponent16Half. Supported
/// pixel formats for 4 channels are \c kCVPixelFormatType_32BGRA and
/// \c kCVPixelFormatType_64RGBAHalf. \c output size must be exactly the size returned when calling
/// \c outputSizeWithInputSize: with the size of \c input. \c output should be Metal compatible
/// (IOSurface backed).
///
/// @param completion a block called on an arbitrary queue when the rendering to \c output is
/// completed. Note that writing to \c input or reading from \c output prior to \c completion being
/// called will lead to undefined behaviour. The block passes an opaque object that holds the state
/// of the processor for the \c input given to this call. Using this state via
/// \c stylizeWithState:output:styleIndex:completion: can reduce the computation time required to
/// perform the stylization. The state might hold GPU resources but can be disposed of on any queue.
///
/// @important calling this method runs the full processing pipeline of this processor. For the
/// possibility of shorter run times it is best to use the stateful interface via
/// \c stylizeWithState:output:styleIndex:completion:.
- (void)stylizeWithInput:(CVPixelBufferRef)input output:(CVPixelBufferRef)output
              styleIndex:(NSUInteger)styleIndex
              completion:(PNKStyleTransferCompletionBlock)completion;

/// Apply onto the input image that was used to create \c state the style corresponding to
/// \c styleIndex.
///
/// @param state a state that holds all necessary information for stylization regarding the input
/// image used to create it.
///
/// @param output a pixel buffer with the number of channels stated by \c stylizedOutputChannels and
/// a supported type. Supported pixel formats for single channel include
/// \c kCVPixelFormatType_OneComponent8 and \c kCVPixelFormatType_OneComponent16Half. Supported
/// pixel formats for 4 channels are \c kCVPixelFormatType_32BGRA and
/// \c kCVPixelFormatType_64RGBAHalf. \c output size must be exactly the size returned when calling
/// \c outputSizeWithInputSize: with the size of the image used to create \c state. \c output should
/// be Metal compatible (IOSurface backed).
///
/// @param completion a block called on an arbitrary queue when the rendering to \c output is
/// completed. Note that reading from \c output prior to \c completion being called will lead to
/// undefined behaviour.
- (void)stylizeWithState:(PNKStyleTransferState *)state output:(CVPixelBufferRef)output
              styleIndex:(NSUInteger)styleIndex completion:(LTCompletionBlock)completion;

/// Returns the output buffer size for an input of size \c size when calling
/// \c stylizeWithInput:output:completion:.
- (CGSize)outputSizeWithInputSize:(CGSize)size;

/// Maximal size of the small side of the images returned when calling \c stylizeWithInput:. Default
/// value is \c 1024.
@property (nonatomic) NSUInteger stylizedOutputSmallSide;

/// Maximal size of the large side of the images returned when calling \c stylizeWithInput:. Default
/// value is \c 3072.
@property (nonatomic) NSUInteger stylizedOutputLargeSide;

/// Number of channels for the stylized image. One of <tt>{1, 4}</tt>.
@property (readonly, nonatomic) NSUInteger stylizedOutputChannels;

/// Number of styles supported by this class.
@property (readonly, nonatomic) NSUInteger stylesCount;

@end

NS_ASSUME_NONNULL_END
