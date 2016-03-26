// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRecomposeProcessor.h"

#import <LTKit/LTRandom.h>
#import <objc/runtime.h>
#import <unordered_set>

#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTInverseTransformSampler.h"
#import "LTMultiRectDrawer.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

/// Dimension to recompose across.
typedef NS_ENUM(NSUInteger, LTDecimationDimension) {
  LTDecimationDimensionHorizontal = 0,
  LTDecimationDimensionVertical,
};

@interface LTRecomposeProcessor ()

/// Drawer used to draw multiple rects (pixel rows) into the target.
@property (strong, nonatomic) LTMultiRectDrawer *drawer;

/// Framebuffer referencing the output texture.
@property (strong, nonatomic) LTFbo *outputFbo;

/// Framebuffer referencing the auxiliary texture.
@property (strong, nonatomic) LTFbo *auxiliaryFbo;

/// Input image.
@property (strong, nonatomic) LTTexture *input;

/// Mask image.
@property (strong, nonatomic) LTTexture *mask;

/// Output image.
@property (strong, nonatomic) LTTexture *output;

/// Auxiliary texture used to store the intermediate result of recomposing the first dimension.
@property (strong, nonatomic) LTTexture *auxiliary;

/// Source rects (pixel lines) in input texture coordinates.
@property (strong, nonatomic) NSArray *sourceRects;

/// Target rects (pixel lines) in output texture coordinates.
@property (strong, nonatomic) NSArray *targetRects;

/// Ordered (first to last) indices of rows to remove.
@property (strong, nonatomic) NSArray *rowsDecimationOrder;

/// Ordered (first to last) indices of columns to remove.
@property (strong, nonatomic) NSArray *colsDecimationOrder;

/// The generation id of the mask texture that was used to calculate the decimation order.
@property (nonatomic) id maskTextureGenerationID;

@end

@implementation LTRecomposeProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask output:(LTTexture *)output {
  LTParameterAssert(input.size == output.size, @"Input size must be equal to output size");
  LTParameterAssert(input.size.width >= mask.size.width && input.size.height >= mask.size.height,
                    @"Input size must be greater or equal to mask size");

  if (self = [super init]) {
    self.drawer = [[LTMultiRectDrawer alloc] initWithProgram:[self createProgram]
                                               sourceTexture:input];

    self.input = input;
    self.mask = mask;
    self.output = output;
    self.auxiliary = [LTTexture textureWithPropertiesOf:output];

    self.outputFbo = [[LTFboPool currentPool] fboWithTexture:output];
    self.auxiliaryFbo = [[LTFboPool currentPool] fboWithTexture:self.auxiliary];

    self.samplerFactory = [[LTInverseTransformSamplerFactory alloc] init];
  }
  return self;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                  fragmentSource:[LTPassthroughShaderFsh source]];
}

#pragma mark -
#pragma mark Mask
#pragma mark -

- (Floats)calculateMaskFrequenciesForDimension:(LTDecimationDimension)dimension {
  static const double kBlurSize = 21;
  static const float kGamma = 1.8;

  // Smooth the summed mask.
  cv::Mat1f sum = [self reducedSumOfMaskForDimension:dimension];
  cv::Mat1f smoothedSum(sum.size());
  cv::GaussianBlur(sum, smoothedSum, cv::Size(0, 0), kBlurSize);

  // Resize the smoothed sum to match the target size, in case the mask was smaller than the input.
  CGFloat reducedSize = [self reducedInputSizeForDecimationDimension:dimension];
  cv::Size targetSize = dimension == LTDecimationDimensionHorizontal ?
      cv::Size(reducedSize, 1) : cv::Size(1, reducedSize);
  cv::resize(smoothedSum, smoothedSum, targetSize);

  // Inverse values so a white mask will cause less throws than black, and make sure that each line
  // has a minimal small frequency so it will be able to be selected when sampling.
  float maxValue = *std::max_element(smoothedSum.begin(), smoothedSum.end()) + 1;
  smoothedSum = maxValue - smoothedSum;

  /// Apply a gamma to make selected areas stronger.
  std::transform(smoothedSum.begin(), smoothedSum.end(), smoothedSum.begin(), [maxValue](float v) {
    return std::pow(v / maxValue, kGamma) * maxValue;
  });

  return Floats(smoothedSum.begin(), smoothedSum.end());
}

