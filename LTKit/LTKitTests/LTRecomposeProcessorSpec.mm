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

- (instancetype)initWithFrequencies:(const Floats &)frequencies random:(LTRandom __unused *)random {
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

- (Floats)sample:(NSUInteger)times {
  Floats samples;
  for (NSUInteger i = 0; i < times; ++i) {
    samples.push_back(_pairs[i % _pairs.size()].first);
  }
  return samples;
}

@end

@interface LTDegenerateSamplerFactory : NSObject <LTDistributionSamplerFactory>
@end

@implementation LTDegenerateSamplerFactory

- (id<LTDistributionSampler>)samplerWithFrequencies:(const Floats &)frequencies
                                             random:(LTRandom *)random {
  return [[LTDegenerateSampler alloc] initWithFrequencies:frequencies random:random];
}

@end

LTSpecBegin(LTRecomposeProcessor)

context(@"initialization", ^{
  it(@"should not initialize if input size is smaller than mask size", ^{
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
  __block LTTexture *input;
  __block LTTexture *mask;
  __block LTTexture *output;

  beforeEach(^{
    image = cv::Mat4b(4, 4);
    image(cv::Rect(0, 0, 1, 4)) = cv::Vec4b(255, 0, 0, 255);
    image(cv::Rect(1, 0, 1, 4)) = cv::Vec4b(0, 255, 0, 255);
    image(cv::Rect(2, 0, 1, 4)) = cv::Vec4b(0, 0, 255, 255);
    image(cv::Rect(3, 0, 1, 4)) = cv::Vec4b(0, 0, 0, 255);

    input = [LTTexture textureWithImage:image];
    mask = [LTTexture byteRedTextureWithSize:input.size];
    output = [LTTexture textureWithPropertiesOf:input];

    [mask clearWithColor:LTVector4One];
    [output clearWithColor:LTVector4(0, 0, 0, 0)];

    processor = [[LTRecomposeProcessor alloc] initWithInput:input mask:mask output:output];
    processor.samplerFactory = [[LTDegenerateSamplerFactory alloc] init];
  });

  afterEach(^{
    mask = nil;
    input = nil;
    output = nil;
    processor = nil;
  });

  it(@"should decimate and center horizontally", ^{
    processor.colsToDecimate = 2;
    [processor process];

    // Take cols 2,3.
    cv::Mat4b expected(4, 4, cv::Vec4b(0, 0, 0, 0));
    image(cv::Rect(2, 0, 1, 4)).copyTo(expected(cv::Rect(1, 0, 1, 4)));
    image(cv::Rect(3, 0, 1, 4)).copyTo(expected(cv::Rect(2, 0, 1, 4)));

    expect(processor.recomposedRect).to.equal(CGRectMake(1, 0, 2, 4));
    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should decimate and center vertically", ^{
    processor.rowsToDecimate = 2;
    [processor process];

    // Take cols 2,3.
    cv::Mat4b expected(4, 4, cv::Vec4b(0, 0, 0, 0));
    image(cv::Rect(0, 2, 4, 1)).copyTo(expected(cv::Rect(0, 1, 4, 1)));
    image(cv::Rect(0, 3, 4, 1)).copyTo(expected(cv::Rect(0, 2, 4, 1)));

    expect(processor.recomposedRect).to.equal(CGRectMake(0, 1, 4, 2));
    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should decimate and center on both dimensions", ^{
    processor.rowsToDecimate = 2;
    processor.colsToDecimate = 2;
    [processor process];

    // Take rect (2,2)-(3,3).
    cv::Mat4b expected(4, 4, cv::Vec4b(0, 0, 0, 0));
    image(cv::Rect(2, 2, 2, 2)).copyTo(expected(cv::Rect(1, 1, 2, 2)));

    expect(processor.recomposedRect).to.equal(CGRectMake(1, 1, 2, 2));
    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should decimate according to updated mask", ^{
    processor.colsToDecimate = 2;
    [processor process];

    [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      (*mapped)(cv::Rect(1, 0, 1, 4)).setTo(0);
    }];

    [processor process];

    // Take cols 1,3, since a mask is blocking column 1 from disappearing.
    cv::Mat4b expected(4, 4, cv::Vec4b(0, 0, 0, 0));
    image(cv::Rect(1, 0, 1, 4)).copyTo(expected(cv::Rect(1, 0, 1, 4)));
    image(cv::Rect(3, 0, 1, 4)).copyTo(expected(cv::Rect(2, 0, 1, 4)));

    expect(processor.recomposedRect).to.equal(CGRectMake(1, 0, 2, 4));
    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should decimate according to mask with smaller size", ^{
    mask = [LTTexture byteRedTextureWithSize:input.size / 2];
    processor = [[LTRecomposeProcessor alloc] initWithInput:input mask:mask output:output];
    processor.samplerFactory = [[LTDegenerateSamplerFactory alloc] init];

    [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      (*mapped)(cv::Rect(1, 0, 1, 2)).setTo(0);
    }];

    processor.colsToDecimate = 2;
    [processor process];

    // Take cols 3,4, since a mask is blocking columns 1,2 from disappearing.
    cv::Mat4b expected(4, 4, cv::Vec4b(0, 0, 0, 0));
    image(cv::Rect(2, 0, 1, 4)).copyTo(expected(cv::Rect(1, 0, 1, 4)));
    image(cv::Rect(3, 0, 1, 4)).copyTo(expected(cv::Rect(2, 0, 1, 4)));

    expect(processor.recomposedRect).to.equal(CGRectMake(1, 0, 2, 4));
    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should normalize frequencies correctly", ^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"RecomposeInput.png")];
    cv::Mat1b maskMat = LTLoadMat([self class], @"RecomposeMask.png");
    mask = [LTTexture textureWithImage:maskMat];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTRecomposeProcessor alloc] initWithInput:input mask:mask output:output];
    processor.colsToDecimate = input.size.width * 0.4;
    [processor process];

    cv::Mat4b expected = LTLoadMat([self class], @"RecomposeOutput.png");
    expect($(output.image)).beCloseToMat($(expected));
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
      processor.colsToDecimate = 4;
    }).toNot.raiseAny();

    expect(^{
      processor.colsToDecimate = 5;
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      processor.rowsToDecimate = 3;
    }).to.raise(NSInvalidArgumentException);
  });
});

LTSpecEnd
