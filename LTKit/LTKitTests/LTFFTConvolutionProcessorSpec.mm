// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFFTConvolutionProcessor.h"

#import "LTOpenCVExtensions.h"

SpecBegin(LTFFTConvolutionProcessor)

context(@"initialization", ^{
  it(@"should not initialize with differently sized operands", ^{
    cv::Mat1f first(16, 16);
    cv::Mat1f second(32, 32);

    expect(^{
      cv::Mat1f output(16, 16);
      __unused LTFFTConvolutionProcessor *processor =
          [[LTFFTConvolutionProcessor alloc] initWithFirstOperand:first secondOperand:second
                                                           output:&output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with differently sized output", ^{
    cv::Mat1f first(16, 16);
    cv::Mat1f second(16, 16);

    expect(^{
      cv::Mat1f output(32, 32);
      __unused LTFFTConvolutionProcessor *processor =
          [[LTFFTConvolutionProcessor alloc] initWithFirstOperand:first secondOperand:second
                                                           output:&output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not initialize with operands with npot size", ^{
    cv::Mat1f first(15, 15);
    cv::Mat1f second(15, 15);

    expect(^{
      cv::Mat1f output(15, 15);
      __unused LTFFTConvolutionProcessor *processor =
          [[LTFFTConvolutionProcessor alloc] initWithFirstOperand:first secondOperand:second
                                                           output:&output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize with properly sized inputs", ^{
    cv::Mat1f first(16, 16);
    cv::Mat1f second(16, 16);

    expect(^{
      cv::Mat1f output(16, 16);
      __unused LTFFTConvolutionProcessor *processor =
          [[LTFFTConvolutionProcessor alloc] initWithFirstOperand:first secondOperand:second
                                                           output:&output];
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  __block cv::Mat1f first, second, output;
  __block LTFFTConvolutionProcessor *processor;

  beforeEach(^{
    first = cv::Mat1f::zeros(16, 16);
    first(cv::Rect(4, 4, 10, 10)) = 1;
    second = cv::Mat1f::zeros(16, 16);
    second(cv::Rect(7, 7, 2, 2)) = 0.25;

    output.create(first.size());
    processor = [[LTFFTConvolutionProcessor alloc] initWithFirstOperand:first secondOperand:second
                                                                 output:&output];
  });

  it(@"should process and shift", ^{
    LTSingleMatOutput *result = [processor process];

    cv::Mat1f expected(first.size());
    cv::filter2D(first, expected, CV_32F, second, cv::Point(7, 7));

    expect($(expected)).to.beCloseToMat($(result.mat));
  });

  it(@"should process and not shift", ^{
    processor.shiftResult = NO;
    LTSingleMatOutput *result = [processor process];

    cv::Mat1f expected(first.size());
    cv::filter2D(first, expected, CV_32F, second, cv::Point(7, 7));
    LTInPlaceFFTShift(&expected);

    expect($(expected)).to.beCloseToMat($(result.mat));
  });
});

SpecEnd
