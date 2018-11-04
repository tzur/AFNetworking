// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTBilateralFilterPyramidProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTBilateralFilterPyramidProcessor)

context(@"initialization", ^{
  __block LTTexture *base;

  beforeEach(^{
    cv::Mat4b baseImage(16, 16);
    base = [LTTexture textureWithImage:baseImage];
  });

  afterEach(^{
    base = nil;
  });

  it(@"should initialize with proper inputs and no guides", ^{
    NSArray<LTTexture *> *levels = [LTBilateralFilterPyramidProcessor levelsForInput:base];

    expect(^{
      LTBilateralFilterPyramidProcessor __unused *processor =
          [[LTBilateralFilterPyramidProcessor alloc] initWithInput:base outputs:levels guides:nil
                                                        rangeSigma:0.1];
    }).toNot.raiseAny();
  });

  it(@"should initialize with proper inputs and guides", ^{
    NSArray<LTTexture *> *levels = [LTBilateralFilterPyramidProcessor levelsForInput:base];
    NSArray<LTTexture *> *guides = [LTBilateralFilterPyramidProcessor levelsForInput:base];

    expect(^{
      LTBilateralFilterPyramidProcessor __unused *processor =
          [[LTBilateralFilterPyramidProcessor alloc] initWithInput:base outputs:levels guides:guides
                                                        rangeSigma:0.1];
    }).toNot.raiseAny();
  });

  it(@"should not initialize with empty output array", ^{
    NSArray<LTTexture *> *levels = @[];

    expect(^{
      LTBilateralFilterPyramidProcessor __unused *processor =
          [[LTBilateralFilterPyramidProcessor alloc] initWithInput:base outputs:levels guides:nil
                                                        rangeSigma:0.1];
    }).to.raise(NSInvalidArgumentException);
  });
});

static NSString * const kPyramidGenerationExamples =
    @"create proper outputs array for bilateral pyramid";

sharedExamples(kPyramidGenerationExamples, ^(NSDictionary *data) {
  context(@"output generation", ^{
    it(@"should create pyramid up to maximal level", ^{
      CGSize size = [data[@"size"] CGSizeValue];
      cv::Mat4b inputImage(size.height, size.width);
      LTTexture *input = [LTTexture textureWithImage:inputImage];

      NSArray<LTTexture *> *outputs = [LTBilateralFilterPyramidProcessor levelsForInput:input];
      expect(outputs.count).to.equal([data[@"expectedLevels"] unsignedIntegerValue]);
    });

    it(@"should create pyramid up to level as requested", ^{
      CGSize size = [data[@"size"] CGSizeValue];
      cv::Mat4b inputImage(size.height, size.width);
      LTTexture *input = [LTTexture textureWithImage:inputImage];

      NSArray<LTTexture *> *outputs = [LTBilateralFilterPyramidProcessor levelsForInput:input
                                                                              upToLevel:2];
      expect(outputs.count).to.equal(1);
    });
  });
});

itBehavesLike(kPyramidGenerationExamples, @{@"size": $(CGSizeMake(16, 16)),
                                            @"expectedLevels": @(3)});
itBehavesLike(kPyramidGenerationExamples, @{@"size": $(CGSizeMake(16, 15)),
                                            @"expectedLevels": @(2)});
itBehavesLike(kPyramidGenerationExamples, @{@"size": $(CGSizeMake(15, 16)),
                                            @"expectedLevels": @(2)});
itBehavesLike(kPyramidGenerationExamples, @{@"size": $(CGSizeMake(15, 15)),
                                            @"expectedLevels": @(2)});

static NSString * const kPyramidCreationExamples =
    @"Creates correct pyramid levels in down and up sampling";

static NSString * const kPyramidCreationExamplesFilenameKey = @"fileName";

static NSString * const kPyramidCreationExamplesDownsampleResultKey = @"downsampleFileName";

static NSString * const kPyramidCreationExamplesUpsampleResultKey = @"upsampleFileName";

static NSString * const kPyramidCreationExamplesUpsampleGuidedResultKey = @"upsampleGuidedFileName";

