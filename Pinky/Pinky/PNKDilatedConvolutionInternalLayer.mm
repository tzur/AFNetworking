// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKDilatedConvolutionInternalLayer.h"

#import "MPSCNNConvolution+Factory.h"
#import "MPSTemporaryImage+Factory.h"
#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKDilatedConvolutionInternalLayer ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Space2Patch kernel function name.
@property (readonly, nonatomic) NSString *space2PatchFunctionName;

/// Space2patch kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> space2PatchState;

/// Patch2space kernel function name.
@property (readonly, nonatomic) NSString *patch2SpaceFunctionName;

/// Patch2space kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> patch2SpaceState;

/// Underlying convolution kernel used for performing the intermediate convolution operation between
/// copying the image to patches and back again.
@property (readonly, nonatomic) MPSCNNConvolution *convolutionKernel;

/// Padding type used in the convolution.
@property (readonly, nonatomic) pnk::PaddingType padding;

/// Kernel dilation in the x dimension.
@property (readonly, nonatomic) NSUInteger dilationX;

/// Kernel dilation in the y dimension.
@property (readonly, nonatomic) NSUInteger dilationY;

@end

@implementation PNKDilatedConvolutionInternalLayer

@synthesize kernelWidth = _kernelWidth;
@synthesize kernelHeight = _kernelHeight;
@synthesize inputFeatureChannels = _inputFeatureChannels;
@synthesize outputFeatureChannels = _outputFeatureChannels;
@synthesize strideX = _strideX;
@synthesize strideY = _strideY;
@synthesize groups = _groups;

/// Texture input space2patch kernel function name.
static NSString * const kS2PKernelSingleFunctionName = @"space2PatchSingle";

/// Texture array input space2patch kernel function name.
static NSString * const kS2PKernelArrayFunctionName = @"space2PatchArray";

/// Texture input patch2space kernel function name.
static NSString * const kP2SKernelSingleFunctionName = @"patch2SpaceSingle";

/// Texture array input patch2space kernel function name.
static NSString * const kP2SKernelArrayFunctionName = @"patch2SpaceArray";

- (instancetype)initWithDevice:(id<MTLDevice>)device
              convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
               activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    _device = device;
    [self updatePropertiesWithConvolutionModel:convolutionModel];
    [self createKernelWithConvolutionModel:convolutionModel activationModel:activationModel];
    [self createStates];
  }
  return self;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
              convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel {
  return [self initWithDevice:device convolutionModel:convolutionModel
              activationModel:{.activationType = pnk::ActivationTypeIdentity}];
}

- (void)updatePropertiesWithConvolutionModel:(pnk::ConvolutionKernelModel)convolutionModel {
  LTParameterAssert(convolutionModel.strideX == 1, @"strideX must be 1, got %lu",
                    (unsigned long)convolutionModel.strideX);
  LTParameterAssert(convolutionModel.strideY == 1, @"strideY must be 1, got %lu",
                    (unsigned long)convolutionModel.strideY);
  LTParameterAssert(convolutionModel.kernelWidth % 2 == 1, @"Kernel width must be odd, got %lu",
                    (unsigned long)convolutionModel.kernelWidth);
  LTParameterAssert(convolutionModel.kernelHeight % 2 == 1, @"Kernel height must be odd, got %lu",
                    (unsigned long)convolutionModel.kernelHeight);
  LTParameterAssert(convolutionModel.groups == 1, @"Only 1 group is supported, got %lu",
                    (unsigned long)convolutionModel.groups);
  _kernelWidth = convolutionModel.kernelWidth;
  _kernelHeight = convolutionModel.kernelHeight;
  _inputFeatureChannels = convolutionModel.inputFeatureChannels;
  _outputFeatureChannels = convolutionModel.outputFeatureChannels;
  _dilationX = convolutionModel.dilationX;
  _dilationY = convolutionModel.dilationY;
  _groups = convolutionModel.groups;
  _padding = convolutionModel.padding;
}

- (void)createKernelWithConvolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
                         activationModel:(const pnk::ActivationKernelModel &)activationModel {
  pnk::ConvolutionKernelModel nonDilatedConvolutionModel = convolutionModel;
  nonDilatedConvolutionModel.dilationX = 1;
  nonDilatedConvolutionModel.dilationY = 1;
  _convolutionKernel = [MPSCNNConvolution pnk_cnnConvolutionWithDevice:self.device
                                                      convolutionModel:nonDilatedConvolutionModel
                                                       activationModel:activationModel];
}

- (void)createStates {
  vector_ushort2 dilationRate = {(ushort)self.dilationX, (ushort)self.dilationY};
  vector_ushort2 kernelGap = {(ushort)(self.kernelWidth / 2), (ushort)(self.kernelHeight / 2)};
  vector_ushort2 paddingSize = [self paddingSize];

  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&dilationRate type:MTLDataTypeUShort2
                             withName:@"dilationRate"];
  [functionConstants setConstantValue:&kernelGap type:MTLDataTypeUShort2
                             withName:@"kernelGap"];
  [functionConstants setConstantValue:&paddingSize type:MTLDataTypeUShort2
                             withName:@"paddingSize"];

  _space2PatchFunctionName = self.convolutionKernel.inputFeatureChannels > 4 ?
      kS2PKernelArrayFunctionName : kS2PKernelSingleFunctionName;
  _space2PatchState = PNKCreateComputeStateWithConstants(self.device, self.space2PatchFunctionName,
                                                         functionConstants);

  _patch2SpaceFunctionName = self.convolutionKernel.outputFeatureChannels > 4 ?
      kP2SKernelArrayFunctionName : kP2SKernelSingleFunctionName;
  _patch2SpaceState = PNKCreateComputeStateWithConstants(self.device, self.patch2SpaceFunctionName,
                                                         functionConstants);
}

