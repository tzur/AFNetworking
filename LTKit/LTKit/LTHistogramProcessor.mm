// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTHistogramProcessor.h"

#import <Accelerate/Accelerate.h>

#import "LTTexture+Factory.h"

@interface LTHistogramProcessor ()

/// Input texture of the processor.
@property (strong, nonatomic) LTTexture *inputTexture;

@end

@implementation LTHistogramProcessor

- (instancetype)initWithInputTexture:(LTTexture *)inputTexture {
  LTParameterAssert([self.class isValidInputTexture:inputTexture],
                    @"Output should be in LTTextureFormatRGBA format");
  if (self = [super init]) {
    self.inputTexture = inputTexture;
    [self setHistogramValuesToZero];
  }
  return self;
}

+ (BOOL)isValidInputTexture:(LTTexture *)texture {
  return texture.format == LTTextureFormatRGBA && texture.precision == LTTexturePrecisionByte;
}

static const NSUInteger kHistogramSize = 256;

- (void)setHistogramValuesToZero {
  _redHistogram = cv::Mat1f::zeros(kHistogramSize, 1);
  _greenHistogram = cv::Mat1f::zeros(kHistogramSize, 1);
  _blueHistogram = cv::Mat1f::zeros(kHistogramSize, 1);

  _maxRedCount = 0;
  _maxGreenCount = 0;
  _maxBlueCount = 0;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)process {
  [self.inputTexture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    vImage_Buffer source = {
      .data = mapped.data,
      .height = (vImagePixelCount)mapped.rows,
      .width = (vImagePixelCount)mapped.cols,
      .rowBytes = mapped.step[0]
    };

    typedef std::array<vImagePixelCount, kHistogramSize> LTHistogram;
    LTHistogram histogramA, histogramR, histogramG, histogramB;
    vImagePixelCount *histogram[4] = {
      histogramA.data(),
      histogramR.data(),
      histogramG.data(),
      histogramB.data()
    };

    vImage_Error error = vImageHistogramCalculation_ARGB8888(&source,
                                                             histogram,
                                                             kvImageNoFlags);
    if (error != kvImageNoError) {
      LogError(@"Error computing histogram: %ld", (long)error);
      [self setHistogramValuesToZero];
      return;
    }

    _maxRedCount = *std::max_element(&histogram[0][0], &histogram[0][kHistogramSize]);
    _maxGreenCount = *std::max_element(&histogram[1][0], &histogram[1][kHistogramSize]);
    _maxBlueCount = *std::max_element(&histogram[2][0], &histogram[2][kHistogramSize]);

    std::copy(&histogram[0][0], &histogram[0][kHistogramSize], _redHistogram.begin());
    std::copy(&histogram[1][0], &histogram[1][kHistogramSize], _greenHistogram.begin());
    std::copy(&histogram[2][0], &histogram[2][kHistogramSize], _blueHistogram.begin());
  }];
}

@end