sharedExamples(kPyramidCreationExamples, ^(NSDictionary *data) {
  context(@"processing", ^{
    __block cv::Mat inputImage;
    __block LTTexture *input;

    beforeEach(^{
      NSString *fileName = data[kPyramidCreationExamplesFilenameKey];
      inputImage = LTLoadMat([self class], fileName);
      input = [LTTexture textureWithImage:inputImage];
    });

    afterEach(^{
      input = nil;
    });

    it(@"should create correct bilateral pyramid when downsampling", ^{
      NSArray<LTTexture *> *outputs = [LTBilateralFilterPyramidProcessor levelsForInput:input
                                                                              upToLevel:3];
      LTBilateralFilterPyramidProcessor *pyramidProcessor =
          [[LTBilateralFilterPyramidProcessor alloc] initWithInput:input outputs:outputs guides:nil
                                                        rangeSigma:0.1];
      [pyramidProcessor process];

      NSString *fileName = data[kPyramidCreationExamplesDownsampleResultKey];
      cv::Mat expected = LTLoadMat([self class], fileName);
      expect($([outputs.lastObject image])).to.beCloseToMatPSNR($(expected), 50);
    });

    it(@"should upsample with rising range sigma between levels of the pyramid correctly", ^{
      NSArray<LTTexture *> *outputs = [LTBilateralFilterPyramidProcessor levelsForInput:input
                                                                              upToLevel:3];
      LTBilateralFilterPyramidProcessor *downPyramidProcessor =
          [[LTBilateralFilterPyramidProcessor alloc] initWithInput:input outputs:outputs guides:nil
                                                        rangeSigma:0.1];
      [downPyramidProcessor process];

      LTTexture *finalOutput = [LTTexture textureWithPropertiesOf:input];

      NSArray<LTTexture *> *upOutputs = @[outputs.firstObject, finalOutput];
      LTBilateralFilterPyramidProcessor *upPyramidProcessor =
          [[LTBilateralFilterPyramidProcessor alloc] initWithInput:outputs.lastObject
                                                           outputs:upOutputs
                                                            guides:nil
                                                     rangeFunction:^float(CGFloat scale) {
                                                       return 0.1 * scale ;
                                                     }];
      [upPyramidProcessor process];

      NSString *fileName = data[kPyramidCreationExamplesUpsampleResultKey];
      cv::Mat expected = LTLoadMat([self class], fileName);
      expect($([finalOutput image])).to.beCloseToMatPSNR($(expected), 50);
    });

    it(@"should upsample correctly with guides the same size as the outputs", ^{
      NSArray<LTTexture *> *downOutputs = [LTBilateralFilterPyramidProcessor levelsForInput:input
                                                                                  upToLevel:3];
      LTBilateralFilterPyramidProcessor *downPyramidProcessor =
          [[LTBilateralFilterPyramidProcessor alloc] initWithInput:input outputs:downOutputs
                                                            guides:nil rangeSigma:0.1];
      [downPyramidProcessor process];

      NSMutableArray<LTTexture *> *upOutputs = [NSMutableArray array];
      NSMutableArray<LTTexture *> *guides = [NSMutableArray array];
      for (NSInteger i = downOutputs.count - 2; i >= 0; --i) {
        [upOutputs addObject:[LTTexture textureWithPropertiesOf:downOutputs[i]]];
        [guides addObject:downOutputs[i]];
      }
      [upOutputs addObject:[LTTexture textureWithPropertiesOf:input]];
      [guides addObject:input];

      LTBilateralFilterPyramidProcessor *upPyramidProcessor =
          [[LTBilateralFilterPyramidProcessor alloc] initWithInput:downOutputs.lastObject
                                                           outputs:[upOutputs copy]
                                                            guides:[guides copy]
                                                     rangeFunction:^float(CGFloat scale) {
                                                       return 0.1 * scale ;
                                                     }];
      [upPyramidProcessor process];

      NSString *fileName = data[kPyramidCreationExamplesUpsampleGuidedResultKey];
      cv::Mat expected = LTLoadMat([self class], fileName);
      expect($([upOutputs.lastObject image])).to.beCloseToMatPSNR($(expected), 50);
    });
  });
});

itBehavesLike(kPyramidCreationExamples,
              @{kPyramidCreationExamplesFilenameKey: @"VerticalStepFunction33.png",
                kPyramidCreationExamplesDownsampleResultKey:
                  @"VerticalStepFunction33_bilateral_L1toL3.png",
                kPyramidCreationExamplesUpsampleResultKey:
                  @"VerticalStepFunction33_bilateral_L1toL3toL1.png",
                kPyramidCreationExamplesUpsampleGuidedResultKey:
                  @"VerticalStepFunction33_bilateral_guided_upsample_L1toL3toL1.png"});

itBehavesLike(kPyramidCreationExamples,
              @{kPyramidCreationExamplesFilenameKey: @"HorizontalStepFunction32.png",
                kPyramidCreationExamplesDownsampleResultKey:
                  @"HorizontalStepFunction32_bilateral_L1toL3.png",
                kPyramidCreationExamplesUpsampleResultKey:
                  @"HorizontalStepFunction32_bilateral_L1toL3toL1.png",
                kPyramidCreationExamplesUpsampleGuidedResultKey:
                  @"HorizontalStepFunction32_bilateral_guided_upsample_L1toL3toL1.png"});

itBehavesLike(kPyramidCreationExamples, @{kPyramidCreationExamplesFilenameKey: @"Lena128.png",
                                          kPyramidCreationExamplesDownsampleResultKey:
                                            @"Lena128_bilateral_L1toL3.png",
                                          kPyramidCreationExamplesUpsampleResultKey:
                                            @"Lena128_bilateral_L1toL3toL1.png",
                                          kPyramidCreationExamplesUpsampleGuidedResultKey:
                                            @"Lena128_bilateral_guided_upsample_L1toL3toL1.png"});

SpecEnd
