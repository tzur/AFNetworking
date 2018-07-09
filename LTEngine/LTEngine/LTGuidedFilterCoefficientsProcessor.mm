// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTGuidedFilterCoefficientsProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTOneShotImageProcessor.h"
#import "LTShaderStorage+LTGuidedFilterBlurNormalizeFsh.h"
#import "LTShaderStorage+LTGuidedFilterDownsampleFsh.h"
#import "LTShaderStorage+LTGuidedFilterMultiplyFsh.h"
#import "LTShaderStorage+LTGuidedFilterScaleFsh.h"
#import "LTShaderStorage+LTGuidedFilterShiftFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTGuidedFilterCoefficientsProcessor () {
  // Array of kernel sizes to smooth with.
  std::vector<NSUInteger> _kernelSizes;
}

/// Processor's input image.
@property (readonly, nonatomic) LTTexture *input;

/// Processor's guide image.
@property (readonly, nonatomic) LTTexture *guide;

/// Processor's output - scale coefficients after averaging.
@property (readonly, nonatomic) NSArray<LTTexture *> *scaleCoefficients;

/// Processor's output - shift coefficients after averaging.
@property (readonly, nonatomic) NSArray<LTTexture *> *shiftCoefficients;

/// Downsized input generated from input.
@property (readonly, nonatomic) LTTexture *downsizedInput;

/// Downsized guide.
@property (readonly, nonatomic) LTTexture *downsizedGuide;

/// Squared values of downsized guide.
@property (readonly, nonatomic) LTTexture *squaredDownsizedGuide;

/// Downsized input multiplied by the guide.
@property (readonly, nonatomic) LTTexture *downsizedInputMultipliedByGuide;

/// Averaged downsized input.
@property (readonly, nonatomic) LTTexture *meanDownsizedInput;

/// Averaged downsized guide.
@property (readonly, nonatomic) LTTexture *meanDownsizedGuide;

/// Averaged squared downsized guide.
@property (readonly, nonatomic) LTTexture *meanSquaredDownsizedGuide;

/// Averaged downsized input multiplied by the guide.
@property (readonly, nonatomic) LTTexture *meanDownsizedInputMultipliedByGuide;

/// Blur normalization texture.
@property (readonly, nonatomic, nullable) LTTexture *blurNormalizationTexture;

/// Guided filter scale coefficients (a matrix in the paper).
@property (readonly, nonatomic) LTTexture *scaleTexture;

/// Guided filter shift coefficients (b matrix in the paper).
@property (readonly, nonatomic) LTTexture *shiftTexture;

@end

@implementation LTGuidedFilterCoefficientsProcessor

- (instancetype)initWithInput:(LTTexture *)input guide:(LTTexture *)guide
            scaleCoefficients:(NSArray<LTTexture *> *)scaleCoefficients
            shiftCoefficients:(NSArray<LTTexture *> *)shiftCoefficients
                  kernelSizes:(const std::vector<NSUInteger> &)kernelSizes {
  [LTGuidedFilterCoefficientsProcessor validateInput:input guide:guide
                                   scaleCoefficients:scaleCoefficients
                                   shiftCoefficients:shiftCoefficients
                                         kernelSizes:kernelSizes];
  if (self = [super init]) {
    _input = input;
    _guide = guide;
    _scaleCoefficients = scaleCoefficients;
    _shiftCoefficients = shiftCoefficients;
    _kernelSizes = kernelSizes;
    [self createIntermediateTextures];

    [self resetInputModel];
  }
  return self;
}

+ (void)validateInput:(LTTexture *)input guide:(LTTexture *)guide
    scaleCoefficients:(NSArray<LTTexture *> *)scaleCoefficients
    shiftCoefficients:(NSArray<LTTexture *> *)shiftCoefficients
          kernelSizes:(const std::vector<NSUInteger> &)kernelSizes  {
  LTParameterAssert(input);
  LTParameterAssert((input.components == LTGLPixelComponentsR) ||
                    (input.components == LTGLPixelComponentsRGBA),
                    @"Input texture channels count(%lu) must be 1 or 4",
                    (unsigned long)input.pixelFormat.channels);
  LTParameterAssert((guide.components == LTGLPixelComponentsR) ||
                    (guide.components == LTGLPixelComponentsRGBA),
                    @"Guide texture channels count(%lu) must be 1 or 4",
                    (unsigned long)guide.pixelFormat.channels);
  LTParameterAssert(!((guide.components == LTGLPixelComponentsR) &&
                      (input.components == LTGLPixelComponentsRGBA)),
                    @"R guide and RGBA input combination is not supported");

  [LTGuidedFilterCoefficientsProcessor validateScaleCoefficients:scaleCoefficients
                                               shiftCoefficients:shiftCoefficients
                                                           input:input
                                                           guide:guide];

  [LTGuidedFilterCoefficientsProcessor validateKernelSizes:kernelSizes
                                         withExpectedCount:scaleCoefficients.count];
}

