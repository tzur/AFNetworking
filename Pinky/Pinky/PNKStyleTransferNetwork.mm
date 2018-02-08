// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKStyleTransferNetwork.h"

#import "MPSTemporaryImage+Factory.h"
#import "PNKActivationLayer.h"
#import "PNKAddition.h"
#import "PNKConditionalInstanceNormLayer.h"
#import "PNKConstantAlpha.h"
#import "PNKConvolutionLayer.h"
#import "PNKNeuralNetworkModel.h"
#import "PNKReflectionPadding.h"
#import "PNKUpsampling.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKStyleTransferNetwork ()

/// Device to encode the operations of this network.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Padding layer to avoif border artifacts in the output of the network.
@property (readonly, nonatomic) PNKReflectionPadding *padding;

/// Convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *downConv1;

/// Conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *downCINorm1;

/// Convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *downConv2;

/// Conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *downCINorm2;

/// Convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *downConv3;

/// Conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *downCINorm3;

/// Residual convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *residualConv1_1;

/// Residual conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *residualCINorm1_1;

/// Residual convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *residualConv2_1;

/// Residual conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *residualCINorm2_1;

/// Residual addition layer.
@property (readonly, nonatomic) PNKAddition *residualAdd1;

/// Residual convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *residualConv1_2;

/// Residual conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *residualCINorm1_2;

/// Residual convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *residualConv2_2;

/// Residual conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *residualCINorm2_2;

/// Residual addition layer.
@property (readonly, nonatomic) PNKAddition *residualAdd2;

/// Residual convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *residualConv1_3;

/// Residual conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *residualCINorm1_3;

/// Residual convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *residualConv2_3;

/// Residual conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *residualCINorm2_3;

/// Residual addition layer.
@property (readonly, nonatomic) PNKAddition *residualAdd3;

/// Residual convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *residualConv1_4;

/// Residual conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *residualCINorm1_4;

/// Residual convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *residualConv2_4;

/// Residual conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *residualCINorm2_4;

/// Residual addition layer.
@property (readonly, nonatomic) PNKAddition *residualAdd4;

/// Residual convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *residualConv1_5;

/// Residual conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *residualCINorm1_5;

/// Residual convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *residualConv2_5;

/// Residual conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *residualCINorm2_5;

/// Residual addition layer.
@property (readonly, nonatomic) PNKAddition *residualAdd5;

/// Upsampling layer.
@property (readonly, nonatomic) PNKUpsampling *upSample1;

/// Convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *upConv1;

/// Conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *upCINorm1;

/// Upsampling layer.
@property (readonly, nonatomic) PNKUpsampling *upSample2;

/// Convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *upConv2;

/// Conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *upCINorm2;

/// Convolution layer.
@property (readonly, nonatomic) PNKConvolutionLayer *upConv3;

/// Conditional normalization layer.
@property (readonly, nonatomic) PNKConditionalInstanceNormLayer *upCINorm3;

/// Final activation layer. This layer also crops the output to remove the padding added.
@property (readonly, nonatomic) MPSCNNNeuronSigmoid *sigmoidActivation;

/// Collection of all conditional normalization layers to update with the chosen style.
@property (readonly, nonatomic) NSArray<PNKConditionalInstanceNormLayer *> *normalizationLayers;

/// Flag signifying the type of architecture used in the loaded network. \c YES iff the network has
/// 3 residual blocks, \c NO iff the network has 5 residual blocks.
@property (readonly, nonatomic) BOOL isLiteNetwork;

@end

@implementation PNKStyleTransferNetwork

- (instancetype)initWithDevice:(id<MTLDevice>)device
                         model:(const pnk::NeuralNetworkModel &)networkModel {
  if (self = [super init]) {
    _device = device;
    [self buildNetworkWithModel:networkModel];
    [self setupAndVerifyStylesCount];
    [self updateStyle:0];
  }
  return self;
}

