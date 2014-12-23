// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRecomposeProcessor.h"

#import <objc/runtime.h>
#import <unordered_set>

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTInverseTransformSampler.h"
#import "LTMultiRectDrawer.h"
#import "LTProgram.h"
#import "LTRandom.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTRecomposeProcessor ()

/// Drawer used to draw multiple rects (pixel rows) into the target.
@property (strong, nonatomic) LTMultiRectDrawer *drawer;

/// Framebuffer referencing the output texture.
@property (strong, nonatomic) LTFbo *fbo;

/// Input image.
@property (strong, nonatomic) LTTexture *input;

/// Mask image.
@property (strong, nonatomic) LTTexture *mask;

/// Output image.
@property (strong, nonatomic) LTTexture *output;

/// Source rects (pixel lines) in input texture coordinates.
@property (strong, nonatomic) NSArray *sourceRects;

/// Target rects (pixel lines) in output texture coordinates.
@property (strong, nonatomic) NSArray *targetRects;

/// Ordered (first to last) indices of lines (vertical or horizontal, depending on \c
/// decimationDimensionSize) to remove.
@property (strong, nonatomic) NSArray *decimationOrder;

/// Size of the input image of the dimension the processor decimates.
@property (readonly, nonatomic) CGFloat decimationDimensionSize;

/// The generation id of the mask texture that was used to calculate the decimation order.
@property (nonatomic) NSUInteger maskTextureGenerationID;

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
    self.fbo = [[LTFbo alloc] initWithTexture:output];

    self.input = input;
    self.mask = mask;
    self.output = output;

    self.samplerFactory = [[LTInverseTransformSamplerFactory alloc] init];
    self.decimationDimension = [self defaultDecimationDimension];
  }
  return self;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                  fragmentSource:[LTPassthroughShaderFsh source]];
}

- (LTRecomposeDecimationDimension)defaultDecimationDimension {
  return self.input.size.width > self.input.size.height ?
      LTRecomposeDecimationDimensionHorizontal : LTRecomposeDecimationDimensionVertical;
}

#pragma mark -
#pragma mark Mask
#pragma mark -

- (Floats)calculateMaskFrequencies {
  static const double kBlurSize = 21;
  static const float kGamma = 1.8;

  // Smooth the summed mask.
  cv::Mat1f sum = [self reducedSumOfMask];
  cv::Mat1f smoothedSum(sum.size());
  cv::GaussianBlur(sum, smoothedSum, cv::Size(0, 0), kBlurSize);

  // Resize the smoothed sum to match the target size, in case the mask was smaller than the input.
  cv::Size targetSize = self.decimationDimension == LTRecomposeDecimationDimensionHorizontal ?
      cv::Size(self.decimationDimensionSize, 1) : cv::Size(1, self.decimationDimensionSize);
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

- (cv::Mat1f)reducedSumOfMask {
  // Sum the mask to get a 1D signal.
  __block cv::Mat1f sum;
  [self.mask mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    cv::reduce(mapped, sum, self.decimationDimension, CV_REDUCE_SUM, CV_32F);
  }];

  // "Invert" the sum, to correspond to an inverted mask. Note that in case the mask is of byte
  // precision, the reduce-sum will sum float values in range [0,255], so it is necessary to divide
  // by 255 in order to have similar behaviors for all mask precision types.
  float maxMaskPixelValue = (self.mask.precision == LTTexturePrecisionByte) ? UCHAR_MAX : 1;
  float maxReducedCellValue = self.decimationDimension == LTRecomposeDecimationDimensionHorizontal ?
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
  [self updateRectsForLinesToDecimate];

  [self.fbo clearWithColor:LTVector4Zero];
  [self.drawer drawRotatedRects:self.targetRects inFramebuffer:self.fbo
               fromRotatedRects:self.sourceRects];
}

- (void)updateDecimationOrderIfNeeded {
  if (self.maskTextureGenerationID == self.mask.generationID) {
    return;
  }

  self.maskTextureGenerationID = self.mask.generationID;
  Floats frequencies = [self calculateMaskFrequencies];
  self.decimationOrder = [self calculateDecimationOrderUsingFrequencies:&frequencies];
}

