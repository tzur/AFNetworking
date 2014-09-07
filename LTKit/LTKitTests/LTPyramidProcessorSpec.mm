// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPyramidProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

void LTGridMake(CGSize size, cv::Mat4b *grid, cv::Mat4b *downsampled) {
  grid->create(cv::Size(size.width, size.height));
  grid->setTo(cv::Vec4b(0, 0, 0, 255));
  downsampled->create(std::ceil(size.height / 2), std::ceil(size.width / 2));

  NSUInteger cellNumber = 0;
  for (int y = 0; y < grid->rows; y += 2) {
    for (int x = 0; x < grid->cols; x += 2) {
      ++cellNumber;

      (*grid)(y, x) = cv::Vec4b(cellNumber & 0xFF, (cellNumber >> 8) & 0xFF,
                                (cellNumber >> 16) & 0xFF, 255);

      (*downsampled)(y / 2, x / 2) = (*grid)(y, x);
    }
  }
}

LTSpecBegin(LTPyramidProcessor)

static NSString * const kSubsamplingExamples = @"subsample image correctly using nearest neighbour";

sharedExamples(kSubsamplingExamples, ^(NSDictionary *data) {
  it(@"should subsample correctly", ^{
    cv::Mat4b grid, expected;
    CGSize size = [data[@"size"] CGSizeValue];
    LTGridMake(size, &grid, &expected);

    LTTexture *input = [LTTexture textureWithImage:grid];
    input.minFilterInterpolation = LTTextureInterpolationNearest;
    input.magFilterInterpolation = LTTextureInterpolationNearest;

    LTTexture *output = [LTTexture byteRGBATextureWithSize:std::ceil(input.size / 2)];

    LTPyramidProcessor *processor = [[LTPyramidProcessor alloc] initWithInput:input
                                                                      outputs:@[output]];
    [processor process];

    expect($(output.image)).to.equalMat($(expected));
  });
});

itBehavesLike(kSubsamplingExamples, @{@"size": $(CGSizeMake(64, 64))});
itBehavesLike(kSubsamplingExamples, @{@"size": $(CGSizeMake(65, 64))});
itBehavesLike(kSubsamplingExamples, @{@"size": $(CGSizeMake(64, 65))});
itBehavesLike(kSubsamplingExamples, @{@"size": $(CGSizeMake(65, 65))});

it(@"should create correct levels for input", ^{
  LTTexture *input = [LTTexture byteRedTextureWithSize:CGSizeMake(15, 13)];
  NSArray *levels = [LTPyramidProcessor levelsForInput:input];

  NSArray *sizes = @[$(CGSizeMake(8, 7)), $(CGSizeMake(4, 4))];

  [levels enumerateObjectsUsingBlock:^(LTTexture *level, NSUInteger i, BOOL *) {
    expect(level.format).to.equal(input.format);
    expect(level.precision).to.equal(input.precision);
    expect(level.size).to.equal([sizes[i] CGSizeValue]);
  }];
});

it(@"should create correct pyramid", ^{
  LTTexture *input = [LTTexture textureWithImage:LTLoadMat([self class], @"PyramidGrid1.png")];
  input.minFilterInterpolation = LTTextureInterpolationNearest;
  input.magFilterInterpolation = LTTextureInterpolationNearest;

  NSArray *outputs = [LTPyramidProcessor levelsForInput:input];
  for (LTTexture *output in outputs) {
    output.minFilterInterpolation = LTTextureInterpolationNearest;
    output.magFilterInterpolation = LTTextureInterpolationNearest;
  }

  LTPyramidProcessor *processor = [[LTPyramidProcessor alloc] initWithInput:input outputs:outputs];
  [processor process];

  for (NSUInteger i = 0; i < outputs.count; ++i) {
    cv::Mat expected = LTLoadMat([self class],
                                 [NSString stringWithFormat:@"PyramidGrid%lu.png",
                                  (unsigned long)i + 2]);
    expect($([(LTTexture *)outputs[i] image])).to.equalMat($(expected));
  }
});

LTSpecEnd
