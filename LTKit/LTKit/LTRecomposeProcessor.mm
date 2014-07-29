// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRecomposeProcessor.h"

#import <objc/runtime.h>

#import "LTCGExtensions.h"
#import "LTInverseTransformSampler.h"
#import "LTMultiRectDrawer.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"
#import "LTTextureFbo.h"

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

@end

@implementation LTRecomposeProcessor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask output:(LTTexture *)output {
  LTParameterAssert(input.size == output.size, @"Input size must be equal to output size");
  LTParameterAssert(input.size == mask.size, @"Input size must be equal to mask size");

  if (self = [super init]) {
    self.drawer = [[LTMultiRectDrawer alloc] initWithProgram:[self createProgram]
                                               sourceTexture:input];
    self.fbo = [[LTTextureFbo alloc] initWithTexture:output];

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

- (void)setMaskUpdated {
  self.decimationOrder = nil;
}

- (Floats)calculateMaskFrequencies {
  __block cv::Mat1f sum;

  // Sum the mask to get a 1D signal.
  [self.mask mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    cv::reduce(mapped, sum, self.decimationDimension, CV_REDUCE_SUM, CV_32F);
  }];

  static const double kBlurSize = 21;
  static const float kEpsilon = 1;

  // Smooth the summed mask.
  cv::Mat1f smoothedSum(sum.size());
  cv::GaussianBlur(sum, smoothedSum, cv::Size(0, 0), kBlurSize);

  // Get maximal value.
  float maxValue = *std::max_element(smoothedSum.begin(), smoothedSum.end());

  // Inverse values so a white mask will cause less throws than black, and make sure that each line
  // has a minimal small frequency so it will be able to be selected when sampling.
  smoothedSum = maxValue - smoothedSum + kEpsilon;

  return Floats(smoothedSum.begin(), smoothedSum.end());
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  [self updateDecimationOrderIfNeeded];
  [self updateRectsForLinesToDecimate];

  [self.drawer drawRotatedRects:self.targetRects inFramebuffer:self.fbo
               fromRotatedRects:self.sourceRects];
}

- (void)updateDecimationOrderIfNeeded {
  if (!self.decimationOrder) {
    Floats frequencies = [self calculateMaskFrequencies];
    self.decimationOrder = [self calculateDecimationOrderUsingFrequencies:&frequencies];
  }
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

  // Sample from the distribution with no repetitions.
  while (decimationOrder.count < self.decimationDimensionSize) {
    id<LTDistributionSampler> sampler = [self.samplerFactory samplerWithFrequencies:*frequencies];
    NSUInteger samplesRequired = self.decimationDimensionSize - decimationOrder.count;

    // NSOrderedSet is used here instead of NSSet to preserve the sampling order, so
    // high-probability lines for decimation will be decimated first (since they will probably be
    // sampled first). This also aids testing since the order of samples is not shuffled when using
    // NSSet's hashing.
    NSOrderedSet *samples = [NSOrderedSet orderedSetWithArray:[sampler sample:samplesRequired]];
    [decimationOrder addObjectsFromArray:[samples array]];
    for (NSNumber *index in samples) {
      (*frequencies)[[index unsignedIntegerValue]] = 0.f;
    }
  }

  return [decimationOrder copy];
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
  [imageCoordinates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *) {
    [sourceRects addObject:[self sourceRectForIndex:[obj unsignedIntegerValue]]];
    [targetRects addObject:[self targetRectForIndex:idx]];
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
