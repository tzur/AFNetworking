// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKDilatedConvolutionInternalLayer.h"

#import "MPSCNNConvolution+Factory.h"
#import "MPSTemporaryImage+Factory.h"
#import "PNKActivationUtils.h"
#import "PNKBufferExtensions.h"
#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"
#import "PNKConvolutionUtils.h"

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

/// Buffer for passing the full zero-padding size <tt>(left + right, top + bottom)</tt> in the
/// Tensorflow convention to the kernel. It is transferred as a pair of \c ushorts.
@property (readonly, nonatomic) id<MTLBuffer> bufferForFullPaddingTF;

/// Kernel activation alpha parameters buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> alphaBuffer;

/// Kernel activation beta parameters buffer.
@property (readonly, nonatomic, nullable) id<MTLBuffer> betaBuffer;

/// Indicator if the layer's ActivationType is using the Alpha parameter buffer.
@property (readonly, nonatomic) bool hasAlphaBuffer;

/// Indicator if the layer's ActivationType is using the Beta parameter buffer.
@property (readonly, nonatomic) bool hasBetaBuffer;

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
    [self createKernelWithConvolutionModel:convolutionModel];
    [self createStatesWithActivationModel:activationModel];
    [self createBuffersWithActivationModel:activationModel];
  }
  return self;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
              convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel {
  return [self initWithDevice:device convolutionModel:convolutionModel
              activationModel:{.activationType = pnk::ActivationTypeIdentity}];
}

- (void)updatePropertiesWithConvolutionModel:(pnk::ConvolutionKernelModel)convolutionModel {
  LTParameterAssert(convolutionModel.groups == 1, @"Only 1 group is supported, got %lu",
                    (unsigned long)convolutionModel.groups);
  LTParameterAssert(convolutionModel.padding == pnk::PaddingTypeSame ||
                    convolutionModel.padding == pnk::PaddingTypeValid, @"Unknown padding type %lu",
                    (unsigned long)convolutionModel.padding);
  _kernelWidth = convolutionModel.kernelWidth;
  _kernelHeight = convolutionModel.kernelHeight;
  _inputFeatureChannels = convolutionModel.inputFeatureChannels;
  _outputFeatureChannels = convolutionModel.outputFeatureChannels;
  _dilationX = convolutionModel.dilationX;
  _dilationY = convolutionModel.dilationY;
  _strideX = convolutionModel.strideX;
  _strideY = convolutionModel.strideY;
  _groups = convolutionModel.groups;
  _padding = convolutionModel.padding;
}

- (void)createKernelWithConvolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel {
  pnk::ConvolutionKernelModel basicConvolutionModel = convolutionModel;
  basicConvolutionModel.dilationX = 1;
  basicConvolutionModel.dilationY = 1;
  basicConvolutionModel.strideX = 1;
  basicConvolutionModel.strideY = 1;

  pnk::ActivationKernelModel basicActivationModel = {.activationType = pnk::ActivationTypeIdentity};

  _convolutionKernel = [MPSCNNConvolution pnk_cnnConvolutionWithDevice:self.device
                                                      convolutionModel:basicConvolutionModel
                                                       activationModel:basicActivationModel];
}

- (void)createStatesWithActivationModel:(const pnk::ActivationKernelModel &)activationModel {
  vector_ushort2 dilationRate = {(ushort)self.dilationX, (ushort)self.dilationY};
  vector_ushort2 kernelGap = {(ushort)(self.kernelWidth / 2), (ushort)(self.kernelHeight / 2)};
  vector_ushort2 stride = {(ushort)self.strideX, (ushort)self.strideY};

  auto needsAlphaBeta = PNKActivationNeedsAlphaBetaParameters(activationModel.activationType);
  _hasAlphaBuffer = needsAlphaBeta.first;
  _hasBetaBuffer = needsAlphaBeta.second;

  ushort activationTypeAsUshort = (ushort)activationModel.activationType;

  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&dilationRate type:MTLDataTypeUShort2
                             withName:@"dilationRate"];
  [functionConstants setConstantValue:&kernelGap type:MTLDataTypeUShort2
                             withName:@"kernelGap"];
  [functionConstants setConstantValue:&stride type:MTLDataTypeUShort2
                             withName:@"stride"];
  [functionConstants setConstantValue:&activationTypeAsUshort type:MTLDataTypeUShort
                             withName:@"activationType"];
  [functionConstants setConstantValue:&_hasAlphaBuffer type:MTLDataTypeBool
                             withName:@"hasAlphaBuffer"];
  [functionConstants setConstantValue:&_hasBetaBuffer type:MTLDataTypeBool
                             withName:@"hasBetaBuffer"];

  _space2PatchFunctionName = self.convolutionKernel.inputFeatureChannels > 4 ?
      kS2PKernelArrayFunctionName : kS2PKernelSingleFunctionName;
  _space2PatchState = PNKCreateComputeStateWithConstants(self.device, self.space2PatchFunctionName,
                                                         functionConstants);

  _patch2SpaceFunctionName = self.convolutionKernel.outputFeatureChannels > 4 ?
      kP2SKernelArrayFunctionName : kP2SKernelSingleFunctionName;
  _patch2SpaceState = PNKCreateComputeStateWithConstants(self.device, self.patch2SpaceFunctionName,
                                                         functionConstants);
}

- (void)createBuffersWithActivationModel:(const pnk::ActivationKernelModel &)model {
  _bufferForFullPaddingTF = [self bufferForPairOfUShorts];

  _alphaBuffer = self.hasAlphaBuffer ? PNKHalfBufferFromFloatVector(self.device, model.alpha) : nil;
  _betaBuffer = self.hasBetaBuffer ? PNKHalfBufferFromFloatVector(self.device, model.beta) : nil;
}