+ (void)validateScaleCoefficients:(NSArray<LTTexture *> *)scaleCoefficients
                shiftCoefficients:(NSArray<LTTexture *> *)shiftCoefficients
                            input:(LTTexture *)input guide:(LTTexture *)guide {
  LTParameterAssert(scaleCoefficients.count, @"scaleCoefficients array provided has a zero length");
  LTParameterAssert(shiftCoefficients.count, @"shiftCoefficients array provided has a zero length");
  LTParameterAssert(scaleCoefficients.count == shiftCoefficients.count,
                    @"Coefficients arrays must be of the same length, got %lu elements in "
                    @"scaleCoefficients and %lu elements in shiftCoefficients",
                    (unsigned long)scaleCoefficients.count, (unsigned long)shiftCoefficients.count);

  for (NSUInteger i = 0; i < scaleCoefficients.count; ++i) {
    LTParameterAssert(scaleCoefficients[i].size == scaleCoefficients.firstObject.size,
                      @"All coefficients texture must be of the same size, "
                      @"got scale coefficients[%lu] size (%@), first scale coefficients size (%@)",
                      (unsigned long)i,
                      NSStringFromCGSize(scaleCoefficients[i].size),
                      NSStringFromCGSize(scaleCoefficients.firstObject.size));
    LTParameterAssert(shiftCoefficients[i].size == scaleCoefficients.firstObject.size,
                      @"All coefficients texture pairs must be of the same size, "
                      @"got shift coefficients[%lu] size (%@), first scale coefficients size (%@)",
                      (unsigned long)i,
                      NSStringFromCGSize(shiftCoefficients[i].size),
                      NSStringFromCGSize(scaleCoefficients.firstObject.size));
    LTParameterAssert(scaleCoefficients[i].pixelFormat.channels == input.pixelFormat.channels,
                      @"scaleCoefficients[%lu] channels count(%lu) must be the as same as of "
                      @"input(%lu)",
                      (unsigned long)i, (unsigned long)scaleCoefficients[i].pixelFormat.channels,
                      (unsigned long)input.pixelFormat.channels);
    LTParameterAssert(shiftCoefficients[i].pixelFormat.channels == input.pixelFormat.channels,
                      @"shiftCoefficients[%lu] channels count(%lu) must be the as same as of "
                      @"input(%lu)",
                      (unsigned long)i, (unsigned long)shiftCoefficients[i].pixelFormat.channels,
                      (unsigned long)input.pixelFormat.channels);

    if (input != guide) {
      LTParameterAssert(scaleCoefficients[i].dataType == LTGLPixelDataType16Float,
                        @"scaleCoefficients[%lu] pixel format(%@) must be half float",
                        (unsigned long)i, scaleCoefficients[i].pixelFormat);
      LTParameterAssert(shiftCoefficients[i].dataType == LTGLPixelDataType16Float,
                        @"shiftCoefficients[%lu] pixel format(%@) must be half float",
                        (unsigned long)i, shiftCoefficients[i].pixelFormat);
    }
  }
}

+ (void)validateKernelSizes:(const std::vector<NSUInteger> &)kernelSizes
          withExpectedCount:(NSUInteger)expectedCount{
  LTParameterAssert(kernelSizes.size(), @"kernelSizes array provided has a zero length");
  LTParameterAssert(expectedCount == kernelSizes.size(),
                    @"kernelSizes array(%lu) must be of the same length as the coefficients arrays"
                    @"arrays(%lu)", (unsigned long)kernelSizes.size(),
                    (unsigned long)expectedCount);
  for (NSUInteger kernelSize: kernelSizes) {
    LTParameterAssert(kernelSize % 2 == 1, @"All kernelSizes must be odd, got %lu",
                      (unsigned long)kernelSize);
    LTParameterAssert((kernelSize >= 3) && (kernelSize <= 999),
                      @"All kernelSizes must be in [3, 999], got %lu",
                      (unsigned long)kernelSize);
  }
}

