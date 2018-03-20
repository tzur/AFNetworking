// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKSkySegmentationNetwork.h"

#import "MPSImage+Factory.h"
#import "MPSTemporaryImage+Factory.h"
#import "PNKArithmetic.h"
#import "PNKConcatenation.h"
#import "PNKConvolutionLayer.h"
#import "PNKNeuralNetworkModel.h"
#import "PNKOpenCVExtensions.h"
#import "PNKPoolingLayer.h"
#import "PNKUpsampling.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKSkySegmentationNetwork ()

/// Device to encode the operations of this network.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Shape model used in this network as a secondary input.
@property (readonly, nonatomic) cv::Mat1hf averageSkyInput;

/// Serial queue used to encode and commit the operations of the network when
/// \c encodeAndCommitAsyncWithCommandQueue:inputImage:outputImage:completion: is called.
@property (readonly, nonatomic) dispatch_queue_t dispatchQueue;

/// Concatenenation layer turning the input image and shape model into a single 4 channel tensor.
/// output of this layer is used as input for \c conv1 and \c concat3.
@property (readonly, nonatomic) PNKConcatenation *concat1;

/// Convolution layer in downsample stage. Output of this layer is used as input for \c maxpool1.
@property (readonly, nonatomic) PNKConvolutionLayer *conv1;

/// Max pooling layer with a dyadic downsample. Output of this layer is used as input for \c conv2
/// and \c concat2.
@property (readonly, nonatomic) PNKPoolingLayer *maxpool1;

/// Convolution layer in downsample stage. Output of this layer is used as input for \c maxpool2.
@property (readonly, nonatomic) PNKConvolutionLayer *conv2;

/// Max pooling layer with a dyadic downsample. Output of this layer is used as input for
/// \c resconv1 and \c add1.
@property (readonly, nonatomic) PNKPoolingLayer *maxpool2;

/// Convolution layer in residual stage. Output of this layer is used as input for \c dilated1.
@property (readonly, nonatomic) PNKConvolutionLayer *resconv1;

/// Dialated convolution layer in residual stage. Output of this layer is used as input for \c add1.
@property (readonly, nonatomic) PNKConvolutionLayer *dilated1;

/// Addition layer in residual stage. Output of this layer is used as input for \c resconv2 and
/// \c add2.
@property (readonly, nonatomic) PNKArithmetic *add1;

/// Convolution layer in residual stage. Output of this layer is used as input for \c dilated2.
@property (readonly, nonatomic) PNKConvolutionLayer *resconv2;

/// Dialated convolution layer in residual stage. Output of this layer is used as input for \c add2.
@property (readonly, nonatomic) PNKConvolutionLayer *dilated2;

/// Addition layer in residual stage. Output of this layer is used as input for \c resconv3 and
/// \c add3.
@property (readonly, nonatomic) PNKArithmetic *add2;

/// Convolution layer in residual stage. Output of this layer is used as input for \c dilated3.
@property (readonly, nonatomic) PNKConvolutionLayer *resconv3;

/// Dialated convolution layer in residual stage. Output of this layer is used as input for \c add3.
@property (readonly, nonatomic) PNKConvolutionLayer *dilated3;

/// Addition layer in residual stage. Output of this layer is used as input for \c resconv4 and
/// \c add4.
@property (readonly, nonatomic) PNKArithmetic *add3;

/// Convolution layer in residual stage. Output of this layer is used as input for \c dilated4.
@property (readonly, nonatomic) PNKConvolutionLayer *resconv4;

/// Dialated convolution layer in residual stage. Output of this layer is used as input for \c add4.
@property (readonly, nonatomic) PNKConvolutionLayer *dilated4;

/// Addition layer in residual stage. Output of this layer is used as input for \c resconv5 and
/// \c add5.
@property (readonly, nonatomic) PNKArithmetic *add4;

/// Convolution layer in residual stage. Output of this layer is used as input for \c dilated5.
@property (readonly, nonatomic) PNKConvolutionLayer *resconv5;

/// Dialated convolution layer in residual stage. Output of this layer is used as input for \c add5.
@property (readonly, nonatomic) PNKConvolutionLayer *dilated5;

/// Addition layer in residual stage. Output of this layer is used as input for \c upsample1.
@property (readonly, nonatomic) PNKArithmetic *add5;

/// Nearest neighbor dyadic upsampling. Output of this layer is used as input for \c uconv1.
@property (readonly, nonatomic) PNKUpsampling *upsample1;

