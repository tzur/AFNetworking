// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRecomposeProcessor.h"

#import "LTInverseTransformSampler.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

typedef std::pair<NSUInteger, float> LTIndexedFloat;

@interface LTDegenerateSampler : NSObject <LTDistributionSampler> {
  std::vector<LTIndexedFloat> _pairs;
}
@end

@implementation LTDegenerateSampler

- (instancetype)initWithFrequencies:(const Floats &)frequencies {
  if (self = [super init]) {
    for (Floats::size_type i = 0; i < frequencies.size(); ++i) {
      _pairs.push_back(std::make_pair(i, frequencies[i]));
    };
    std::stable_sort(_pairs.begin(), _pairs.end(), [](LTIndexedFloat a, LTIndexedFloat b) {
      return a.second > b.second;
    });
  }
  return self;
}

- (NSArray *)sample:(NSUInteger)times {
  NSMutableArray *values = [NSMutableArray array];
  for (NSUInteger i = 0; i < times; ++i) {
    [values addObject:@(_pairs[i % _pairs.size()].first)];
  }
  return [values copy];
}

@end

@interface LTDegenerateSamplerFactory : NSObject <LTDistributionSamplerFactory>
@end

@implementation LTDegenerateSamplerFactory

- (id<LTDistributionSampler>)samplerWithFrequencies:(const Floats &)frequencies {
  return [[LTDegenerateSampler alloc] initWithFrequencies:frequencies];
}

@end

LTSpecBegin(LTRecomposeProcessor)

context(@"initialization", ^{
  it(@"should not initialize if input size is different than mask size", ^{
    LTTexture *input = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 4)];
    LTTexture *mask = [LTTexture byteRGBATextureWithSize:CGSizeMake(8, 8)];
    LTTexture *output = [LTTexture textureWithPropertiesOf:input];

    expect(^{
      LTRecomposeProcessor __unused *processor = [[LTRecomposeProcessor alloc]
                                                  initWithInput:input mask:mask output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize if input size is different than output size", ^{
    LTTexture *input = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 4)];
    LTTexture *mask = [LTTexture textureWithPropertiesOf:input];
    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMake(8, 8)];

    expect(^{
      LTRecomposeProcessor __unused *processor = [[LTRecomposeProcessor alloc]
                                                  initWithInput:input mask:mask output:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  __block LTRecomposeProcessor *processor;
  __block cv::Mat4b image;
  __block LTTexture *mask;
  __block LTTexture *output;

  beforeEach(^{
    image = cv::Mat4b(4, 4);
    image(cv::Rect(0, 0, 1, 4)) = cv::Vec4b(255, 0, 0, 255);
    image(cv::Rect(1, 0, 1, 4)) = cv::Vec4b(0, 255, 0, 255);
    image(cv::Rect(2, 0, 1, 4)) = cv::Vec4b(0, 0, 255, 255);
    image(cv::Rect(3, 0, 1, 4)) = cv::Vec4b(0, 0, 0, 255);

    LTTexture *input = [LTTexture textureWithImage:image];
    mask = [LTTexture textureWithSize:input.size precision:LTTexturePrecisionByte
                               format:LTTextureFormatRed allocateMemory:YES];
    output = [LTTexture textureWithPropertiesOf:input];

    [mask clearWithColor:LTVector4(0, 0, 0, 1)];
    [output clearWithColor:LTVector4(0, 0, 0, 0)];

    processor = [[LTRecomposeProcessor alloc] initWithInput:input mask:mask output:output];
    processor.samplerFactory = [[LTDegenerateSamplerFactory alloc] init];
    processor.linesToDecimate = 2;
  });

  afterEach(^{
    mask = nil;
    output = nil;
    processor = nil;
  });

  it(@"should decimate horizontally", ^{
    processor.decimationDimension = LTRecomposeDecimationDimensionHorizontal;
    [processor process];

    // Take cols 2,3.
    cv::Mat4b expected(4, 4, cv::Vec4b(0, 0, 0, 0));
    image(cv::Rect(2, 0, 1, 4)).copyTo(expected(cv::Rect(0, 0, 1, 4)));
    image(cv::Rect(3, 0, 1, 4)).copyTo(expected(cv::Rect(1, 0, 1, 4)));

    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should decimate vertically", ^{
    processor.decimationDimension = LTRecomposeDecimationDimensionVertical;
    [processor process];

    // Take cols 2,3.
    cv::Mat4b expected(4, 4, cv::Vec4b(0, 0, 0, 0));
    image(cv::Rect(0, 2, 4, 1)).copyTo(expected(cv::Rect(0, 0, 4, 1)));
    image(cv::Rect(0, 3, 4, 1)).copyTo(expected(cv::Rect(0, 1, 4, 1)));

    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should decimate according to mask", ^{
    [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      (*mapped)(cv::Rect(1, 0, 1, 4)).setTo(255);
    }];
    [processor setMaskUpdated];

    processor.decimationDimension = LTRecomposeDecimationDimensionHorizontal;
    [processor process];

    // Take cols 1,3, since a mask is blocking column 1 from disappearing.
    cv::Mat4b expected(4, 4, cv::Vec4b(0, 0, 0, 0));
    image(cv::Rect(1, 0, 1, 4)).copyTo(expected(cv::Rect(0, 0, 1, 4)));
    image(cv::Rect(3, 0, 1, 4)).copyTo(expected(cv::Rect(1, 0, 1, 4)));

    expect($([output image])).to.equalMat($(expected));
  });
});

context(@"properties", ^{
  it(@"should limit lines to decimate range", ^{
    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(2, 4)];
    LTTexture *mask = [LTTexture textureWithPropertiesOf:input];
    LTTexture *output = [LTTexture textureWithPropertiesOf:input];

    LTRecomposeProcessor *processor = [[LTRecomposeProcessor alloc] initWithInput:input
                                                                             mask:mask
                                                                           output:output];

    expect(^{
      processor.linesToDecimate = 4;
    }).toNot.raiseAny();

    expect(^{
      processor.linesToDecimate = 5;
    }).to.raise(NSInvalidArgumentException);

    processor.decimationDimension = LTRecomposeDecimationDimensionVertical;
    expect(^{
      processor.linesToDecimate = 3;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should have correct default decimationDimension value for wide images", ^{
    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(2, 4)];
    LTTexture *mask = [LTTexture textureWithPropertiesOf:input];
    LTTexture *output = [LTTexture textureWithPropertiesOf:input];

    LTRecomposeProcessor *processor = [[LTRecomposeProcessor alloc] initWithInput:input
                                                                             mask:mask
                                                                           output:output];

    expect(processor.decimationDimension).to.equal(LTRecomposeDecimationDimensionHorizontal);
  });

  it(@"should have correct default decimationDimension value for tall images", ^{
    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(4, 2)];
    LTTexture *mask = [LTTexture textureWithPropertiesOf:input];
    LTTexture *output = [LTTexture textureWithPropertiesOf:input];

    LTRecomposeProcessor *processor = [[LTRecomposeProcessor alloc] initWithInput:input
                                                                             mask:mask
                                                                           output:output];

    expect(processor.decimationDimension).to.equal(LTRecomposeDecimationDimensionVertical);
  });
});

LTSpecEnd
