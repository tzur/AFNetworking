// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTMeanProcessor.h"

#import "LTGLContext.h"
#import "LTTexture+Factory.h"

static NSArray *LTGenerateTextureArray(NSUInteger textureCount, NSUInteger baseValue,
                                               NSUInteger alphaValue, bool scaleAlpha) {
  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:textureCount];
  float alphaScalingFactor = 1;
  for (unsigned int i = 0; i < textureCount; ++i) {
    if (scaleAlpha) {
      alphaScalingFactor = (i + 1) / 10.0;
    }
    cv::Mat4b image(16, 16, cv::Vec4b((i + 1) * baseValue, (i + 1) * baseValue,
                                      (i + 1) * baseValue, alphaScalingFactor * alphaValue));
    LTTexture *texture = [LTTexture textureWithImage:image];
    [result addObject:texture];
  }
  return [result copy];
}

SpecBegin(LTMeanProcessor)

context(@"initialization", ^{
  __block GLint maxTexturesForDevice;

  beforeEach(^{
    maxTexturesForDevice = [LTGLContext currentContext].maxFragmentTextureUnits;
  });

  it(@"should not initialize with array with more than GL_MAX_TEXTURE_IMAGE_UNITS textures", ^{
    NSArray<LTTexture *> *input = LTGenerateTextureArray(maxTexturesForDevice + 1, 10, 255, false);

    expect(^{
      __unused LTMeanProcessor *processor =
          [[LTMeanProcessor alloc] initWithInputTextures:input];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with array with just 1 texture", ^{
    NSArray<LTTexture *> *input = LTGenerateTextureArray(1, 10, 255, false);

    expect(^{
      __unused LTMeanProcessor *processor =
          [[LTMeanProcessor alloc] initWithInputTextures:input];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with correctly sized texture array", ^{
    NSArray<LTTexture *> *input = LTGenerateTextureArray(std::ceilf(maxTexturesForDevice / 2), 10, 255, false);

    expect(^{
      __unused LTMeanProcessor *processor =
          [[LTMeanProcessor alloc] initWithInputTextures:input];
    }).toNot.raiseAny();
  });
});

static NSString * const kMeanProcessorSharedExamples = @"MeanProcessor Shared Examples";
static NSString * const kMeanProcessorCountKey = @"count";
static NSString * const kMeanProcessorBaseValueKey = @"baseValue";
static NSString * const kMeanProcessorAlphaKey = @"alphaTestValue";
static NSString * const kMeanProcessorResultValueKey = @"resultValue";
static NSString * const kMeanProcessorWeightedResultValueKey = @"weightedResultValue";

sharedExamplesFor(kMeanProcessorSharedExamples, ^(NSDictionary *data) {
  context(@"processing", ^{
    it(@"should average all textures with full weight", ^{
      NSUInteger textureCount = [data[kMeanProcessorCountKey] unsignedIntegerValue];
      NSUInteger baseValue = [data[kMeanProcessorBaseValueKey] unsignedIntegerValue];
      NSArray<LTTexture *> *input = LTGenerateTextureArray(textureCount, baseValue, 255, false);

      NSUInteger resultValue = [data[kMeanProcessorResultValueKey] unsignedIntegerValue];
      cv::Mat4b expectedImage(16, 16, cv::Vec4b(resultValue, resultValue, resultValue, 255));

      LTMeanProcessor *processor = [[LTMeanProcessor alloc] initWithInputTextures:input];
      [processor process];
      expect($(processor.outputTexture.image)).to.beCloseToMat($(expectedImage));
    });

    it(@"should average all textures with similar partial weight", ^{
      NSUInteger textureCount = [data[kMeanProcessorCountKey] unsignedIntegerValue];
      NSUInteger baseValue = [data[kMeanProcessorBaseValueKey] unsignedIntegerValue];
      NSUInteger alphaValue = [data[kMeanProcessorAlphaKey] unsignedIntegerValue];
      NSArray<LTTexture *> *input = LTGenerateTextureArray(textureCount, baseValue, alphaValue, false);

      NSUInteger resultValue = [data[kMeanProcessorResultValueKey] unsignedIntegerValue];
      cv::Mat4b expectedImage(16, 16, cv::Vec4b(resultValue, resultValue, resultValue, 255));

      LTMeanProcessor *processor = [[LTMeanProcessor alloc] initWithInputTextures:input];
      [processor process];
      expect($(processor.outputTexture.image)).to.beCloseToMat($(expectedImage));
    });

    it(@"should average all textures with changing partial weight", ^{
      NSUInteger textureCount = [data[kMeanProcessorCountKey] unsignedIntegerValue];
      NSUInteger baseValue = [data[kMeanProcessorBaseValueKey] unsignedIntegerValue];
      NSUInteger alphaValue = [data[kMeanProcessorAlphaKey] unsignedIntegerValue];
      NSArray<LTTexture *> *input = LTGenerateTextureArray(textureCount, baseValue, alphaValue, true);

      NSUInteger resultValue = [data[kMeanProcessorWeightedResultValueKey] unsignedIntegerValue];
      cv::Mat4b expectedImage(16, 16, cv::Vec4b(resultValue, resultValue, resultValue, 255));

      LTMeanProcessor *processor = [[LTMeanProcessor alloc] initWithInputTextures:input];
      [processor process];
      expect($(processor.outputTexture.image)).to.beCloseToMat($(expectedImage));
    });

    it(@"should average all textures with zero weight", ^{
      NSUInteger textureCount = [data[kMeanProcessorCountKey] unsignedIntegerValue];
      NSUInteger baseValue = [data[kMeanProcessorBaseValueKey] unsignedIntegerValue];
      NSArray<LTTexture *> *input = LTGenerateTextureArray(textureCount, baseValue, 0, false);

      cv::Mat4b expectedImage(16, 16, cv::Vec4b(0, 0, 0, 255));

      LTMeanProcessor *processor = [[LTMeanProcessor alloc] initWithInputTextures:input];
      [processor process];
      expect($(processor.outputTexture.image)).to.beCloseToMat($(expectedImage));
    });
  });
});

itShouldBehaveLike(kMeanProcessorSharedExamples, ^{
  return @{
    kMeanProcessorCountKey: @(2),
    kMeanProcessorBaseValueKey: @(10),
    kMeanProcessorAlphaKey: @(61),
    kMeanProcessorResultValueKey: @(15),
    kMeanProcessorWeightedResultValueKey: @(17)
  };
});

itShouldBehaveLike(kMeanProcessorSharedExamples, ^{
  return @{
    kMeanProcessorCountKey: @(7),
    kMeanProcessorBaseValueKey: @(10),
    kMeanProcessorAlphaKey: @(61),
    kMeanProcessorResultValueKey: @(40),
    kMeanProcessorWeightedResultValueKey: @(50)
  };
});

itShouldBehaveLike(kMeanProcessorSharedExamples, ^{
  return @{
    kMeanProcessorCountKey: @(8),
    kMeanProcessorBaseValueKey: @(10),
    kMeanProcessorAlphaKey: @(61),
    kMeanProcessorResultValueKey: @(45),
    kMeanProcessorWeightedResultValueKey: @(57)
  };
});

SpecEnd