/// The size in pixels of the padding on each side of the input image.
static const NSUInteger kPaddingSide = 32;

/// The padding used for the input of the network.
static const pnk::PaddingSize kPadding = {
  .left = kPaddingSide,
  .top = kPaddingSide,
  .right = kPaddingSide,
  .bottom = kPaddingSide
};

- (void)buildNetworkWithModel:(const pnk::NeuralNetworkModel &)model {
  /// input-output
  auto inputConv = model.convolutionKernels.at("conv1-conv");
  _inputChannels = inputConv.inputFeatureChannels;
  auto lastConv = model.convolutionKernels.at("upcv3-conv");
  _outputChannels = lastConv.outputFeatureChannels;

  /// Preprocess
  _padding = [[PNKReflectionPadding alloc] initWithDevice:self.device paddingSize:kPadding];
  /// Encode
  _downConv1 = [[PNKConvolutionLayer alloc]
                initWithDevice:self.device
                convolutionModel:model.convolutionKernels.at("conv1-conv")];
  _downCINorm1 = [[PNKConditionalInstanceNormLayer alloc]
                  initWithDevice:self.device
                  normalizationModel:model.normalizationKernels.at("conv1-normalization")
                  activationModel:model.activationKernels.at("conv1-relu")];
  _downConv2 = [[PNKConvolutionLayer alloc]
                initWithDevice:self.device
                convolutionModel:model.convolutionKernels.at("conv2-conv")];
  _downCINorm2 = [[PNKConditionalInstanceNormLayer alloc]
                  initWithDevice:self.device
                  normalizationModel:model.normalizationKernels.at("conv2-normalization")
                  activationModel:model.activationKernels.at("conv2-relu")];
  _downConv3 = [[PNKConvolutionLayer alloc]
                initWithDevice:self.device
                convolutionModel:model.convolutionKernels.at("conv3-conv")];
  _downCINorm3 = [[PNKConditionalInstanceNormLayer alloc]
                  initWithDevice:self.device
                  normalizationModel:model.normalizationKernels.at("conv3-normalization")
                  activationModel:model.activationKernels.at("conv3-relu")];

  /// Residual
  _residualConv1_1 = [[PNKConvolutionLayer alloc]
                      initWithDevice:self.device
                      convolutionModel:model.convolutionKernels.at("resd1-1-conv")];
  _residualCINorm1_1 = [[PNKConditionalInstanceNormLayer alloc]
                        initWithDevice:self.device
                        normalizationModel:model.normalizationKernels.at("resd1-1-normalization")
                        activationModel:model.activationKernels.at("resd1-1-relu")];
  _residualConv2_1 = [[PNKConvolutionLayer alloc]
                      initWithDevice:self.device
                      convolutionModel:model.convolutionKernels.at("resd1-2-conv")];
  _residualCINorm2_1 = [[PNKConditionalInstanceNormLayer alloc]
                        initWithDevice:self.device
                        normalizationModel:model.normalizationKernels.at("resd1-2-normalization")
                        activationModel:{.activationType = pnk::ActivationTypeIdentity}];
  _residualAdd1 = [[PNKAddition alloc] initWithDevice:self.device];
  _residualConv1_2 = [[PNKConvolutionLayer alloc]
                      initWithDevice:self.device
                      convolutionModel:model.convolutionKernels.at("resd2-1-conv")];
  _residualCINorm1_2 = [[PNKConditionalInstanceNormLayer alloc]
                        initWithDevice:self.device
                        normalizationModel:model.normalizationKernels.at("resd2-1-normalization")
                        activationModel:model.activationKernels.at("resd2-1-relu")];
  _residualConv2_2 = [[PNKConvolutionLayer alloc]
                      initWithDevice:self.device
                      convolutionModel:model.convolutionKernels.at("resd2-2-conv")];
  _residualCINorm2_2 = [[PNKConditionalInstanceNormLayer alloc]
                        initWithDevice:self.device
                        normalizationModel:model.normalizationKernels.at("resd2-2-normalization")
                        activationModel:{.activationType = pnk::ActivationTypeIdentity}];
  _residualAdd2 = self.residualAdd1;
  _residualConv1_3 = [[PNKConvolutionLayer alloc]
                      initWithDevice:self.device
                      convolutionModel:model.convolutionKernels.at("resd3-1-conv")];
  _residualCINorm1_3 = [[PNKConditionalInstanceNormLayer alloc]
                        initWithDevice:self.device
                        normalizationModel:model.normalizationKernels.at("resd3-1-normalization")
                        activationModel:model.activationKernels.at("resd3-1-relu")];
  _residualConv2_3 = [[PNKConvolutionLayer alloc]
                      initWithDevice:self.device
                      convolutionModel:model.convolutionKernels.at("resd3-2-conv")];
  _residualCINorm2_3 = [[PNKConditionalInstanceNormLayer alloc]
                        initWithDevice:self.device
                        normalizationModel:model.normalizationKernels.at("resd3-2-normalization")
                        activationModel:{.activationType = pnk::ActivationTypeIdentity}];
  _residualAdd3 = self.residualAdd1;
  _isLiteNetwork = YES;
  if (model.convolutionKernels.count("resd4-1-conv") > 0) {
    _isLiteNetwork = NO;
    _residualConv1_4 = [[PNKConvolutionLayer alloc]
                        initWithDevice:self.device
                        convolutionModel:model.convolutionKernels.at("resd4-1-conv")];
    _residualCINorm1_4 = [[PNKConditionalInstanceNormLayer alloc]
                          initWithDevice:self.device
                          normalizationModel:model.normalizationKernels.at("resd4-1-normalization")
                          activationModel:model.activationKernels.at("resd4-1-relu")];
    _residualConv2_4 = [[PNKConvolutionLayer alloc]
                        initWithDevice:self.device
                        convolutionModel:model.convolutionKernels.at("resd4-2-conv")];
    _residualCINorm2_4 = [[PNKConditionalInstanceNormLayer alloc]
                          initWithDevice:self.device
                          normalizationModel:model.normalizationKernels.at("resd4-2-normalization")
                          activationModel:{.activationType = pnk::ActivationTypeIdentity}];
    _residualAdd4 = self.residualAdd1;
    _residualConv1_5 = [[PNKConvolutionLayer alloc]
                        initWithDevice:self.device
                        convolutionModel:model.convolutionKernels.at("resd5-1-conv")];
    _residualCINorm1_5 = [[PNKConditionalInstanceNormLayer alloc]
                          initWithDevice:self.device
                          normalizationModel:model.normalizationKernels.at("resd5-1-normalization")
                          activationModel:model.activationKernels.at("resd5-1-relu")];
    _residualConv2_5 = [[PNKConvolutionLayer alloc]
                        initWithDevice:self.device
                        convolutionModel:model.convolutionKernels.at("resd5-2-conv")];
    _residualCINorm2_5 = [[PNKConditionalInstanceNormLayer alloc]
                          initWithDevice:self.device
                          normalizationModel:model.normalizationKernels.at("resd5-2-normalization")
                          activationModel:{.activationType = pnk::ActivationTypeIdentity}];
    _residualAdd5 = self.residualAdd1;
  }

  /// Decode
  _upSample1 = [[PNKUpsampling alloc] initWithDevice:self.device
                                      upsamplingType:PNKUpsamplingTypeNearestNeighbor];
  _upConv1 = [[PNKConvolutionLayer alloc]
              initWithDevice:self.device
              convolutionModel:model.convolutionKernels.at("upcv1-conv-conv")];
  _upCINorm1 = [[PNKConditionalInstanceNormLayer alloc]
                initWithDevice:self.device
                normalizationModel:model.normalizationKernels.at("upcv1-conv-normalization")
                activationModel:model.activationKernels.at("upcv1-conv-relu")];
  _upSample2 = self.upSample1;
  _upConv2 = [[PNKConvolutionLayer alloc]
              initWithDevice:self.device
              convolutionModel:model.convolutionKernels.at("upcv2-conv-conv")];
  _upCINorm2 = [[PNKConditionalInstanceNormLayer alloc]
                initWithDevice:self.device
                normalizationModel:model.normalizationKernels.at("upcv2-conv-normalization")
                activationModel:model.activationKernels.at("upcv2-conv-relu")];
  _upConv3 = [[PNKConvolutionLayer alloc]
              initWithDevice:self.device
              convolutionModel:model.convolutionKernels.at("upcv3-conv")];
  _upCINorm3 = [[PNKConditionalInstanceNormLayer alloc]
                initWithDevice:self.device
                normalizationModel:model.normalizationKernels.at("upcv3-normalization")
                activationModel:{.activationType = pnk::ActivationTypeIdentity}];

  _sigmoidActivation = [[MPSCNNNeuronSigmoid alloc] initWithDevice:self.device];
  self.sigmoidActivation.offset = {kPaddingSide, kPaddingSide, 0};

  /// Helpers
  if (self.isLiteNetwork) {
    _normalizationLayers = @[
      self.downCINorm1,
      self.downCINorm2,
      self.downCINorm3,
      self.residualCINorm1_1,
      self.residualCINorm2_1,
      self.residualCINorm1_2,
      self.residualCINorm2_2,
      self.residualCINorm1_3,
      self.residualCINorm2_3,
      self.upCINorm1,
      self.upCINorm2,
      self.upCINorm3
      ];
  } else {
    _normalizationLayers = @[
    self.downCINorm1,
    self.downCINorm2,
    self.downCINorm3,
    self.residualCINorm1_1,
    self.residualCINorm2_1,
    self.residualCINorm1_2,
    self.residualCINorm2_2,
    self.residualCINorm1_3,
    self.residualCINorm2_3,
    self.residualCINorm1_4,
    self.residualCINorm2_4,
    self.residualCINorm1_5,
    self.residualCINorm2_5,
    self.upCINorm1,
    self.upCINorm2,
    self.upCINorm3
    ];
  }
}