- (void)createIntermediateTextures {
  _downsizedGuide = [LTTexture textureWithPropertiesOf:self.scaleCoefficients.firstObject];
  _meanDownsizedGuide = [LTTexture textureWithPropertiesOf:self.downsizedGuide];
  _squaredDownsizedGuide =  [LTTexture textureWithPropertiesOf:self.downsizedGuide];
  _meanSquaredDownsizedGuide = [LTTexture textureWithPropertiesOf:self.downsizedGuide];
  if (self.input != self.guide) {
    _downsizedInput = [LTTexture textureWithSize:self.scaleCoefficients.firstObject.size
                                     pixelFormat:self.downsizedGuide.pixelFormat
                                  allocateMemory:YES];
    _meanDownsizedInput = [LTTexture textureWithPropertiesOf:self.downsizedInput];
    _downsizedInputMultipliedByGuide = [LTTexture textureWithPropertiesOf:self.downsizedGuide];
    _meanDownsizedInputMultipliedByGuide = [LTTexture textureWithPropertiesOf:self.downsizedGuide];
  } else {
    _downsizedInput = self.downsizedGuide;
    _meanDownsizedInput = self.meanDownsizedGuide;
    _downsizedInputMultipliedByGuide = self.squaredDownsizedGuide;
    _meanDownsizedInputMultipliedByGuide = self.meanSquaredDownsizedGuide;
  }
  _scaleTexture = [LTTexture textureWithPropertiesOf:self.scaleCoefficients.firstObject];
  _shiftTexture = [LTTexture textureWithPropertiesOf:self.scaleTexture];

  if (self.input.components != LTGLPixelComponentsRGBA) {
    _blurNormalizationTexture = [LTTexture textureWithPropertiesOf:self.scaleTexture];
  }
}

- (void)process {
  BOOL useGuideLuminance = ((self.guide.components == LTGLPixelComponentsRGBA) &&
                            (self.input.components == LTGLPixelComponentsR));

  [self downsampleImage:self.guide output:self.downsizedGuide useLuminanceOnly:useGuideLuminance];
  [self multiplyImage:self.downsizedGuide withImage:self.downsizedGuide
               output:self.squaredDownsizedGuide];
  if (self.input != self.guide) {
    [self downsampleImage:self.input output:self.downsizedInput useLuminanceOnly:NO];
    [self multiplyImage:self.downsizedInput withImage:self.downsizedGuide
                 output:self.downsizedInputMultipliedByGuide];
  }

  for (NSUInteger i = 0; i < self.scaleCoefficients.count; ++i) {
    CGFloat ratio = std::max(self.input.size / self.scaleCoefficients[i].size);
    CGFloat kernelSize = _kernelSizes[i];
    CGFloat scaledKernelSize = [self roundToOdd:kernelSize / ratio];

    if (self.blurNormalizationTexture) {
      [self.blurNormalizationTexture clearColor:LTVector4::ones()];
      [self nonNormalizedBoxFilterWithInput:self.blurNormalizationTexture
                                     output:self.blurNormalizationTexture
                                 kernelSize:scaledKernelSize];
    }

    if (self.input != self.guide) {
      [self boxFilterWithInput:self.downsizedInput output:self.meanDownsizedInput
                    kernelSize:scaledKernelSize];
      [self boxFilterWithInput:self.downsizedInputMultipliedByGuide
                        output:self.meanDownsizedInputMultipliedByGuide
                    kernelSize:scaledKernelSize];
    }

    [self boxFilterWithInput:self.squaredDownsizedGuide output:self.meanSquaredDownsizedGuide
                  kernelSize:scaledKernelSize];

    [self boxFilterWithInput:self.downsizedGuide output:self.meanDownsizedGuide
                  kernelSize:scaledKernelSize];

    [self calculateScale];
    [self calculateShift];

    [self boxFilterWithInput:self.scaleTexture output:self.scaleCoefficients[i]
                  kernelSize:scaledKernelSize];
    [self boxFilterWithInput:self.shiftTexture output:self.shiftCoefficients[i]
                  kernelSize:scaledKernelSize];
  }
}