/// Convolution layer in upsampling stage. Output of this layer is used as input for \c concat2.
@property (readonly, nonatomic) PNKConvolutionLayer *uconv1;

/// Concatenenation layer with a skip connection from the output of \c maxpool1. Output of this
/// layer is used as input for \c upsample2.
@property (readonly, nonatomic) PNKConcatenation *concat2;

/// Nearest neighbor dyadic upsampling. Output of this layer is used as input for \c uconv2.
@property (readonly, nonatomic) PNKUpsampling *upsample2;

/// Convolution layer in upsampling stage. Output of this layer is used as input for \c concat3.
@property (readonly, nonatomic) PNKConvolutionLayer *uconv2;

/// Concatenenation layer with a skip connection from the input of the network. Output of this layer
/// is used as input for \c convfc.
@property (readonly, nonatomic) PNKConcatenation *concat3;

/// Pixel-wise convolution. Output of this layer is the segmentation output of the network.
@property (readonly, nonatomic) PNKConvolutionLayer *convfc;

@end

@implementation PNKSkySegmentationNetwork

- (nullable instancetype)initWithDevice:(id<MTLDevice>)device
                           networkModel:(const pnk::NeuralNetworkModel &)networkModel
                             shapeModel:(const cv::Mat1hf &)shapeModel {
  if (self = [super init]) {
    _device = device;
    _averageSkyInput = shapeModel.clone();

    [self buildNetworkWithModel:networkModel];
    _dispatchQueue = dispatch_queue_create("com.lightricks.Pinky.SkyNetwork",
                                           DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)buildNetworkWithModel:(const pnk::NeuralNetworkModel &)model {
  _concat1 = [[PNKConcatenation alloc] initWithDevice:self.device];
  // Downsample.
  _conv1 = [[PNKConvolutionLayer alloc]
            initWithDevice:self.device
            convolutionModel:model.convolutionKernels.at("conv1")
            activationModel:model.activationKernels.at("conv1__activation__")];
  _maxpool1 = [[PNKPoolingLayer alloc] initWithDevice:self.device
                                         poolingModel:model.poolingKernels.at("maxpool1")];
  _conv2 = [[PNKConvolutionLayer alloc]
            initWithDevice:self.device
            convolutionModel:model.convolutionKernels.at("conv2")
            activationModel:model.activationKernels.at("conv2__activation__")];
  _maxpool2 = [[PNKPoolingLayer alloc] initWithDevice:self.device
                                         poolingModel:model.poolingKernels.at("maxpool2")];
  // Residual Blocks.
  _resconv1 = [[PNKConvolutionLayer alloc]
               initWithDevice:self.device
               convolutionModel:model.convolutionKernels.at("resconv1")
               activationModel:model.activationKernels.at("resconv1__activation__")];
  _dilated1 = [[PNKConvolutionLayer alloc]
               initWithDevice:self.device
               convolutionModel:model.convolutionKernels.at("dilated1")
               activationModel:model.activationKernels.at("dilated1__activation__")];
  _add1 = [[PNKArithmetic alloc] initWithDevice:self.device
                                      operation:pnk::ArithmeticOperationAddition];
  _resconv2 = [[PNKConvolutionLayer alloc]
               initWithDevice:self.device
               convolutionModel:model.convolutionKernels.at("resconv2")
               activationModel:model.activationKernels.at("resconv2__activation__")];
  _dilated2 = [[PNKConvolutionLayer alloc]
               initWithDevice:self.device
               convolutionModel:model.convolutionKernels.at("dilated2")
               activationModel:model.activationKernels.at("dilated2__activation__")];
  _add2 = [[PNKArithmetic alloc] initWithDevice:self.device
                                      operation:pnk::ArithmeticOperationAddition];
  _resconv3 = [[PNKConvolutionLayer alloc]
               initWithDevice:self.device
               convolutionModel:model.convolutionKernels.at("resconv3")
               activationModel:model.activationKernels.at("resconv3__activation__")];
  _dilated3 = [[PNKConvolutionLayer alloc]
               initWithDevice:self.device
               convolutionModel:model.convolutionKernels.at("dilated3")
               activationModel:model.activationKernels.at("dilated3__activation__")];
  _add3 = [[PNKArithmetic alloc] initWithDevice:self.device
                                      operation:pnk::ArithmeticOperationAddition];
  _resconv4 = [[PNKConvolutionLayer alloc]
               initWithDevice:self.device
               convolutionModel:model.convolutionKernels.at("resconv4")
               activationModel:model.activationKernels.at("resconv4__activation__")];
  _dilated4 = [[PNKConvolutionLayer alloc]
               initWithDevice:self.device
               convolutionModel:model.convolutionKernels.at("dilated4")
               activationModel:model.activationKernels.at("dilated4__activation__")];
  _add4 = [[PNKArithmetic alloc] initWithDevice:self.device
                                      operation:pnk::ArithmeticOperationAddition];
  _resconv5 = [[PNKConvolutionLayer alloc]
               initWithDevice:self.device
               convolutionModel:model.convolutionKernels.at("resconv5")
               activationModel:model.activationKernels.at("resconv5__activation__")];
  _dilated5 = [[PNKConvolutionLayer alloc]
               initWithDevice:self.device
               convolutionModel:model.convolutionKernels.at("dilated5")
               activationModel:model.activationKernels.at("dilated5__activation__")];
  _add5 = [[PNKArithmetic alloc] initWithDevice:self.device
                                      operation:pnk::ArithmeticOperationAddition];
  // Upsample.
  _upsample1 = [[PNKUpsampling alloc] initWithDevice:self.device
                                      upsamplingType:PNKUpsamplingTypeNearestNeighbor];
  _uconv1 = [[PNKConvolutionLayer alloc]
             initWithDevice:self.device
             convolutionModel:model.convolutionKernels.at("uconv1")
             activationModel:model.activationKernels.at("uconv1__activation__")];
  _concat2 = [[PNKConcatenation alloc] initWithDevice:self.device];
  _upsample2 = [[PNKUpsampling alloc] initWithDevice:self.device
                                      upsamplingType:PNKUpsamplingTypeNearestNeighbor];
  _uconv2 = [[PNKConvolutionLayer alloc]
             initWithDevice:self.device
             convolutionModel:model.convolutionKernels.at("uconv2")
             activationModel:model.activationKernels.at("uconv2__activation__")];
  _concat3 = [[PNKConcatenation alloc] initWithDevice:self.device];
  // Segment.
  _convfc = [[PNKConvolutionLayer alloc]
              initWithDevice:self.device
              convolutionModel:model.convolutionKernels.at("conv_fc")
              activationModel:model.activationKernels.at("conv_fc__activation__")];
}

- (void)verifyInputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.featureChannels == 3, @"Input image must have 3 feature channels, "
                    "got %lu", (unsigned long)inputImage.featureChannels);
  LTParameterAssert(outputImage.featureChannels == 2, @"Output image must have 2 feature channels, "
                    "got %lu", (unsigned long)outputImage.featureChannels);
  LTParameterAssert(inputImage.width == outputImage.width,
                    @"Input image width must match output image width. got: (%lu, %lu)",
                    (unsigned long)inputImage.width, (unsigned long)outputImage.width);
  LTParameterAssert(inputImage.height == outputImage.height,
                    @"Input image height must match output image height. got: (%lu, %lu)",
                    (unsigned long)inputImage.height, (unsigned long)outputImage.height);
}

- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)buffer inputImage:(MPSImage *)inputImage
                    outputImage:(MPSImage *)outputImage {
  [self verifyInputImage:inputImage outputImage:outputImage];

  auto inputConcat = [self encodeConcatShapeModelWithCommandBuffer:buffer
                                                concatenationLayer:self.concat1
                                                        inputImage:inputImage];
  inputConcat.readCount += 1;

  auto down1Output = [self encodePooledConvolutionWithCommandBuffer:buffer
                                                   convolutionLayer:self.conv1
                                                       poolingLayer:self.maxpool1
                                                         inputImage:inputConcat];
  down1Output.readCount += 1;

  auto down2Output = [self encodePooledConvolutionWithCommandBuffer:buffer
                                                   convolutionLayer:self.conv2
                                                       poolingLayer:self.maxpool2
                                                         inputImage:down1Output];

  auto residual1Output = [self encodeResidualBlockWithCommandBuffer:buffer
                                              firstConvolutionLayer:self.resconv1
                                             secondConvolutionLayer:self.dilated1
                                                      additionLayer:self.add1
                                                         inputImage:down2Output];
  auto residual2Output = [self encodeResidualBlockWithCommandBuffer:buffer
                                              firstConvolutionLayer:self.resconv2
                                             secondConvolutionLayer:self.dilated2
                                                      additionLayer:self.add2
                                                         inputImage:residual1Output];
  auto residual3Output = [self encodeResidualBlockWithCommandBuffer:buffer
                                              firstConvolutionLayer:self.resconv3
                                             secondConvolutionLayer:self.dilated3
                                                      additionLayer:self.add3
                                                         inputImage:residual2Output];
  auto residual4Output = [self encodeResidualBlockWithCommandBuffer:buffer
                                              firstConvolutionLayer:self.resconv4
                                             secondConvolutionLayer:self.dilated4
                                                      additionLayer:self.add4
                                                         inputImage:residual3Output];
  auto residual5Output = [self encodeResidualBlockWithCommandBuffer:buffer
                                              firstConvolutionLayer:self.resconv5
                                             secondConvolutionLayer:self.dilated5
                                                      additionLayer:self.add5
                                                         inputImage:residual4Output];

  auto up1Output = [self encodeUpsampleConvolutionWithCommandBuffer:buffer
                                                      upsampleLayer:self.upsample1
                                                   convolutionLayer:self.uconv1
                                                 concatenationLayer:self.concat2
                                                         inputImage:residual5Output
                                                secondaryInputImage:down1Output];

  auto up2Output = [self encodeUpsampleConvolutionWithCommandBuffer:buffer
                                                      upsampleLayer:self.upsample2
                                                   convolutionLayer:self.uconv2
                                                 concatenationLayer:self.concat3
                                                         inputImage:up1Output
                                                secondaryInputImage:inputConcat];

  [self.convfc encodeToCommandBuffer:buffer inputImage:up2Output outputImage:outputImage];
}