- (void)setupAndVerifyStylesCount {
  _stylesCount = _downCINorm1.conditionsCount;
  for (PNKConditionalInstanceNormLayer *layer in self.normalizationLayers) {
    LTParameterAssert(layer.conditionsCount == self.stylesCount);
  }
}

- (void)updateStyle:(NSUInteger)style {
  for (PNKConditionalInstanceNormLayer *layer in self.normalizationLayers) {
    [layer setSingleCondition:style];
  }
}

- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)buffer inputImage:(MPSImage *)inputImage
                    outputImage:(MPSImage *)outputImage styleIndex:(NSUInteger)styleIndex {
  [self updateStyle:styleIndex];
  [self encodeWithCommandBuffer:buffer inputImage:inputImage outputImage:outputImage];
}

- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                     inputImage:(MPSImage *)inputImage
                    outputImage:(MPSImage *)outputImage {
  LTParameterAssert(outputImage.featureChannels >= self.outputChannels);
  LTParameterAssert(inputImage.featureChannels >= self.inputChannels);

  MPSTemporaryImage *preprocessOutput =
      [self encodePreProcessWithCommandBuffer:commandBuffer
                                   inputImage:inputImage];
  MPSTemporaryImage *down1Output =
      [self encodeNormalizedConvolutionWithCommandBuffer:commandBuffer
                                        convolutionLayer:self.downConv1
                                      normalizationLayer:self.downCINorm1
                                              inputImage:preprocessOutput];
  MPSTemporaryImage *down2Output =
      [self encodeNormalizedConvolutionWithCommandBuffer:commandBuffer
                                        convolutionLayer:self.downConv2
                                      normalizationLayer:self.downCINorm2
                                              inputImage:down1Output];
  MPSTemporaryImage *down3Output =
      [self encodeNormalizedConvolutionWithCommandBuffer:commandBuffer
                                        convolutionLayer:self.downConv3
                                      normalizationLayer:self.downCINorm3
                                              inputImage:down2Output];
  MPSTemporaryImage *residual1Output =
      [self encodeResidualBlockWithCommandBuffer:commandBuffer
                           firstConvolutionLayer:self.residualConv1_1
                         firstNormalizationLayer:self.residualCINorm1_1
                          secondConvolutionLayer:self.residualConv2_1
                        secondNormalizationLayer:self.residualCINorm2_1
                                   additionLayer:self.residualAdd1
                                      inputImage:down3Output];
  MPSTemporaryImage *residual2Output =
      [self encodeResidualBlockWithCommandBuffer:commandBuffer
                           firstConvolutionLayer:self.residualConv1_2
                         firstNormalizationLayer:self.residualCINorm1_2
                          secondConvolutionLayer:self.residualConv2_2
                        secondNormalizationLayer:self.residualCINorm2_2
                                   additionLayer:self.residualAdd2
                                      inputImage:residual1Output];
  MPSTemporaryImage *residual3Output =
      [self encodeResidualBlockWithCommandBuffer:commandBuffer
                           firstConvolutionLayer:self.residualConv1_3
                         firstNormalizationLayer:self.residualCINorm1_3
                          secondConvolutionLayer:self.residualConv2_3
                        secondNormalizationLayer:self.residualCINorm2_3
                                   additionLayer:self.residualAdd3
                                      inputImage:residual2Output];
  MPSTemporaryImage *up1Output;
  if (self.isLiteNetwork) {
    up1Output =
    [self encodeUpsampleConvolutionWithCommandBuffer:commandBuffer
                                       upsampleLayer:self.upSample1
                                    convolutionLayer:self.upConv1
                                  normalizationLayer:self.upCINorm1
                                          inputImage:residual3Output];
  } else {
    MPSTemporaryImage *residual4Output =
        [self encodeResidualBlockWithCommandBuffer:commandBuffer
                             firstConvolutionLayer:self.residualConv1_4
                           firstNormalizationLayer:self.residualCINorm1_4
                            secondConvolutionLayer:self.residualConv2_4
                          secondNormalizationLayer:self.residualCINorm2_4
                                     additionLayer:self.residualAdd4
                                        inputImage:residual3Output];
    MPSTemporaryImage *residual5Output =
        [self encodeResidualBlockWithCommandBuffer:commandBuffer
                             firstConvolutionLayer:self.residualConv1_5
                           firstNormalizationLayer:self.residualCINorm1_5
                            secondConvolutionLayer:self.residualConv2_5
                          secondNormalizationLayer:self.residualCINorm2_5
                                     additionLayer:self.residualAdd5
                                        inputImage:residual4Output];
    up1Output =
        [self encodeUpsampleConvolutionWithCommandBuffer:commandBuffer
                                           upsampleLayer:self.upSample1
                                        convolutionLayer:self.upConv1
                                      normalizationLayer:self.upCINorm1
                                              inputImage:residual5Output];
  }
  MPSTemporaryImage *up2Output =
      [self encodeUpsampleConvolutionWithCommandBuffer:commandBuffer
                                         upsampleLayer:self.upSample2
                                      convolutionLayer:self.upConv2
                                    normalizationLayer:self.upCINorm2
                                            inputImage:up1Output];
  MPSTemporaryImage *up3Output =
      [self encodeNormalizedConvolutionWithCommandBuffer:commandBuffer
                                        convolutionLayer:self.upConv3
                                      normalizationLayer:self.upCINorm3
                                              inputImage:up2Output];

  [self.sigmoidActivation encodeToCommandBuffer:commandBuffer sourceImage:up3Output
                               destinationImage:outputImage];
}