- (vector_ushort2)paddingSize {
  switch (self.padding) {
    case pnk::PaddingTypeSame:
      return {0, 0};
    case pnk::PaddingTypeValid:
      return {(ushort)(self.kernelWidth / 2), (ushort)(self.kernelHeight / 2)};
  }

  LTParameterAssert(NO, @"Invalid padding type: %lu", (unsigned long)self.padding);
}

#pragma mark -
#pragma mark PNKUnaryImageKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(inputImage.numberOfImages == 1, @"Input image cannot be a batch");
  LTParameterAssert(inputImage.featureChannels == self.inputFeatureChannels,
                    @"Input image featureChannels must be %lu, got: %lu",
                    (unsigned long)self.inputFeatureChannels,
                    (unsigned long)inputImage.featureChannels);
  LTParameterAssert(outputImage.numberOfImages == 1, @"Output image cannot be a batch");
  LTParameterAssert(outputImage.featureChannels == self.outputFeatureChannels,
                    @"Output image featureChannels must be %lu, got: %lu",
                    (unsigned long)self.outputFeatureChannels,
                    (unsigned long)outputImage.featureChannels);

  MTLSize outputSize = {outputImage.width, outputImage.height, outputImage.featureChannels};
  MTLSize expectedInputSize = [self inputSizeForOutputSize:outputSize];
  LTParameterAssert(inputImage.width == expectedInputSize.width &&
                    inputImage.height == expectedInputSize.height,
                    @"Input image must be of size (%lu, %lu), got: (%lu, %lu)",
                    (unsigned long)expectedInputSize.width, (unsigned long)expectedInputSize.height,
                    (unsigned long)inputImage.width, (unsigned long)inputImage.height);

  // The width and height of the transformed image must be exactly
  // divisible by the dilation rate, so add zero padding if necessary.
  NSUInteger inputHeightPadded =
      ((inputImage.height + self.dilationY - 1) / self.dilationY) * self.dilationY;
  NSUInteger inputWidthPadded =
      ((inputImage.width + self.dilationX - 1) / self.dilationX) * self.dilationX;

  // There are \c dilation patches in each direction. There is a gap of zeros in between each pair
  // of adjacent patches. As this gap is used for zero padding,  the size of the gap depends on the
  // size of the filter kernel.
  NSUInteger gapWidth = self.kernelWidth / 2;
  NSUInteger gapHeight = self.kernelHeight / 2;
  NSUInteger patchedImageWidth = inputWidthPadded + (self.dilationX - 1) * gapWidth;
  NSUInteger patchedImageHeight = inputHeightPadded + (self.dilationY - 1) * gapHeight;

  NSUInteger patchWidth = inputWidthPadded / self.dilationX;
  NSUInteger patchHeight = inputHeightPadded / self.dilationY;
  NSUInteger patchWidthWithGap = patchWidth + gapWidth;
  NSUInteger patchHeightWithGap = patchHeight + gapHeight;

  // Rounding up the size to even numbers seems to make the convolution a tiny bit faster.
  if (patchedImageWidth % 2 == 1) {
    patchedImageWidth += 1;
  }
  if (patchedImageHeight % 2 == 1) {
    patchedImageHeight += 1;
  }

  auto patchedInputImage = [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                            width:patchedImageWidth
                            height:patchedImageHeight
                            channels:self.inputFeatureChannels];

  auto textures = @[inputImage.texture, patchedInputImage.texture];
  MTLSize workingSpaceSize = {
    patchWidthWithGap,
    patchHeightWithGap,
    inputImage.texture.arrayLength
  };

  PNKComputeDispatchWithDefaultThreads(self.space2PatchState, commandBuffer, @[], textures,
                                       self.space2PatchFunctionName, workingSpaceSize);

  if ([inputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *) inputImage).readCount -= 1;
  }

  auto patchedOutputImage = [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                             width:patchedImageWidth
                             height:patchedImageHeight
                             channels:self.outputFeatureChannels];

  [self.convolutionKernel encodeToCommandBuffer:commandBuffer sourceImage:patchedInputImage
                               destinationImage:patchedOutputImage];

  textures = @[patchedOutputImage.texture, outputImage.texture];

  vector_ushort2 paddingSize = [self paddingSize];
  workingSpaceSize = {
    patchWidth - 2 * paddingSize.x,
    patchHeight - 2 * paddingSize.y,
    outputImage.texture.arrayLength
  };

  PNKComputeDispatchWithDefaultThreads(self.patch2SpaceState, commandBuffer, @[], textures,
                                       self.patch2SpaceFunctionName, workingSpaceSize);
  patchedOutputImage.readCount -= 1;
}

- (MTLSize)inputSizeForOutputSize:(MTLSize)outputSize {
  vector_ushort2 paddingSize = [self paddingSize];
  return {
    outputSize.width + 2 * paddingSize.x * self.dilationX,
    outputSize.height + 2 * paddingSize.y * self.dilationY,
    self.inputFeatureChannels
  };
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = [self inputSizeForOutputSize:outputSize]
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