- (cv::Mat1f)reducedSumOfMaskForDimension:(LTDecimationDimension)dimension {
  // Sum the mask to get a 1D signal.
  __block cv::Mat1f sum;
  [self.mask mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    cv::reduce(mapped, sum, dimension, CV_REDUCE_SUM, CV_32F);
  }];

  // "Invert" the sum, to correspond to an inverted mask. Note that in case the mask is of byte
  // precision, the reduce-sum will sum float values in range [0,255], so it is necessary to divide
  // by 255 in order to have similar behaviors for all mask precision types.
  float maxMaskPixelValue = (self.mask.dataType == LTGLPixelDataTypeUnorm) ? UCHAR_MAX : 1;
  float maxReducedCellValue = dimension == LTDecimationDimensionHorizontal ?
      self.mask.size.height : self.mask.size.width;
  std::transform(sum.begin(), sum.end(), sum.begin(),
                 [maxReducedCellValue, maxMaskPixelValue](float value) {
    return maxReducedCellValue - value / maxMaskPixelValue;
  });

  return sum;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  [self updateDecimationOrderIfNeeded];

  [self updateRectsForLinesToDecimateInDimension:LTDecimationDimensionHorizontal];
  [self.auxiliaryFbo clearWithColor:LTVector4::zeros()];
  [self.drawer setSourceTexture:self.input];
  [self.drawer drawRotatedRects:self.targetRects inFramebuffer:self.auxiliaryFbo
               fromRotatedRects:self.sourceRects];

  [self updateRectsForLinesToDecimateInDimension:LTDecimationDimensionVertical];
  [self.outputFbo clearWithColor:LTVector4::zeros()];
  [self.drawer setSourceTexture:self.auxiliary];
  [self.drawer drawRotatedRects:self.targetRects inFramebuffer:self.outputFbo
               fromRotatedRects:self.sourceRects];
}

- (void)updateDecimationOrderIfNeeded {
  if ([self.maskTextureGenerationID isEqual:self.mask.generationID]) {
    return;
  }

  self.maskTextureGenerationID = self.mask.generationID;
  self.rowsDecimationOrder =
      [self calculateDecimationOrderForDimension:LTDecimationDimensionVertical];
  self.colsDecimationOrder =
      [self calculateDecimationOrderForDimension:LTDecimationDimensionHorizontal];
}

- (NSArray *)calculateDecimationOrderForDimension:(LTDecimationDimension)dimension {
  Floats frequencies = [self calculateMaskFrequenciesForDimension:dimension];
  return [self calculateDecimationOrderForDimension:dimension usingFrequencies:&frequencies];
}

- (NSArray *)calculateDecimationOrderForDimension:(LTDecimationDimension)dimension
                                 usingFrequencies:(Floats *)frequencies {
  NSMutableArray *decimationOrder = [NSMutableArray array];

  // Sample from the distribution with no repetitions. We're using a constant seed since we prefer
  // something pseudo-random, that will generate the same decimation under the same parameters.
  // This is important so users can duplicate a previous result.
  CGFloat reducedSize = [self reducedInputSizeForDecimationDimension:dimension];
  static const NSUInteger kRandomSeed = 100;
  LTRandom *random = [[LTRandom alloc] initWithSeed:kRandomSeed];
  while (decimationOrder.count < reducedSize) {
    id<LTDistributionSampler> sampler =
        [self.samplerFactory samplerWithFrequencies:*frequencies random:random];
    NSUInteger samplesRequired = reducedSize - decimationOrder.count;

    // The order of the unique samples is preserved, so high-probability lines for decimation will
    // be decimated first (since they will probably be sampled first). This also aids testing since
    // the order of samples are not shuffeled.
    Floats uniqueSamples = [self uniqueSamples:[sampler sample:samplesRequired]];
    for (const float &sample : uniqueSamples) {
      [decimationOrder addObject:@(sample)];
      (*frequencies)[(uint)sample] = 0.f;
    }
  }

  return [decimationOrder copy];
}

- (Floats)uniqueSamples:(const Floats &)samples {
  Floats uniqueSamples;
  std::unordered_set<float> set;
  for (const float &sample : samples) {
    if (!set.count(sample)) {
      uniqueSamples.push_back(sample);
      set.insert(sample);
    }
  }
  return uniqueSamples;
}