- (MPSTemporaryImage *)encodePreProcessWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                              inputImage:(MPSImage *)inputImage {
  NSUInteger paddedWidth = inputImage.width + kPadding.left + kPadding.right;
  NSUInteger paddedHeight = inputImage.height + kPadding.top + kPadding.bottom;
  MPSTemporaryImage *paddedOutput =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:paddedWidth
                                                    height:paddedHeight
                                                  channels:inputImage.featureChannels];
  [self.padding encodeToCommandBuffer:buffer inputImage:inputImage outputImage:paddedOutput];
  return paddedOutput;
}

- (MPSTemporaryImage *)encodeNormalizedConvolutionWithCommandBuffer:(id<MTLCommandBuffer>)buffer
    convolutionLayer:(PNKConvolutionLayer *)convLayer
    normalizationLayer:(PNKConditionalInstanceNormLayer *)normLayer
    inputImage:(MPSTemporaryImage *)inputImage {
  auto outputWidth = inputImage.width / convLayer.strideX;
  auto outputHeight = inputImage.height / convLayer.strideY;
  MPSTemporaryImage *convOutput =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:outputWidth
                                                    height:outputHeight
                                                  channels:convLayer.outputFeatureChannels];
  [convLayer encodeToCommandBuffer:buffer inputImage:inputImage outputImage:convOutput];
  MPSTemporaryImage *normOutput =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:outputWidth
                                                    height:outputHeight
                                                  channels:convLayer.outputFeatureChannels];
  [normLayer encodeToCommandBuffer:buffer inputImage:convOutput outputImage:normOutput];

  return normOutput;
}

