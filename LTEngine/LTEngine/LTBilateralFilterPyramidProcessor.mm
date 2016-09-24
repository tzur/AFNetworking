// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTBilateralFilterPyramidProcessor.h"

#import "LTBilateralFilterProcessor.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTBilateralFilterPyramidProcessor ()

/// Input texture.
@property (readonly, nonatomic) LTTexture *input;

/// Output pyramid texture array.
@property (readonly, nonatomic) NSArray<LTTexture *> *outputs;

/// Guide texture array for each pyramid level.
@property (readonly, nonatomic, nullable) NSArray<LTTexture *> *guides;

/// Range sigma function for the pyramid levels.
@property (copy, readonly, nonatomic) LTBilateralPyramidRangeSigmaBlock rangeFunction;

@end

@implementation LTBilateralFilterPyramidProcessor

#pragma mark -
#pragma mark Output generation
#pragma mark -

+ (NSUInteger)highestLevelForInput:(LTTexture *)input {
  return MAX(1, std::floor(std::log2(std::min(input.size))));
}

+ (NSArray *)levelsForInput:(LTTexture *)input {
  return [LTBilateralFilterPyramidProcessor levelsForInput:input
                                                 upToLevel:[LTBilateralFilterPyramidProcessor
                                                            highestLevelForInput:input]];
}

+ (NSArray<LTTexture *> *)levelsForInput:(LTTexture *)input upToLevel:(NSUInteger)level {
  NSUInteger maxLevel = [LTBilateralFilterPyramidProcessor highestLevelForInput:input];
  LTParameterAssert(level <= maxLevel,
                    @"level cannot be larger than %lu", (unsigned long)maxLevel);

  NSMutableArray *outputLevels = [NSMutableArray arrayWithCapacity:level - 1];
  for (NSUInteger i = 1; i < level; ++i) {
    LTTexture *texture = [LTTexture textureWithSize:std::ceil(input.size / std::pow(2, i))
                                        pixelFormat:input.pixelFormat allocateMemory:YES];
    [outputLevels addObject:texture];
  }

  return [outputLevels copy];
}

#pragma mark -
#pragma mark Initializers
#pragma mark -

- (instancetype)initWithInput:(LTTexture *)input
                      outputs:(NSArray<LTTexture *> *)outputs
                       guides:(NSArray<LTTexture *> * _Nullable)guides
                rangeFunction:(LTBilateralPyramidRangeSigmaBlock)rangeFunction {
  LTParameterAssert(input);
  LTParameterAssert(outputs.count > 0, @"Output textures array must contain at least one texture");
  LTParameterAssert(!guides || guides.count == outputs.count, @"Guide textures array must contain "
                    "the exact same number of textures as the outputs array");
  LTParameterAssert(rangeFunction);

  if (self = [super init]) {
    _input = input;
    _outputs = outputs;
    _guides = guides;
    _rangeFunction = [rangeFunction copy];
  }
  return self;
}

- (instancetype)initWithInput:(LTTexture *)input
                      outputs:(NSArray<LTTexture *> *)outputs
                       guides:(NSArray<LTTexture *> * _Nullable)guides
                   rangeSigma:(float)rangeSigma {
  return [self initWithInput:input outputs:outputs guides:guides
               rangeFunction:^float(CGFloat) {
                 return rangeSigma;
               }];
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  for (NSUInteger i = 0; i < self.outputs.count; ++i) {
    LTTexture *input = (i == 0) ? self.input : self.outputs[i - 1];
    LTTexture *guide = self.guides ? self.guides[i] : input;

    LTBilateralFilterProcessor *processor =
        [[LTBilateralFilterProcessor alloc] initWithInput:input guide:guide
                                                  outputs:@[self.outputs[i]]];

    processor.rangeSigma =
        self.rangeFunction(std::max(self.outputs[i].size / self.input.size));
    processor.iterationsPerOutput = @[@(1)];

    [processor process];
  }
}

@end

NS_ASSUME_NONNULL_END
