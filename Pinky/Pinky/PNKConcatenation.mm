// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKConcatenation.h"

#import "PNKComputeDispatch.h"
#import "PNKComputeState.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKConcatenation ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode.
@property (readonly, nonatomic) id<MTLComputePipelineState> state;

/// Kernel function name.
@property (readonly, nonatomic) NSString *functionName;

@end

@implementation PNKConcatenation

/// Name of kernel function for concatenating 2 single textures into a single texture.
static NSString * const kKernelFunctionSingleAndSingleToSingle = @"concatSingleAndSingleToSingle";

/// Name of kernel function for concatenating 2 single textures into an array of textures.
static NSString * const kKernelFunctionSingleAndSingleToArray = @"concatSingleAndSingleToArray";

/// Name of kernel function for concatenating a single texture and an array of textures into an
/// array of textures.
static NSString * const kKernelFunctionSingleAndArrayToArray = @"concatSingleAndArrayToArray";

/// Name of kernel function for concatenating an array of textures and a single texture into an
/// array of textures.
static NSString * const kKernelFunctionArrayAndSingleToArray = @"concatArrayAndSingleToArray";

/// Name of kernel function for concatenating 2 arrays of textures into an array of textures.
static NSString * const kKernelFunctionArrayAndArrayToArray = @"concatArrayAndArrayToArray";

/// Number of channels in each texture in array.
static NSUInteger kChannelsPerTexture = 4;

@synthesize primaryInputFeatureChannels = _primaryInputFeatureChannels;
@synthesize secondaryInputFeatureChannels = _secondaryInputFeatureChannels;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDevice:(id<MTLDevice>)device
   primaryInputFeatureChannels:(NSUInteger)primaryInputFeatureChannels
 secondaryInputFeatureChannels:(NSUInteger)secondaryInputFeatureChannels {
  if (self = [super init]) {
    _device = device;
    _primaryInputFeatureChannels = primaryInputFeatureChannels;
    _secondaryInputFeatureChannels = secondaryInputFeatureChannels;

    [self createState];
  }
  return self;
}

- (void)createState {
  if (self.primaryInputFeatureChannels <= kChannelsPerTexture) {
    if (self.secondaryInputFeatureChannels <= kChannelsPerTexture) {
      if (self.primaryInputFeatureChannels + self.secondaryInputFeatureChannels <=
          kChannelsPerTexture) {
        _functionName = kKernelFunctionSingleAndSingleToSingle;
      } else {
        _functionName = kKernelFunctionSingleAndSingleToArray;
      }
    } else {
      _functionName = kKernelFunctionSingleAndArrayToArray;
    }
  } else {
    if (self.secondaryInputFeatureChannels <= kChannelsPerTexture) {
      _functionName = kKernelFunctionArrayAndSingleToArray;
    } else {
      _functionName = kKernelFunctionArrayAndArrayToArray;
    }
  }

  auto functionConstants = [[MTLFunctionConstantValues alloc] init];
  [functionConstants setConstantValue:&_primaryInputFeatureChannels type:MTLDataTypeUShort
                             withName:@"primaryInputFeatureChannels"];
  [functionConstants setConstantValue:&_secondaryInputFeatureChannels type:MTLDataTypeUShort
                             withName:@"secondaryInputFeatureChannels"];
  _state = PNKCreateComputeStateWithConstants(self.device, self.functionName, functionConstants);
}

#pragma mark -
#pragma mark PNKBinaryImageKernel
#pragma mark -

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
          primaryInputTexture:(id<MTLTexture>)primaryInputTexture
        secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                outputTexture:(id<MTLTexture>)outputTexture {
  [self verifyParametersWithPrimaryInputTexture:primaryInputTexture
                          secondaryInputTexture:secondaryInputTexture outputTexture:outputTexture];

  NSArray<id<MTLTexture>> *textures = @[
    primaryInputTexture,
    secondaryInputTexture,
    outputTexture
  ];
  MTLSize workingSpaceSize = {outputTexture.width, outputTexture.height, 1};

  PNKComputeDispatchWithDefaultThreads(self.state, commandBuffer, @[], textures, self.functionName,
                                       workingSpaceSize);
}

