// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKKernel.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Kernel performing an instance normalization operation.
@interface PNKInstanceNormInternalKernel : NSObject <PNKUnaryKernel>

/// Initializes a new kernel that runs on \c device and performs an instance normalization
/// operation. The kernel expects to work on images with \c featureChannels channels and apply an
/// activation function described by \c activationType. The kernel normalization parameters are
/// initialized such that the scale is 1 and shift is 0 for all channels. Parametric activation
/// functions such as \c pnk::ActivationTypeLeakyReLU and \c pnk::ActivationTypePReLU are
/// initialized to perform a simple ReLU activation. All these parameters can be set via their
/// respective setters.
- (instancetype)initWithDevice:(id<MTLDevice>)device
               featureChannels:(NSUInteger)featureChannels
                activationType:(pnk::ActivationType)activationType NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as
/// input. Output is written asynchronously to \c outputImage. \c outputImage must be the same size
/// and number of channels as \c inputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage;

/// Set the parameters used for scaling in the normalization operation. The \c parameters vector
/// must have exactly \c featureChannels elements.
- (void)setScaleParameters:(const cv::Mat &)parameters;

/// Set the parameters used for shifting in the normalization operation. The \c parameters vector
/// must have exactly \c featureChannels elements.
- (void)setShiftParameters:(const cv::Mat &)parameters;

/// Set the parameters used for PReLU activation in the normalization operation. The \c parameters
/// vector must have exactly \c featureChannels elements.
///
/// @throws In case that \c activationType used in initialization is not one of
/// \c pnk::ActivationTypeLeakyReLU or \c pnk::ActivationTypePReLU.
- (void)setPReluParameters:(const cv::Mat &)parameters;

/// Number of feature channels per pixel in the input and output images of this kernel.
@property (readonly, nonatomic) NSUInteger featureChannels;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