- (MPSTemporaryImage *)encodeConcatShapeModelWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                            concatenationLayer:(PNKConcatenation *)concatLayer
                                                    inputImage:(MPSImage *)inputImage {
  cv::Mat1hf resizedShape((int)inputImage.height, (int)inputImage.width);
  cv::resize(self.averageSkyInput, resizedShape, resizedShape.size());

  auto shapeModel = [MPSImage pnk_float16ImageWithDevice:buffer.device width:inputImage.width
                                                  height:inputImage.height channels:1];
  PNKCopyMatToMTLTexture(shapeModel.texture, resizedShape);

  auto output = [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                               width:inputImage.width
                                                              height:inputImage.height
                                                            channels:4];

  [concatLayer encodeToCommandBuffer:buffer primaryInputImage:inputImage
                 secondaryInputImage:shapeModel outputImage:output];
  return output;
}

- (MPSTemporaryImage *)encodeConvolutionWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                         convolutionLayer:(PNKConvolutionLayer *)convLayer
                                               inputImage:(MPSImage *)inputImage {
  auto convOutputWidth = ceil(inputImage.width / convLayer.strideX);
  auto convOutputHeight = ceil(inputImage.height / convLayer.strideY);
  MPSTemporaryImage *convOutput =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:convOutputWidth
                                                    height:convOutputHeight
                                                  channels:convLayer.outputFeatureChannels];
  [convLayer encodeToCommandBuffer:buffer inputImage:inputImage outputImage:convOutput];

  return convOutput;
}

- (MPSTemporaryImage *)encodePooledConvolutionWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                               convolutionLayer:(PNKConvolutionLayer *)convLayer
                                                   poolingLayer:(PNKPoolingLayer *)poolLayer
                                                     inputImage:(MPSTemporaryImage *)inputImage {
  auto convOutput = [self encodeConvolutionWithCommandBuffer:buffer convolutionLayer:convLayer
                                                  inputImage:inputImage];

  auto poolOutputWidth = ceil(convOutput.width / poolLayer.strideX);
  auto poolOutputHeight = ceil(convOutput.height / poolLayer.strideY);
  MPSTemporaryImage *poolOutput =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:poolOutputWidth
                                                    height:poolOutputHeight
                                                  channels:convLayer.outputFeatureChannels];
  [poolLayer encodeToCommandBuffer:buffer inputImage:convOutput outputImage:poolOutput];

  return poolOutput;
}

