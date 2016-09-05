// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTAnisotropicDiffusionProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTOneShotImageProcessor.h"
#import "LTShaderStorage+LTAnisotropicDiffusionFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

/// Maximal available size to use when setting the kernel size in the
/// \c LTAnisotropicDiffusionProcessor. The upper bound value depends on the performance of the
/// currently supported devices since a large kernel size can significantly increase the processing
/// time. Upper bound was taken as the value for which processing from an input of size ~0.2MP to an
/// output of size ~8MP takes on iPhone 5s about 1.3 seconds.
const NSUInteger kKernelSizeUpperBound = 101;

@interface LTAnisotropicDiffusionProcessor ()

/// Input texture used as the source of the diffusion.
@property (readonly, nonatomic) LTTexture *input;

/// Guide texture used for determining the diffusion extent.
@property (readonly, nonatomic) LTTexture *guide;

/// Intermidiate texture of size <tt>(output.size.width, input.size.height)</tt>. Diffusion is
/// applied in two steps by first applying a horizontal diffusion from \c input to
/// \c intermediateTexture and then applying a vertical diffusion from \c intermediateTexture to
/// \c output.
@property (readonly, nonatomic) LTTexture *intermediateTexture;

/// Output texture for the diffusion result.
@property (readonly, nonatomic) LTTexture *output;

/// Processor for applying horizontal anisotropic diffusion from \c input to \c intermediateTexture.
@property (readonly, nonatomic) LTOneShotImageProcessor *horizontalDiffuser;

/// Processor for applying vertical anisotropic diffusion from \c intermediateTexture to \c output.
@property (readonly, nonatomic) LTOneShotImageProcessor *verticalDiffuser;

@end

@implementation LTAnisotropicDiffusionProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  return [self initWithInput:input guide:nil output:output];
}

- (instancetype)initWithInput:(LTTexture *)input guide:(LTTexture * _Nullable)guide
                       output:(LTTexture *)output {
  LTParameterAssert(input);
  LTParameterAssert(output);

  LTParameterAssert(input.size.width <= output.size.width &&
                    input.size.height <= output.size.height, @"input size (%@) must be smaller "
                    "than or equal to the output size (%@) in both dimensions",
                    NSStringFromCGSize(input.size), NSStringFromCGSize(output.size));
  LTParameterAssert(input.pixelFormat.components == output.pixelFormat.components,
                    @"input pixel format (%@) and output pixel format (%@) must have the same "
                    "number of components", input.pixelFormat, output.pixelFormat);

  if (self = [super init]) {
    _input = input;

    _guide = guide ?: input;
    LTParameterAssert(output.size == self.guide.size,
                      @"guide size (%@) and output size (%@) must be equal",
                      NSStringFromCGSize(guide.size), NSStringFromCGSize(output.size));

    _output = output;

    [self createIntermediateTexture];
    [self createHorizontalDiffuser];
    [self createVerticalDiffuser];

    self.rangeSigma = 0.1;
    self.kernelSize = 15;
  }

  return self;
}

- (void)createIntermediateTexture {
   CGSize intermediateSize = CGSizeMake(self.output.size.width, self.input.size.height);
  _intermediateTexture = [LTTexture textureWithSize:intermediateSize
                                        pixelFormat:self.output.pixelFormat allocateMemory:YES];
}

- (void)createHorizontalDiffuser {
  _horizontalDiffuser = [self diffusingProcessorWithInput:self.input
                                                   output:self.intermediateTexture];
  self.horizontalDiffuser[[LTAnisotropicDiffusionFsh texelOffset]] =
      $(LTVector2(1 / self.output.size.width, 0));
}

- (void)createVerticalDiffuser {
  _verticalDiffuser = [self diffusingProcessorWithInput:self.intermediateTexture
                                                 output:self.output];
  self.verticalDiffuser[[LTAnisotropicDiffusionFsh texelOffset]] =
      $(LTVector2(0, 1 / self.output.size.height));
}

- (LTOneShotImageProcessor *)diffusingProcessorWithInput:(LTTexture *)input
                                                  output:(LTTexture *)output {
  return [[LTOneShotImageProcessor alloc]
      initWithVertexSource:[LTPassthroughShaderVsh source]
      fragmentSource:[LTAnisotropicDiffusionFsh source] sourceTexture:input
      auxiliaryTextures:@{[LTAnisotropicDiffusionFsh guideTexture] : self.guide} andOutput:output];
}

- (void)process {
  [self.input executeAndPreserveParameters:^{
    self.input.minFilterInterpolation = LTTextureInterpolationNearest;
    self.input.magFilterInterpolation = LTTextureInterpolationNearest;

    [self.intermediateTexture executeAndPreserveParameters:^{
      self.intermediateTexture.minFilterInterpolation = LTTextureInterpolationNearest;
      self.intermediateTexture.magFilterInterpolation = LTTextureInterpolationNearest;
      [self.horizontalDiffuser process];
      [self.verticalDiffuser process];
    }];
  }];
}

- (void)setRangeSigma:(CGFloat)rangeSigma {
  LTParameterAssert(rangeSigma > 0, @"rangeSigma (%g) must be positive", rangeSigma);
  _rangeSigma = rangeSigma;

  self.horizontalDiffuser[[LTAnisotropicDiffusionFsh rangeSigma]] = @(rangeSigma);
  self.verticalDiffuser[[LTAnisotropicDiffusionFsh rangeSigma]] = @(rangeSigma);
}

- (void)setKernelSize:(NSUInteger)kernelSize {
  LTParameterAssert(kernelSize % 2, @"kernel size (%lu) must be an odd number",
                    (unsigned long)kernelSize);
  LTParameterAssert(kernelSize > 0 && kernelSize <= kKernelSizeUpperBound,
                    @"kernelSize value (%lu) must be in [1, %lu]",
                    (unsigned long)kernelSize, (unsigned long)kKernelSizeUpperBound);
  _kernelSize = kernelSize;

  self.horizontalDiffuser[[LTAnisotropicDiffusionFsh kernelSize]] = @(kernelSize);
  self.verticalDiffuser[[LTAnisotropicDiffusionFsh kernelSize]] = @(kernelSize);
}

@end

NS_ASSUME_NONNULL_END