- (id<MTLBuffer>)bufferForPairOfUShorts {
  id<MTLBuffer> buffer = [self.device newBufferWithLength:2 * sizeof(ushort)
                                                  options:MTLResourceCPUCacheModeWriteCombined];
  return buffer;
}

- (void)fillBuffer:(id<MTLBuffer>)buffer withFirst:(NSUInteger)first second:(NSUInteger)second {
  vector_ushort2 value = {(ushort)first, (ushort)second};
  memcpy(buffer.contents, &value, sizeof(value));
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

  MTLSize inputSize = {inputImage.width, inputImage.height, inputImage.featureChannels};
  MTLSize expectedOutputSize = PNKConvolutionOutputSize(inputSize, self.kernelWidth,
                                                        self.kernelHeight, self.dilationX,
                                                        self.dilationY, self.strideX,
                                                        self.strideY, self.padding,
                                                        self.outputFeatureChannels);
  LTParameterAssert(outputImage.width == expectedOutputSize.width &&
                    outputImage.height == expectedOutputSize.height &&
                    outputImage.featureChannels == expectedOutputSize.depth,
                    @"Output image must be of size (%lu, %lu, %lu), got: (%lu, %lu, %lu)",
                    expectedOutputSize.width, expectedOutputSize.height, expectedOutputSize.depth,
                    outputImage.width, outputImage.height, outputImage.featureChannels);

  pnk::PaddingSize fullPaddingTF = PNKConvolutionFullPaddingTF(inputImage.width, inputImage.height,
                                                               self.kernelWidth, self.kernelHeight,
                                                               self.dilationX, self.dilationY,
                                                               self.strideX, self.strideY,
                                                               self.padding);

  // The width and height of the transformed image must be exactly
  // divisible by the dilation rate, so add zero padding if necessary.
  NSUInteger inputWidthPadded =
      ((inputImage.width + fullPaddingTF.x - 1) / self.dilationX + 1) * self.dilationX;
  NSUInteger inputHeightPadded =
      ((inputImage.height + fullPaddingTF.y - 1) / self.dilationY + 1) * self.dilationY;

  // There are \c dilation patches in each direction. There is a gap of zeros in between each pair
  // of adjacent patches. As this gap is used for zero padding,  the size of the gap depends on the
  // size of the filter kernel.
  NSUInteger gapWidth = self.kernelWidth / 2;
  NSUInteger gapHeight = self.kernelHeight / 2;
  NSUInteger patchedImageWidth = inputWidthPadded + (self.dilationX - 1) * gapWidth;
  NSUInteger patchedImageHeight = inputHeightPadded + (self.dilationY - 1) * gapHeight;

  if (patchedImageWidth % 2 == 1) {
    patchedImageWidth += 1;
  }

  if (patchedImageHeight % 2 == 1) {
    patchedImageHeight += 1;
  }

  NSUInteger patchWidth = inputWidthPadded / self.dilationX;
  NSUInteger patchHeight = inputHeightPadded / self.dilationY;
  NSUInteger patchWidthWithGap = patchWidth + gapWidth;
  NSUInteger patchHeightWithGap = patchHeight + gapHeight;

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

  [self fillBuffer:self.bufferForFullPaddingTF withFirst:fullPaddingTF.x second:fullPaddingTF.y];
  auto buffers = @[self.bufferForFullPaddingTF];

  PNKComputeDispatchWithDefaultThreads(self.space2PatchState, commandBuffer, buffers, textures,
                                       self.space2PatchFunctionName, workingSpaceSize);

  if ([inputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *) inputImage).readCount -= 1;
  }

  auto patchedOutputImage = [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                             width:patchedImageWidth
                             height:patchedImageHeight
                             channels:self.outputFeatureChannels];

  pnk::PaddingSize leftTopPaddingMPS = PNKConvolutionLeftTopPaddingMPS(self.kernelWidth,
                                                                       self.kernelHeight, 1, 1);
  self.convolutionKernel.offset = {
    static_cast<NSInteger>(leftTopPaddingMPS.x),
    static_cast<NSInteger>(leftTopPaddingMPS.y),
    0
  };
  [self.convolutionKernel encodeToCommandBuffer:commandBuffer sourceImage:patchedInputImage
                               destinationImage:patchedOutputImage];

  textures = @[patchedOutputImage.texture, outputImage.texture];

  if (self.hasBetaBuffer) {
    buffers = @[self.alphaBuffer, self.betaBuffer];
  } else if (self.hasAlphaBuffer) {
    buffers = @[self.alphaBuffer];
  } else {
    buffers = @[];
  }

  workingSpaceSize = {
    patchWidth,
    patchHeight,
    outputImage.texture.arrayLength
  };

  PNKComputeDispatchWithDefaultThreads(self.patch2SpaceState, commandBuffer, buffers, textures,
                                       self.patch2SpaceFunctionName, workingSpaceSize);
  patchedOutputImage.readCount -= 1;
}

- (MTLRegion)inputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = PNKConvolutionInputSize(outputSize, self.kernelWidth, self.kernelHeight, self.dilationX,
                                    self.dilationY, self.strideX, self.strideY, self.padding,
                                    self.inputFeatureChannels)
  };
}

- (MTLSize)outputSizeForInputSize:(MTLSize)inputSize {
  return PNKConvolutionOutputSize(inputSize, self.kernelWidth, self.kernelHeight, self.dilationX,
                                  self.dilationY, self.strideX, self.strideY, self.padding,
                                  self.outputFeatureChannels);
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