- (void)updateRectsForLinesToDecimateInDimension:(LTDecimationDimension)dimension {
  NSRange decimationRange = NSMakeRange(0, [self linesToDecimateForDimension:dimension]);
  NSArray *decimationOrder =
      [[self decimationOrderForDimension:dimension] subarrayWithRange:decimationRange];
  NSSet *linesToThrow = [NSSet setWithArray:decimationOrder];

  NSMutableArray *imageCoordinates = [NSMutableArray array];
  CGFloat reducedInputSize = [self reducedInputSizeForDecimationDimension:dimension];
  for (NSUInteger i = 0; i < reducedInputSize; ++i) {
    if ([linesToThrow containsObject:@(i)]) {
      continue;
    }
    [imageCoordinates addObject:@(i)];
  }

  NSMutableArray *sourceRects = [NSMutableArray array];
  NSMutableArray *targetRects = [NSMutableArray array];

  // Start at the origin of the rect with the number of recomposed lines, centered at the center of
  // the output texture.
  NSUInteger offset = std::floor((reducedInputSize - imageCoordinates.count) / 2.0);
  [imageCoordinates enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *) {
    [sourceRects addObject:[self sourceRectForIndex:obj.unsignedIntegerValue dimension:dimension]];
    [targetRects addObject:[self targetRectForIndex:offset + idx dimension:dimension]];
  }];

  self.sourceRects = [sourceRects copy];
  self.targetRects = [targetRects copy];
}

- (LTRotatedRect *)sourceRectForIndex:(NSUInteger)index dimension:(LTDecimationDimension)dimension {
  switch (dimension) {
    case LTDecimationDimensionHorizontal:
      return [LTRotatedRect rect:CGRectMake(index, 0, 1, self.input.size.height)];
    case LTDecimationDimensionVertical:
      return [LTRotatedRect rect:CGRectMake(0, index, self.input.size.width, 1)];
  }
}

- (LTRotatedRect *)targetRectForIndex:(NSUInteger)index dimension:(LTDecimationDimension)dimension {
  switch (dimension) {
    case LTDecimationDimensionHorizontal:
      return [LTRotatedRect rect:CGRectMake(index, 0, 1, self.input.size.height)];
    case LTDecimationDimensionVertical:
      return [LTRotatedRect rect:CGRectMake(0, index, self.input.size.width, 1)];
  }
}

#pragma mark -
#pragma mark Dimension-Specific Properties
#pragma mark -

- (NSArray *)decimationOrderForDimension:(LTDecimationDimension)dimension {
  switch (dimension) {
    case LTDecimationDimensionHorizontal:
      return self.colsDecimationOrder;
    case LTDecimationDimensionVertical:
      return self.rowsDecimationOrder;
  }
}

- (NSUInteger)linesToDecimateForDimension:(LTDecimationDimension)dimension {
  switch (dimension) {
    case LTDecimationDimensionHorizontal:
      return self.colsToDecimate;
    case LTDecimationDimensionVertical:
      return self.rowsToDecimate;
  }
}

- (CGFloat)reducedInputSizeForDecimationDimension:(LTDecimationDimension)dimension {
  switch (dimension) {
    case LTDecimationDimensionHorizontal:
      return self.input.size.width;
    case LTDecimationDimensionVertical:
      return self.input.size.height;
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGRect)recomposedRect {
  NSUInteger recomposedRows = self.input.size.height - self.rowsToDecimate;
  NSUInteger recomposedCols = self.input.size.width - self.colsToDecimate;
  NSUInteger rowOffset = std::floor(self.input.size.height - recomposedRows) / 2.0;
  NSUInteger colOffset = std::floor(self.input.size.width - recomposedCols) / 2.0;
  return CGRectMake(colOffset, rowOffset, recomposedCols, recomposedRows);
}

- (void)setRowsToDecimate:(NSUInteger)rowsToDecimate {
  LTParameterAssert(rowsToDecimate <= self.input.size.height);
  _rowsToDecimate = rowsToDecimate;
}

- (void)setColsToDecimate:(NSUInteger)colsToDecimate {
  LTParameterAssert(colsToDecimate <= self.input.size.width);
  _colsToDecimate = colsToDecimate;
}

@end

@implementation LTRecomposeProcessor (ForTesting)

- (void)setSamplerFactory:(id<LTDistributionSamplerFactory>)samplerFactory {
  objc_setAssociatedObject(self, @selector(samplerFactory), samplerFactory,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<LTDistributionSamplerFactory>)samplerFactory {
  return objc_getAssociatedObject(self, @selector(samplerFactory));
}

@end