- (void)downsampleImage:(LTTexture *)input output:(LTTexture *)output
       useLuminanceOnly:(BOOL)useLuminanceOnly {
  LTOneShotImageProcessor *downsampleProcessor =
      [[LTOneShotImageProcessor alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                             fragmentSource:[LTGuidedFilterDownsampleFsh source]
                                                      input:input andOutput:output];
  downsampleProcessor[[LTGuidedFilterDownsampleFsh useLuminance]] = @(useLuminanceOnly);
  downsampleProcessor[[LTGuidedFilterDownsampleFsh shiftValues]] =
      @(output.dataType == LTGLPixelDataType16Float);
  [downsampleProcessor process];
}

- (void)multiplyImage:(LTTexture *)input1 withImage:(LTTexture *)input2 output:(LTTexture *)output {
  NSDictionary<NSString *, LTTexture *> *auxiliaryTextures =
      @{[LTGuidedFilterMultiplyFsh secondTexture]: input2};
  LTOneShotImageProcessor *multiplyProcessor =
      [[LTOneShotImageProcessor alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                             fragmentSource:[LTGuidedFilterMultiplyFsh source]
                                              sourceTexture:input1
                                          auxiliaryTextures:auxiliaryTextures
                                                  andOutput:output];
  multiplyProcessor[[LTGuidedFilterMultiplyFsh sourceTextureSingleChannel]] =
      @(input1.components == LTGLPixelComponentsR);
  multiplyProcessor[[LTGuidedFilterMultiplyFsh secondTextureSingleChannel]] =
      @(input2.components == LTGLPixelComponentsR);
  [multiplyProcessor process];
}

- (CGFloat)roundToOdd:(CGFloat)value {
  return std::floor(value / 2) * 2 + 1;
}

- (void)calculateScale {
  NSDictionary<NSString *, LTTexture *> *auxiliaryTextures = @{
    [LTGuidedFilterScaleFsh meanSquareGuideTexture]: self.meanSquaredDownsizedGuide,
    [LTGuidedFilterScaleFsh meanGuideTexture]: self.meanDownsizedGuide,
    [LTGuidedFilterScaleFsh meanInputMultipliedByGuideTexture]:
        self.meanDownsizedInputMultipliedByGuide
  };

  LTOneShotImageProcessor *scaleProcessor =
      [[LTOneShotImageProcessor alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                             fragmentSource:[LTGuidedFilterScaleFsh source]
                                              sourceTexture:self.meanDownsizedInput
                                          auxiliaryTextures:auxiliaryTextures
                                                  andOutput:self.scaleTexture];
  scaleProcessor[[LTGuidedFilterScaleFsh smoothingDegree]] = @(self.smoothingDegree);
  [scaleProcessor process];
}

- (void)calculateShift {
  NSDictionary<NSString *, LTTexture *> *auxiliaryTextures = @{
    [LTGuidedFilterShiftFsh scaleTexture]: self.scaleTexture,
    [LTGuidedFilterShiftFsh meanGuideTexture]: self.meanDownsizedGuide
  };
  LTOneShotImageProcessor *shiftProcessor =
      [[LTOneShotImageProcessor alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                             fragmentSource:[LTGuidedFilterShiftFsh source]
                                              sourceTexture:self.meanDownsizedInput
                                          auxiliaryTextures:auxiliaryTextures
                                                  andOutput:self.shiftTexture];
  shiftProcessor[[LTGuidedFilterShiftFsh shiftValues]] =
      @(self.shiftTexture.dataType == LTGLPixelDataType16Float);
  [shiftProcessor process];
}

- (void)boxFilterWithInput:(LTTexture *)input output:(LTTexture *)output
                kernelSize:(CGFloat)kernelSize {
  [self nonNormalizedBoxFilterWithInput:input output:output kernelSize:kernelSize];
  [self normalizeTexture:output];
}

- (void)nonNormalizedBoxFilterWithInput:(LTTexture *)input output:(LTTexture *)output
                             kernelSize:(CGFloat)kernelSize {
  [input mappedCIImage:^(CIImage *image) {
    [output drawWithCoreImage:^CIImage *{
      auto filterParameters = @{kCIInputRadiusKey: @(kernelSize)};
      return [[image
          imageByApplyingFilter:@"CIBoxBlur" withInputParameters:filterParameters]
          imageByCroppingToRect:image.extent];
    }];
  }];
}

// Since CIBoxBlur uses zero as boundary condition, normalizing by the fourth channel is needed
// (as it acts as a binary mask blurred with the same kernel).
- (void)normalizeTexture:(LTTexture *)texture {
  LTOneShotImageProcessor *processor =
      [[LTOneShotImageProcessor alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                             fragmentSource:[LTGuidedFilterBlurNormalizeFsh source]
                                                      input:texture andOutput:texture];
  if (texture.components != LTGLPixelComponentsRGBA) {
    [processor setAuxiliaryTexture:self.blurNormalizationTexture
                          withName:[LTGuidedFilterBlurNormalizeFsh normalizationMask]];
    processor[[LTGuidedFilterBlurNormalizeFsh useExternalMask]] = @YES;
  } else {
    processor[[LTGuidedFilterBlurNormalizeFsh useExternalMask]] = @NO;
  }
  processor[[LTGuidedFilterBlurNormalizeFsh clampMaximum]] =
      @(texture.dataType == LTGLPixelDataType8Unorm);

  [processor process];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(CGFloat, smoothingDegree, SmoothingDegree, 1e-7, 1, 0.01);

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTGuidedFilterCoefficientsProcessor, smoothingDegree)
    ]];
  });
  return properties;
}

@end

NS_ASSUME_NONNULL_END