- (MPSTemporaryImage *)encodeResidualBlockWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                      firstConvolutionLayer:(PNKConvolutionLayer *)firstConvLayer
                                     secondConvolutionLayer:(PNKConvolutionLayer *)secondConvLayer
                                              additionLayer:(PNKArithmetic *)additionLayer
                                                 inputImage:(MPSTemporaryImage *)inputImage {
  inputImage.readCount += 1;

  MPSImage *conv1Output = [self encodeConvolutionWithCommandBuffer:buffer
                                                  convolutionLayer:firstConvLayer
                                                        inputImage:inputImage];

  auto conv2OutputWidth = ceil(conv1Output.width / firstConvLayer.strideX);
  auto conv2OutputHeight = ceil(conv1Output.height / firstConvLayer.strideY);
  MPSTemporaryImage *conv2Output =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:conv2OutputWidth
                                                    height:conv2OutputHeight
                                                  channels:secondConvLayer.outputFeatureChannels];
  [secondConvLayer encodeToCommandBuffer:buffer inputImage:conv1Output outputImage:conv2Output];

  MPSTemporaryImage *addOutput =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:inputImage.width
                                                    height:inputImage.height
                                                  channels:inputImage.featureChannels];
  [additionLayer encodeToCommandBuffer:buffer primaryInputImage:inputImage
                   secondaryInputImage:conv2Output outputImage:addOutput];

  return addOutput;
}

- (MPSTemporaryImage *)encodeUpsampleConvolutionWithCommandBuffer:(id<MTLCommandBuffer>)buffer
    upsampleLayer:(PNKUpsampling *)upLayer
    convolutionLayer:(PNKConvolutionLayer *)convLayer
    concatenationLayer:(PNKConcatenation *)concatLayer
    inputImage:(MPSTemporaryImage *)inputImage
    secondaryInputImage:(MPSTemporaryImage *)secondaryInputImage {
  auto outputWidth = inputImage.width * 2;
  auto outputHeight = inputImage.height * 2;
  MPSTemporaryImage *upsampledOutput =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:outputWidth
                                                    height:outputHeight
                                                  channels:inputImage.featureChannels];
  [upLayer encodeToCommandBuffer:buffer inputImage:inputImage outputImage:upsampledOutput];

  auto convOutput = [self encodeConvolutionWithCommandBuffer:buffer convolutionLayer:convLayer
                                                  inputImage:upsampledOutput];

  MPSTemporaryImage *concatOutput =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:convOutput.width
                                                    height:convOutput.height
                                                  channels:convOutput.featureChannels +
       secondaryInputImage.featureChannels];
  [concatLayer encodeToCommandBuffer:buffer primaryInputImage:convOutput
                 secondaryInputImage:secondaryInputImage outputImage:concatOutput];
  return concatOutput;
}

- (void)encodeAndCommitAsyncWithCommandQueue:(id<MTLCommandQueue>)queue
                                  inputImage:(MPSImage *)inputImage
                                 outputImage:(MPSImage *)outputImage
                                  completion:(LTCompletionBlock)completion {
  LTParameterAssert(completion, @"Completion block must not be nil.");

  __block auto buffer = [queue commandBuffer];
  dispatch_async(self.dispatchQueue, ^{
    [self encodeWithCommandBuffer:buffer inputImage:inputImage outputImage:outputImage];
    [buffer addCompletedHandler:^(id<MTLCommandBuffer>) {
      completion();
    }];
    [buffer commit];
  });
}

/// The size in pixels of the images used as input for this network during training.
static const CGFloat kNetworkTrainedInputSide = 512;

/// Maximal optimal size in pixels for the shorter side of an image used as input for this network.
static const CGFloat kNetworkMaximalInputSmallSide = kNetworkTrainedInputSide;

/// Minimal optimal size in pixels for the shorter side of an image used as input for this network.
static const CGFloat kNetworkMinimalInputSmallSide = kNetworkTrainedInputSide / 2;

/// Calculates the optimal size to use for an input to the network given the original size of the
/// image. Given the size of images the network trained on, best results are achieved when the small
/// side of the image is no smaller than half the original training size and no bigger than twice
/// the original training size. Due to the two dyadic downsampling and upsampling steps in the
/// network, best results are achieved for input sizes that are a multiple of 4.
- (CGSize)optimalInputSizeWithSize:(CGSize)size {
  CGFloat smallSide = std::min(size.width, size.height);
  if (smallSide <= kNetworkMaximalInputSmallSide && smallSide >= kNetworkMinimalInputSmallSide) {
    return size;
  }
  CGSize sizeToFill = smallSide > kNetworkMaximalInputSmallSide ?
      CGSizeMake(kNetworkMaximalInputSmallSide, kNetworkMaximalInputSmallSide) :
      CGSizeMake(kNetworkMinimalInputSmallSide, kNetworkMinimalInputSmallSide);
  CGSize resizedInputSize = CGSizeAspectFill(size, sizeToFill);
  resizedInputSize.width = ((int)(resizedInputSize.width + 3) / 4) * 4;
  resizedInputSize.height = ((int)(resizedInputSize.height + 3) / 4) * 4;
  return resizedInputSize;
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
