// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

namespace pnk {
  struct NeuralNetworkModel;
}

/// Network for style transfer onto an image. The output of this network is an image, the same size
/// and number of channels as the input. The architecture of this network is of an autoencoder with
/// two downsampling stages and two upsampling stages with 3 or 5 residual blocks in between.
API_AVAILABLE(ios(10.0))
@interface PNKStyleTransferNetwork : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new network that runs on \c device and performs stylization. The parameters of the
/// network are described by \c networkModel.
- (instancetype)initWithDevice:(id<MTLDevice>)device
                         model:(const pnk::NeuralNetworkModel &)networkModel
    NS_DESIGNATED_INITIALIZER;

/// Encodes the entire set of operations performed by the neural network onto \c buffer.
/// \c inputImage must have the number of channels stated in \c inputChannels or more.
/// \c outputImage must have the number of channels stated in \c outputChannels.
/// \c styleIndex must be in the range <tt>[0, stylesCount)</tt>.
- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)buffer inputImage:(MPSImage *)inputImage
                    outputImage:(MPSImage *)outputImage styleIndex:(NSUInteger)styleIndex;

/// Number of styles applicable in this network.
@property (readonly, nonatomic) NSUInteger stylesCount;

/// Number of channels expected in the input of this network.
@property (readonly, nonatomic) NSUInteger inputChannels;

/// Number of channels expected in the output of this network.
@property (readonly, nonatomic) NSUInteger outputChannels;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
