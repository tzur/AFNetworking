// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTLaplacianPyramidProcessor.h"

#import "LTHatPyramidProcessor.h"
#import "LTLaplacianLevelConstructProcessor.h"
#import "LTOpenCVHalfFloat.h"
#import "LTOpenCVExtensions.h"
#import "LTQuadCopyProcessor.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTLaplacianPyramidProcessor()

/// Input texture for the processor.
@property (readonly, nonatomic) LTTexture *inputTexture;

@end

@implementation LTLaplacianPyramidProcessor

#pragma mark -
#pragma mark Output generation
#pragma mark -

+ (NSUInteger)highestLevelForInput:(LTTexture *)input {
  return MAX(1, std::floor(std::log2(std::min(input.size))));
}

+ (NSArray *)levelsForInput:(LTTexture *)input {
  return [LTLaplacianPyramidProcessor levelsForInput:input
                                           upToLevel:[LTLaplacianPyramidProcessor
                                                      highestLevelForInput:input]];
}

+ (NSArray<LTTexture *> *)levelsForInput:(LTTexture *)input upToLevel:(NSUInteger)level {
  NSUInteger maxLevel = [LTLaplacianPyramidProcessor highestLevelForInput:input];
  LTParameterAssert(level <= maxLevel,
                    @"level cannot be larger than %lu", (unsigned long)maxLevel);

  LTGLPixelFormat *hfFormat = [LTLaplacianPyramidProcessor
                               floatPrecisionPixelFormatFromAnyPixelFormat:input.pixelFormat];

  NSMutableArray *outputLevels = [NSMutableArray arrayWithCapacity:level];
  for (NSUInteger i = 0; i < level; ++i) {
    LTTexture *texture = [LTTexture textureWithSize:std::ceil(input.size / std::pow(2, i))
                                        pixelFormat:hfFormat allocateMemory:YES];
    texture.minFilterInterpolation = input.minFilterInterpolation;
    texture.magFilterInterpolation = input.magFilterInterpolation;
    [outputLevels addObject:texture];
  }

  return [outputLevels copy];
}

/// Converts any \c LTGLPixelDataType to a Floating Point \c LTGLPixelDataType with the closest
/// BitDepth.
+ (LTGLPixelFormat *)floatPrecisionPixelFormatFromAnyPixelFormat:(LTGLPixelFormat *)format {
  if (format.dataType == LTGLPixelDataTypeFloat) {
    return format;
  }
  switch (format.components) {
    case LTGLPixelComponentsR:
    case LTGLPixelComponentsDepth:
      return $(LTGLPixelFormatR16Float);
    case LTGLPixelComponentsRG:
      return $(LTGLPixelFormatRG16Float);
    case LTGLPixelComponentsRGBA:
      return $(LTGLPixelFormatRGBA16Float);
  }
}

#pragma mark -
#pragma mark Initializers
#pragma mark -

- (instancetype)initWithInputTexture:(LTTexture *)input {
  return [self initWithInputTexture:input
                 outputPyramidArray:[LTLaplacianPyramidProcessor levelsForInput:input]];
}

- (instancetype)initWithInputTexture:(LTTexture *)input
                  outputPyramidArray:(NSArray<LTTexture *> *)outputs {
  [self verifyInputTexture:input outputPyramidArray:outputs];

  if ((self = [super init])) {
    _inputTexture = input;
    _outputLaplacianPyramid = outputs;
  }
  return self;
}

- (void)verifyInputTexture:(LTTexture *)input
        outputPyramidArray:(NSArray<LTTexture *> *)outputs {
  LTParameterAssert(input.minFilterInterpolation == LTTextureInterpolationNearest,
                    @"input texture min interpolation method must be Nearest Neighbour");
  LTParameterAssert(input.magFilterInterpolation == LTTextureInterpolationNearest,
                    @"input texture mag interpolation method must be Nearest Neighbour");
  CGSize currentSize = input.size;
  for (LTTexture *texture in outputs) {
    LTParameterAssert(texture.minFilterInterpolation == LTTextureInterpolationNearest,
                      @"output texture min interpolation method must be Nearest Neighbour");
    LTParameterAssert(texture.magFilterInterpolation == LTTextureInterpolationNearest,
                      @"output texture mag interpolation method must be Nearest Neighbour");
    LTParameterAssert(texture.size.width <= currentSize.width &&
                      texture.size.height <= currentSize.height,
                      @"outputs array must be of dyadic decending size");
    currentSize = texture.size;
  }
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  [self copyInputTexture:self.inputTexture
     toPyramidFirstLevel:self.outputLaplacianPyramid.firstObject];

  [self preprocessGaussianPyramidForInput:self.outputLaplacianPyramid.firstObject];

  [self inPlaceLaplacianLevelConstructionIteration];
}

- (void)copyInputTexture:(LTTexture *)input toPyramidFirstLevel:(LTTexture *)halfFloatOutput {
  LTQuadCopyProcessor *copyProcessor = [[LTQuadCopyProcessor alloc] initWithInput:input
                                                                           output:halfFloatOutput];
  [copyProcessor process];
}

- (void)preprocessGaussianPyramidForInput:(LTTexture *)input {
  NSArray<LTTexture *> *gaussianHighPyramidLevels =
      [self.outputLaplacianPyramid
       subarrayWithRange:NSMakeRange(1, self.outputLaplacianPyramid.count - 1)];

  LTHatPyramidProcessor *pyramidProcessor =
      [[LTHatPyramidProcessor alloc] initWithInput:input
                                           outputs:gaussianHighPyramidLevels];
  [pyramidProcessor process];
}

- (void)inPlaceLaplacianLevelConstructionIteration {
  for (NSUInteger i = 0; i < self.outputLaplacianPyramid.count - 1; ++i) {
    LTLaplacianLevelConstructProcessor *laplacianLevelProcessor =
        [[LTLaplacianLevelConstructProcessor alloc]
         initWithBaseGaussianLevel:self.outputLaplacianPyramid[i]
         higherGaussianLevel:self.outputLaplacianPyramid[i + 1]
         outputTexture:self.outputLaplacianPyramid[i]];
    [laplacianLevelProcessor process];
  }
}

@end

NS_ASSUME_NONNULL_END
