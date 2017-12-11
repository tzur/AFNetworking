// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNeuralNetwork.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

namespace pnk {
  struct NeuralNetworkModel;
}

/// Network for segmentation of skies. The output of this network is an image, the same size as the
/// input, and has 2 channels. The first channel represents the confidence in the segmentation of
/// skies in the image such that pixels included in the sky get a high value and pixels in other
/// classes, i.e. the background, get a low value. The second channel represents the confidence of
/// all classes that are not sky and are called "background". The architecture of this network is a
/// proprietary one composed of a downsampling stage encoding the image while downsampling it twice
/// in a dyadic manner. Then the created tensor is encoded in 5 residual blocks with dilated
/// convolution for enlarged receptive fields. The tensor is then upsampled and concatenated with
/// tensors from the downsampling stage via skip connections. Finally the last tensor passes through
/// a pixel-wise convolution to create the confidence maps per class.
@interface PNKSkySegmentationNetwork : NSObject <PNKNeuralNetwork>

/// Initializes a new network that runs on \c device and performs segmentation of skies in images.
/// The parameters of the network are described by \c networkModel and the shape model used as input
/// for the network is represented by \c shapeModel. \c shapeModel is deep copied by the instance.
- (nullable instancetype)initWithDevice:(id<MTLDevice>)device
                           networkModel:(const pnk::NeuralNetworkModel &)networkModel
                             shapeModel:(const cv::Mat1hf &)shapeModel NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Encodes the entire set of operations performed by the neural network onto \c buffer.
/// \c inputImage must have 3 channels of either RGB or YYY representation of the image to segment.
/// \c outputImage must have 2 channels and the same size as \c inputImage. The first channel of the
/// input is the segmentation map of skies and the second channel is the segmentation map of the
/// background.
- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)buffer inputImage:(MPSImage *)inputImage
                    outputImage:(MPSImage *)outputImage;

/// Encodes the entire set of operations performed by the neural network onto a single commandBuffer
/// derived from \c queue. \c inputImage must have 3 channels of either RGB or YYY representation of
/// the image to segment. \c outputImage must have 2 channels and the same size as \c inputImage.
/// The first channel of the input is the segmentation map of skies and the second channel is the
/// segmentation map of the background. This method returns immediately and \c completion is called
/// on an arbitrary queue once all operations have completed. \c completion is called on a thread
/// managed by Metal by using the \c addCompletedHandler: method of \c MTLCommandBuffer.
- (void)encodeAndCommitAsyncWithCommandQueue:(id<MTLCommandQueue>)queue
                                  inputImage:(MPSImage *)inputImage
                                 outputImage:(MPSImage *)outputImage
                                  completion:(LTCompletionBlock)completion;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