- (MPSTemporaryImage *)encodeResidualBlockWithCommandBuffer:(id<MTLCommandBuffer>)buffer
    firstConvolutionLayer:(PNKConvolutionLayer *)firstConvLayer
    firstNormalizationLayer:(PNKConditionalInstanceNormLayer *)firstNormLayer
    secondConvolutionLayer:(PNKConvolutionLayer *)secondConvLayer
    secondNormalizationLayer:(PNKConditionalInstanceNormLayer *)secondNormLayer
    additionLayer:(PNKAddition *)additionLayer
    inputImage:(MPSTemporaryImage *)inputImage {
  inputImage.readCount += 1;

  MPSTemporaryImage *normConv1Output = [self encodeNormalizedConvolutionWithCommandBuffer:buffer
                                                                convolutionLayer:firstConvLayer
                                                              normalizationLayer:firstNormLayer
                                                                      inputImage:inputImage];
  MPSTemporaryImage *normConv2Output = [self encodeNormalizedConvolutionWithCommandBuffer:buffer
                                                                convolutionLayer:secondConvLayer
                                                              normalizationLayer:secondNormLayer
                                                                      inputImage:normConv1Output];
  MPSTemporaryImage *addOutput =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:inputImage.width
                                                    height:inputImage.height
                                                  channels:inputImage.featureChannels];
  [additionLayer encodeToCommandBuffer:buffer primaryInputImage:inputImage
                   secondaryInputImage:normConv2Output outputImage:addOutput];
  return addOutput;
}

- (MPSTemporaryImage *)encodeUpsampleConvolutionWithCommandBuffer:(id<MTLCommandBuffer>)buffer
    upsampleLayer:(PNKUpsampling *)upLayer
    convolutionLayer:(PNKConvolutionLayer *)convLayer
    normalizationLayer:(PNKConditionalInstanceNormLayer *)normLayer
    inputImage:(MPSTemporaryImage *)inputImage {
  auto outputWidth = inputImage.width * 2;
  auto outputHeight = inputImage.height * 2;
  MPSTemporaryImage *upsampledOutput =
      [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:buffer
                                                     width:outputWidth
                                                    height:outputHeight
                                                  channels:inputImage.featureChannels];
  [upLayer encodeToCommandBuffer:buffer inputImage:inputImage outputImage:upsampledOutput];
  return [self encodeNormalizedConvolutionWithCommandBuffer:buffer convolutionLayer:convLayer
                                         normalizationLayer:normLayer inputImage:upsampledOutput];
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
