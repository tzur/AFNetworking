// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFFTProcessor.h"

SpecBegin(LTFFTProcessor)

context(@"forward transform", ^{
  context(@"real input", ^{
    it(@"should produce correct transform of constant input", ^{
      cv::Mat1f input = cv::Mat1f(32, 32, 1.0);
      LTSplitComplexMat output;

      LTFFTProcessor *processor = [[LTFFTProcessor alloc] initWithRealInput:input output:&output];
      LTSplitComplexOutput *result = [processor process];

      // For constant input, the output should be a single DC coefficient and phases of 0.
      cv::Mat1f expectedReal = cv::Mat1f::zeros(input.size());
      expectedReal(0, 0) = input.total() * 1.0;
      cv::Mat1f expectedImag = cv::Mat1f::zeros(input.size());

      expect($(result.splitComplexMat.real)).to.beCloseToMat($(expectedReal));
      expect($(result.splitComplexMat.imag)).to.beCloseToMat($(expectedImag));
    });

    it(@"should produce correct transform of complex input", ^{
      cv::Mat1f input = cv::Mat1f(4, 4, 1.0);
      for (int y = 0; y < input.cols; ++y) {
        for (int x = 0; x < input.rows; ++x) {
          input(y, x) = y * input.rows + x;
        }
      }

      LTSplitComplexMat output;

      LTFFTProcessor *processor = [[LTFFTProcessor alloc] initWithRealInput:input output:&output];
      LTSplitComplexOutput *result = [processor process];

      // Output calculated by Matlab.
      cv::Mat1f expectedReal = (cv::Mat1f(input.size()) << 120, -8, -8, -8,
                                                           -32,  0,  0,  0,
                                                           -32,  0,  0,  0,
                                                           -32,  0,  0,  0);
      cv::Mat1f expectedImag = (cv::Mat1f(input.size()) <<   0,  8,  0, -8,
                                                            32,  0,  0,  0,
                                                             0,  0,  0,  0,
                                                           -32,  0,  0,  0);

      expect($(result.splitComplexMat.real)).to.beCloseToMat($(expectedReal));
      expect($(result.splitComplexMat.imag)).to.beCloseToMat($(expectedImag));
    });
  });

  context(@"real and imag input", ^{
    it(@"should produce correct transform", ^{
      cv::Mat1f inputReal = cv::Mat1f(2, 2, 1.0);
      cv::Mat1f inputImag = cv::Mat1f(2, 2, 1.0);

      LTSplitComplexMat input = {.real = inputReal, .imag = inputImag};
      LTSplitComplexMat output;

      LTFFTProcessor *processor = [[LTFFTProcessor alloc] initWithInput:input output:&output];
      LTSplitComplexOutput *result = [processor process];

      cv::Mat1f expectedReal = cv::Mat1f::zeros(inputReal.size());
      expectedReal(0, 0) = inputReal.total();
      cv::Mat1f expectedImag = cv::Mat1f::zeros(inputImag.size());
      expectedImag(0, 0) = inputReal.total();

      expect($(result.splitComplexMat.real)).to.beCloseToMat($(expectedReal));
      expect($(result.splitComplexMat.imag)).to.beCloseToMat($(expectedImag));
    });
  });
});

context(@"inverse transform", ^{
  it(@"should produce identity when doing forward and inverse transforms", ^{
    cv::Mat1f input = cv::Mat1f(32, 32, 1.0);
    LTSplitComplexMat forwardOutput, inverseOutput;

    LTFFTProcessor *forwardProcessor = [[LTFFTProcessor alloc] initWithRealInput:input
                                                                          output:&forwardOutput];
    LTSplitComplexOutput *forwardResult = [forwardProcessor process];

    LTFFTProcessor *inverseProcessor = [[LTFFTProcessor alloc]
                                        initWithInput:forwardResult.splitComplexMat
                                        output:&inverseOutput];
    inverseProcessor.transformDirection = LTFFTTransformDirectionInverse;
    LTSplitComplexOutput *inverseResult = [inverseProcessor process];

    expect($(inverseResult.splitComplexMat.real)).to.beCloseToMat($(input));
    expect($(inverseResult.splitComplexMat.imag)).to.beCloseToScalar($(cv::Scalar(0)));
  });

  context(@"normalization", ^{
    __block cv::Mat1f expectedReal, expectedImag;
    __block LTSplitComplexMat input;

    beforeAll(^{
      cv::Mat1f inputMat = cv::Mat1f(4, 4, 1.0);
      for (int y = 0; y < inputMat.cols; ++y) {
        for (int x = 0; x < inputMat.rows; ++x) {
          inputMat(y, x) = y * inputMat.rows + x;
        }
      }
      input = {.real = inputMat, .imag = inputMat};

      // Output calculated by Matlab.
      expectedReal = (cv::Mat1f(input.real.size()) << 7.5,  0, -0.5, -1,
                                                        0,  0,    0,  0,
                                                       -2,  0,    0,  0,
                                                       -4,  0,    0,  0);
      expectedImag = (cv::Mat1f(input.imag.size()) << 7.5, -1, -0.5,  0,
                                                       -4,  0,    0,  0,
                                                       -2,  0,    0,  0,
                                                        0,  0,    0,  0);
    });

    it(@"should normalize real output only", ^{
      LTSplitComplexMat output;

      LTFFTProcessor *processor = [[LTFFTProcessor alloc] initWithInput:input output:&output];
      processor.transformDirection = LTFFTTransformDirectionInverse;
      processor.normalization = LTFFTTransformNormalizeReal;
      LTSplitComplexOutput *result = [processor process];

      expect($(result.splitComplexMat.real)).to.beCloseToMat($(expectedReal));
      expect($(result.splitComplexMat.imag)).to.beCloseToMat($(expectedImag * input.imag.total()));
    });

    it(@"should normalize imag output only", ^{
      LTSplitComplexMat output;

      LTFFTProcessor *processor = [[LTFFTProcessor alloc] initWithInput:input output:&output];
      processor.transformDirection = LTFFTTransformDirectionInverse;
      processor.normalization = LTFFTTransformNormalizeImag;
      LTSplitComplexOutput *result = [processor process];

      expect($(result.splitComplexMat.real)).to.beCloseToMat($(expectedReal * input.real.total()));
      expect($(result.splitComplexMat.imag)).to.beCloseToMat($(expectedImag));
    });
  });
});

SpecEnd