- (void)verifyParametersWithPrimaryInputTexture:(id<MTLTexture>)primaryInputTexture
                          secondaryInputTexture:(id<MTLTexture>)secondaryInputTexture
                                  outputTexture:(id<MTLTexture>)outputTexture {
  LTParameterAssert(primaryInputTexture.arrayLength ==
                    (self.primaryInputFeatureChannels - 1) / kChannelsPerTexture + 1,
                    @"Primary input texture arrayLength must be %lu, got: %lu",
                    (self.primaryInputFeatureChannels - 1) / kChannelsPerTexture + 1,
                    primaryInputTexture.arrayLength);
  LTParameterAssert(secondaryInputTexture.arrayLength ==
                    (self.secondaryInputFeatureChannels - 1) / kChannelsPerTexture + 1,
                    @"Secondary input texture arrayLength must be %lu, got: %lu",
                    (self.secondaryInputFeatureChannels - 1) / kChannelsPerTexture + 1,
                    secondaryInputTexture.arrayLength);
  LTParameterAssert(outputTexture.arrayLength ==
                    (self.primaryInputFeatureChannels +
                     self.secondaryInputFeatureChannels - 1) / kChannelsPerTexture + 1,
                    @"Output texture arrayLength must be %lu, got: %lu",
                    (self.primaryInputFeatureChannels +
                     self.secondaryInputFeatureChannels - 1) / kChannelsPerTexture + 1,
                    outputTexture.arrayLength);
  LTParameterAssert(primaryInputTexture.width == secondaryInputTexture.width, @"Primary input "
                    "texture width must match secondary input texture width. got: (%lu, %lu)",
                    primaryInputTexture.width, secondaryInputTexture.width);
  LTParameterAssert(primaryInputTexture.height == secondaryInputTexture.height, @"Primary input "
                    "texture height must match secondary input texture height. got: (%lu, %lu)",
                    primaryInputTexture.height, secondaryInputTexture.height);
  LTParameterAssert(primaryInputTexture.width == outputTexture.width,
                    @"Primary input texture width must match output texture width. got: (%lu, %lu)",
                    primaryInputTexture.width, outputTexture.width);
  LTParameterAssert(primaryInputTexture.height == outputTexture.height, @"Primary input texture "
                    "height must match output texture height. got: (%lu, %lu)",
                    primaryInputTexture.height, outputTexture.height);
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            primaryInputImage:(MPSImage *)primaryInputImage
          secondaryInputImage:(MPSImage *)secondaryInputImage outputImage:(MPSImage *)outputImage {
  LTParameterAssert(primaryInputImage.featureChannels == self.primaryInputFeatureChannels,
                    @"Primary input image featureChannels must be %lu, got: %lu",
                    self.primaryInputFeatureChannels, primaryInputImage.featureChannels);
  LTParameterAssert(secondaryInputImage.featureChannels == self.secondaryInputFeatureChannels,
                    @"Secondary input image featureChannels must be %lu, got: %lu",
                    self.secondaryInputFeatureChannels, secondaryInputImage.featureChannels);
  LTParameterAssert(outputImage.featureChannels ==
                    self.primaryInputFeatureChannels + self.secondaryInputFeatureChannels,
                    @"Output image featureChannels must be %lu, got: %lu",
                    self.primaryInputFeatureChannels + self.secondaryInputFeatureChannels,
                    outputImage.featureChannels);

  [self encodeToCommandBuffer:commandBuffer primaryInputTexture:primaryInputImage.texture
        secondaryInputTexture:secondaryInputImage.texture outputTexture:outputImage.texture];

  if ([primaryInputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)primaryInputImage).readCount -= 1;
  }
  if ([secondaryInputImage isKindOfClass:[MPSTemporaryImage class]]) {
    ((MPSTemporaryImage *)secondaryInputImage).readCount -= 1;
  }
}

- (MTLRegion)primaryInputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = {
      outputSize.width,
      outputSize.height,
      self.primaryInputFeatureChannels
    }
  };
}

- (MTLRegion)secondaryInputRegionForOutputSize:(MTLSize)outputSize {
  return {
    .origin = {0, 0, 0},
    .size = {
      outputSize.width,
      outputSize.height,
      self.secondaryInputFeatureChannels
    }
  };
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
