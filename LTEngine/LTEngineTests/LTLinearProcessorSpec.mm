// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "LTLinearProcessor.h"

#import "LTTexture+Factory.h"

SpecBegin(LTLinearProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTLinearProcessor *processor;

static const GLKMatrix4 kMatrix = GLKMatrix4Make(0.01, 0.02, 0.03, 0.04,
                                                 0.05, 0.06, 0.07, 0.08,
                                                 0.09, 0.10 ,0.11, 0.12,
                                                 0.13, 0.14, 0.15, 0.16);

static const LTVector4 kConstant = -LTVector4(0.1, 0.2, 0.3, 0.1);

beforeEach(^{
  input = [LTTexture textureWithImage:cv::Mat4b(1, 1, (cv::Vec4b)LTVector4::ones())];
  output = [LTTexture textureWithPropertiesOf:input];
});

afterEach(^{
  input = nil;
  output = nil;
});

context(@"initialization", ^{
  beforeEach(^{
    processor = [[LTLinearProcessor alloc] initWithInput:input output:output];
  });

  afterEach(^{
    processor = nil;
  });

  it(@"should initialize correctly", ^{
    expect(processor).toNot.beNil();
    expect($(processor.matrix)).to.equal($(GLKMatrix4Identity));
    expect(processor.constant).to.equal(LTVector4::zeros());
  });
});

context(@"processing", ^{
  context(@"regular", ^{
    beforeEach(^{
      processor = [[LTLinearProcessor alloc] initWithInput:input output:output];
    });

    afterEach(^{
      processor = nil;
    });

    it(@"should produce the input texture as output on default", ^{
      [processor process];
      expect($(output.image)).to.equalMat($(input.image));
    });

    it(@"should add constant vector to pixels of input texture", ^{
      cv::Mat expectedResult = (cv::Mat_<CGFloat>(4, 1) << 230, 204, 179, 230);
      expectedResult.convertTo(expectedResult, CV_8UC1);
      expectedResult = expectedResult.reshape(4);

      processor.constant = kConstant;
      [processor process];

      expect($(output.image)).to.beCloseToMatPSNR($(expectedResult), 49);
    });

    it(@"should multiply pixels of input texture with a matrix", ^{
      cv::Mat expectedResult = (cv::Mat_<CGFloat>(4, 1) << 71, 82, 92, 102);
      expectedResult.convertTo(expectedResult, CV_8UC1);
      expectedResult = expectedResult.reshape(4);

      processor.matrix = kMatrix;
      [processor process];

      expect($(output.image)).to.equalMat($(expectedResult));
    });

    it(@"should multiply pixels of input texture with a matrix and add constant vector", ^{
      cv::Mat expectedResult = (cv::Mat_<CGFloat>(4, 1) << 46, 31, 15, 76);
      expectedResult.convertTo(expectedResult, CV_8UC1);
      expectedResult = expectedResult.reshape(4);

      processor.matrix = kMatrix;
      processor.constant = kConstant;
      [processor process];

      expect($(output.image)).to.beCloseToMatPSNR($(expectedResult), 50);
    });
  });

  context(@"in situ", ^{
    beforeEach(^{
      processor = [[LTLinearProcessor alloc] initWithInput:input output:input];
    });

    afterEach(^{
      processor = nil;
    });

    it(@"should produce the input texture as output on default", ^{
      LTTexture *originalTexture = [input clone];

      [processor process];

      expect($(input.image)).to.equalMat($(originalTexture.image));
    });

    it(@"should add constant vector to pixels of input texture", ^{
      cv::Mat expectedResult = (cv::Mat_<CGFloat>(4, 1) << 230, 204, 179, 230);
      expectedResult.convertTo(expectedResult, CV_8UC1);
      expectedResult = expectedResult.reshape(4);

      processor.constant = kConstant;
      [processor process];

      expect($(input.image)).to.beCloseToMatPSNR($(expectedResult), 49);
    });

    it(@"should multiply pixels of input texture with a matrix", ^{
      cv::Mat expectedResult = (cv::Mat_<CGFloat>(4, 1) << 71, 82, 92, 102);
      expectedResult.convertTo(expectedResult, CV_8UC1);
      expectedResult = expectedResult.reshape(4);

      processor.matrix = kMatrix;
      [processor process];

      expect($(input.image)).to.equalMat($(expectedResult));
    });

    it(@"should multiply pixels of input texture with a matrix and add constant vector", ^{
      cv::Mat expectedResult = (cv::Mat_<CGFloat>(4, 1) << 46, 31, 15, 76);
      expectedResult.convertTo(expectedResult, CV_8UC1);
      expectedResult = expectedResult.reshape(4);

      processor.matrix = kMatrix;
      processor.constant = kConstant;
      [processor process];

      expect($(input.image)).to.beCloseToMatPSNR($(expectedResult), 50);
    });
  });
});

SpecEnd