- (CGFloat)decimationDimensionSize {
  switch (self.decimationDimension) {
    case LTRecomposeDecimationDimensionHorizontal:
      return self.input.size.width;
    case LTRecomposeDecimationDimensionVertical:
      return self.input.size.height;
  }
}

- (NSArray *)calculateDecimationOrderUsingFrequencies:(Floats *)frequencies {
  NSMutableArray *decimationOrder = [NSMutableArray array];

  // Sample from the distribution with no repetitions. We're using a constant seed since we prefer
  // something pseudo-random, that will generate the same decimation under the same parameters.
  // This is important so users can duplicate a previous result.
  static const NSUInteger kRandomSeed = 100;
  LTRandom *random = [[LTRandom alloc] initWithSeed:kRandomSeed];
  while (decimationOrder.count < self.decimationDimensionSize) {
    id<LTDistributionSampler> sampler =
        [self.samplerFactory samplerWithFrequencies:*frequencies random:random];
    NSUInteger samplesRequired = self.decimationDimensionSize - decimationOrder.count;

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

- (void)updateRectsForLinesToDecimate {
  NSSet *linesToThrow = [NSSet setWithArray:[self.decimationOrder
                                             subarrayWithRange:NSMakeRange(0,
                                                                           self.linesToDecimate)]];

  NSMutableArray *imageCoordinates = [NSMutableArray array];
  for (NSUInteger i = 0; i < self.decimationDimensionSize; ++i) {
    if ([linesToThrow containsObject:@(i)]) {
      continue;
    }
    [imageCoordinates addObject:@(i)];
  }

  NSMutableArray *sourceRects = [NSMutableArray array];
  NSMutableArray *targetRects = [NSMutableArray array];

  // Start at the origin of the rect with the number of recomposed lines, centered at the center of
  // the output texture.
  NSUInteger offset = std::floor((self.decimationDimensionSize - imageCoordinates.count) / 2.0);
  [imageCoordinates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *) {
    [sourceRects addObject:[self sourceRectForIndex:[obj unsignedIntegerValue]]];
    [targetRects addObject:[self targetRectForIndex:offset + idx]];
  }];

  self.sourceRects = [sourceRects copy];
  self.targetRects = [targetRects copy];
}

- (LTRotatedRect *)sourceRectForIndex:(NSUInteger)index {
  switch (self.decimationDimension) {
    case LTRecomposeDecimationDimensionHorizontal:
      return [LTRotatedRect rect:CGRectMake(index, 0, 1, self.input.size.height)];
    case LTRecomposeDecimationDimensionVertical:
      return [LTRotatedRect rect:CGRectMake(0, index, self.input.size.width, 1)];
  }
}

- (LTRotatedRect *)targetRectForIndex:(NSUInteger)index {
  switch (self.decimationDimension) {
    case LTRecomposeDecimationDimensionHorizontal:
      return [LTRotatedRect rect:CGRectMake(index, 0, 1, self.input.size.height)];
    case LTRecomposeDecimationDimensionVertical:
      return [LTRotatedRect rect:CGRectMake(0, index, self.input.size.width, 1)];
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGRect)recomposedRect {
  NSUInteger recomposedLines = self.decimationDimensionSize - self.linesToDecimate;
  NSUInteger offset = std::floor(self.decimationDimensionSize - recomposedLines) / 2.0;
  switch (self.decimationDimension) {
    case LTRecomposeDecimationDimensionHorizontal:
      return CGRectMake(offset, 0, recomposedLines, self.input.size.height);
    case LTRecomposeDecimationDimensionVertical:
      return CGRectMake(0, offset, self.input.size.width, recomposedLines);
  }
}

- (void)setDecimationDimension:(LTRecomposeDecimationDimension)decimationDimension {
  _decimationDimension = decimationDimension;
  self.linesToDecimate = std::min(self.linesToDecimate,
                                  (NSUInteger)self.decimationDimensionSize);
  self.decimationOrder = nil;
}

- (void)setLinesToDecimate:(NSUInteger)linesToDecimate {
  LTParameterAssert(linesToDecimate <= self.decimationDimensionSize);
  _linesToDecimate = linesToDecimate;
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
