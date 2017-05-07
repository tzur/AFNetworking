// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTLaplacianPyramidReconstructProcessor.h"

#import "LTLaplacianLevelReconstructProcessor.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTLaplacianPyramidReconstructProcessor()

/// Input pyramid before reconstruction.
@property (readonly, nonatomic) NSArray<LTTexture *> *laplacianPyramid;

/// Output texture.
@property (readonly, nonatomic) LTTexture *output;

/// Boosting function for the laplacian levels.
@property (copy, readonly, nonatomic) LTLaplacianLevelBoostBlock boostingFunction;

/// Determines whether to do processing using the textures already allocated in \c laplacianPyramid.
@property (readonly, nonatomic) BOOL inPlaceProcessing;

/// Records if processing was already performed when using in place processing.
@property (nonatomic) BOOL processingPerformed;

@end

@implementation LTLaplacianPyramidReconstructProcessor

- (instancetype)initWithLaplacianPyramid:(NSArray<LTTexture *> *)laplacianPyramid
                           outputTexture:(LTTexture *)output
                       inPlaceProcessing:(BOOL)inPlaceProcessing
                        boostingFunction:(LTLaplacianLevelBoostBlock)boostingFunction {
  LTParameterAssert(laplacianPyramid.count >= 2, @"Laplacian pyramid must have at least 2 levels.");
  LTParameterAssert(laplacianPyramid.firstObject.size == output.size,
                    @"Output texture must be the same size as the finest scale in the pyramid.");
  LTParameterAssert(boostingFunction, @"boostingFunction must be nonnull");

  if (self = [super init]) {
    _laplacianPyramid = laplacianPyramid;
    _output = output;
    _inPlaceProcessing = inPlaceProcessing;
    _processingPerformed = NO;
    _boostingFunction = [boostingFunction copy];
  }
  return self;
}

/// Convenience initializer that uses the identity function for \c boostingFunction.
- (instancetype)initWithLaplacianPyramid:(NSArray<LTTexture *> *)laplacianPyramid
                           outputTexture:(LTTexture *)output
                       inPlaceProcessing:(BOOL)inPlaceProcessing {
  return [self initWithLaplacianPyramid:laplacianPyramid
                          outputTexture:output
                      inPlaceProcessing:inPlaceProcessing
                       boostingFunction:^float(NSUInteger) {
                         return 1;
                       }];
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  if (self.inPlaceProcessing) {
    // After the first processing, all levels of the pyramid are already gaussian levels, treating
    // them as laplacian levels results in too much energy and the image would clamp at white.
    LTAssert(!self.processingPerformed,
             @"In place laplacian pyramid reconstruction is called more than once");

    self.processingPerformed = YES;
    [self processInPlace];
  } else {
    [self processInAuxiliaryTextures];
  }
}

- (void)processInAuxiliaryTextures {
  LTTexture *currentHigherGaussianLevel = [self.laplacianPyramid.lastObject clone];

  for (NSInteger level = self.laplacianPyramid.count - 2; level >= 0; --level) {
    @autoreleasepool {
      LTTexture *output = (level == 0) ? self.output :
          [LTTexture textureWithPropertiesOf:self.laplacianPyramid[level]];

      currentHigherGaussianLevel.minFilterInterpolation = LTTextureInterpolationNearest;
      currentHigherGaussianLevel.magFilterInterpolation = LTTextureInterpolationNearest;

      LTLaplacianLevelReconstructProcessor *processor =
          [[LTLaplacianLevelReconstructProcessor alloc]
           initWithBaseLaplacianLevel:self.laplacianPyramid[level]
           baseLaplacianLevelBoost:self.boostingFunction(level + 1)
           higherGaussianLevel:currentHigherGaussianLevel
           outputTexture:output];

      [processor process];

      currentHigherGaussianLevel = output;
    }
  }
}

- (void)processInPlace {
  for (NSInteger level = self.laplacianPyramid.count - 2; level >= 0; --level) {
    LTTexture *output = (level == 0) ? self.output : self.laplacianPyramid[level];

    LTLaplacianLevelReconstructProcessor *processor =
        [[LTLaplacianLevelReconstructProcessor alloc]
         initWithBaseLaplacianLevel:self.laplacianPyramid[level]
         baseLaplacianLevelBoost:self.boostingFunction(level + 1)
         higherGaussianLevel:self.laplacianPyramid[level + 1]
         outputTexture:output];

    [processor process];
  }
}

@end

NS_ASSUME_NONNULL_END
