// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOpenCVExtensions.h"

#import "LTTestUtils.h"

using half_float::half;

SpecBegin(LTOpenCVExtensions)

context(@"mat conversion", ^{
  it(@"should not change mat when type is similar to input", ^{
    cv::Mat4b input(16, 16);
    input.setTo(cv::Vec4b(1, 2, 3, 4));

    cv::Mat output;
    LTConvertMat(input, &output, CV_8UC4);

    expect(output.type()).to.equal(CV_8UC4);
    expect(LTCompareMat(input, output)).to.beTruthy();
  });

  context(@"different number of channels", ^{
    it(@"should truncate channels when number of channels is less than the input's", ^{
      cv::Vec4b value(1, 2, 3, 4);
      cv::Mat4b input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_8UC2);

      cv::Mat2b truncated(input.rows, input.cols, CV_8UC2);
      truncated.setTo(cv::Vec2b(value[0], value[1]));

      expect(output.type()).to.equal(CV_8UC2);
      expect(LTCompareMat(truncated, output)).to.beTruthy();
    });

    it(@"should pad extra channels with zeros", ^{
      cv::Vec2b value(1, 2);
      cv::Mat2b input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_8UC4);

      cv::Scalar paddedValue(1, 2, 0, 0);
      expect(LTCompareMatWithValue(paddedValue, output)).to.beTruthy();
    });
  });

  context(@"different depth", ^{
    it(@"should scale from ubyte to float", ^{
      cv::Vec4b value(255, 0, 128, 255);
      cv::Mat4b input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_32FC4);

      cv::Scalar convertedValue(1, 0, 0.5, 1);
      expect(LTFuzzyCompareMatWithValue(convertedValue, output, 1.0/255.0)).to.beTruthy();
    });

    it(@"should scale from float to ubyte", ^{
      cv::Vec4f value(1, 0, 0.5, 1);
      cv::Mat4f input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_8UC4);

      cv::Scalar convertedValue(255, 0, 128, 255);
      expect(LTFuzzyCompareMatWithValue(convertedValue, output)).to.beTruthy();
    });

    it(@"should convert half-float to float", ^{
      cv::Vec4hf value(half(0.5), half(-1.0), half(0.5), half(1.0));
      cv::Mat4hf input(16, 16);
      input.setTo(value);

      cv::Mat4f output;
      LTConvertMat(input, &output, CV_32FC4);

      expect(LTFuzzyCompareMatWithValue(cv::Scalar(0.5, -1, 0.5, 1), output)).to.beTruthy();
    });

    it(@"should convert float to half-float", ^{
      cv::Vec4f value(0.5, -1.0, 0.5, 1.0);
      cv::Mat4f input(16, 16);
      input.setTo(value);

      cv::Mat4hf output;
      LTConvertMat(input, &output, CV_16FC4);

      cv::Mat4hf expected(input.size());
      expected.setTo(cv::Vec4hf(half(0.5), half(-1.0), half(0.5), half(1.0)));
      
      expect(LTFuzzyCompareMat(expected, output, 1.0/255.0)).to.beTruthy();
    });
  });

  context(@"different depth and channels", ^{
    it(@"should convert depth and number of channels for float", ^{
      cv::Vec4f value(1, 0.5, 0.5, 1);
      cv::Mat4f input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_8UC2);

      cv::Scalar convertedValue(255, 128);
      expect(LTFuzzyCompareMatWithValue(convertedValue, output)).to.beTruthy();
    });

    it(@"should convert depth and number of channels for half-float", ^{
      cv::Vec4hf value(half(1), half(0.5), half(0.5), half(1));
      cv::Mat4hf input(16, 16);
      input.setTo(value);

      cv::Mat output;
      LTConvertMat(input, &output, CV_8UC2);

      cv::Scalar convertedValue(255, 128);
      expect(LTFuzzyCompareMatWithValue(convertedValue, output)).to.beTruthy();
    });
  });
});

context(@"fft shift", ^{
  it(@"should shift correctly", ^{
    cv::Mat1f mat = (cv::Mat1f(2, 2) << 1, 2, 3, 4);
    LTInPlaceFFTShift(&mat);

    cv::Mat1f expected = (cv::Mat1f(2, 2) << 4, 3, 2, 1);

    expect($(expected)).to.equalMat($(mat));
  });
});

context(@"pre-divide", ^{
  it(@"should pre-divide correctly", ^{
    cv::Mat4b mat(2, 2, cv::Vec4b(10, 20, 30, 51));
    cv::Mat4b expected(2, 2, cv::Vec4b(50, 100, 150, 51));
    LTPreDivideMat(&mat);
    expect($(mat)).to.equalMat($(expected));
  });
  
  it(@"should pre-divide and clamp to 255", ^{
    cv::Mat4b mat(2, 2, cv::Vec4b(10, 20, 30, 1));
    cv::Mat4b expected(2, 2, cv::Vec4b(255, 255, 255, 1));
    LTPreDivideMat(&mat);
    expect($(mat)).to.equalMat($(expected));
  });
  
  it(@"should return black when alpha is zero", ^{
    cv::Mat4b mat(2, 2, cv::Vec4b(10, 20, 30, 0));
    cv::Mat4b expected(2, 2, cv::Vec4b());
    LTPreDivideMat(&mat);
    expect($(mat)).to.equalMat($(expected));
  });
  
  it(@"should fail when trying to pre-divide a non byte rgba mat", ^{
    expect(^{
      cv::Mat4f mat1f(2, 2);
      LTPreDivideMat(&mat1f);
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      cv::Mat3b mat3b(2, 2);
      LTPreDivideMat(&mat3b);
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"load image", ^{
  it(@"should load image", ^{
    UIImage *image = LTLoadImage([self class], @"White.jpg");

    expect(image).toNot.beNil();
    expect(image.size).to.equal(CGSizeMake(16, 16));
  });

  it(@"should fail when loading non-existing image", ^{
    expect(^{
      UIImage __unused *image = LTLoadImage([self class], @"_Invalid.png");
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should load mat", ^{
    cv::Mat mat = LTLoadMat([self class], @"White.jpg");

    expect(mat.type()).to.equal(CV_8UC4);
    expect(mat.rows).to.equal(16);
    expect(mat.cols).to.equal(16);
  });

  it(@"should fail when loading non-existing mat", ^{
    expect(^{
      cv::Mat __unused mat = LTLoadMat([self class], @"_Invalid.png");
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should load mat from bundle", ^{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    cv::Mat mat = LTLoadMatFromBundle(bundle, @"White.jpg");

    expect(mat.type()).to.equal(CV_8UC4);
    expect(mat.rows).to.equal(16);
    expect(mat.cols).to.equal(16);
  });
  
  it(@"should load mat and pre-divide it", ^{
    cv::Mat matWithoutPreDivision = LTLoadMat([self class], @"SemiTransparentGray.png", NO);
    cv::Mat matWithPreDivision = LTLoadMat([self class], @"SemiTransparentGray.png", YES);
    expect($(matWithPreDivision)).notTo.equalMat($(matWithoutPreDivision));
    
    cv::Mat expected = LTLoadMat([self class], @"SemiTransparentGray.png");
    expect($(matWithoutPreDivision)).to.equalMat($(expected));
    
    LTPreDivideMat(&expected);
    expect($(matWithPreDivision)).to.equalMat($(expected));
  });
});

context(@"generate mat", ^{
  it(@"should generate a square gaussian mat", ^{
    const CGSize kTargetSize = CGSizeMake(256, 256);
    cv::Mat mat = LTCreateGaussianMat(kTargetSize, 0.3);
    expect(mat.rows).to.equal(kTargetSize.height);
    expect(mat.cols).to.equal(kTargetSize.width);
    expect(mat.type()).to.equal(CV_16U);

    cv::Mat1b convertedGray(kTargetSize.height, kTargetSize.width);
    cv::Mat4b convertedRGB(kTargetSize.height, kTargetSize.width);
    LTConvertHalfFloat<half, uchar>(mat, &convertedGray, 255);
    cv::cvtColor(convertedGray, convertedRGB, CV_GRAY2RGBA);
    
    cv::Mat expected = LTLoadMat([self class], @"GaussianSquare.png");
    expect($(convertedRGB)).to.beCloseToMat($(expected));
  });
  
  it(@"should generate anisotropic gaussian mat", ^{
    const CGSize kTargetSize = CGSizeMake(512, 256);
    cv::Mat mat = LTCreateGaussianMat(kTargetSize, 0.3);
    expect(mat.rows).to.equal(kTargetSize.height);
    expect(mat.cols).to.equal(kTargetSize.width);
    expect(mat.type()).to.equal(CV_16U);
    
    cv::Mat1b convertedGray(kTargetSize.height, kTargetSize.width);
    cv::Mat4b convertedRGB(kTargetSize.height, kTargetSize.width);
    LTConvertHalfFloat<half, uchar>(mat, &convertedGray, 255);
    cv::cvtColor(convertedGray, convertedRGB, CV_GRAY2RGBA);
    
    cv::Mat expected = LTLoadMat([self class], @"GaussianAnisotropic.png");
    expect($(convertedRGB)).to.beCloseToMat($(expected));
  });

  it(@"should generate a normalized gaussian mat", ^{
    const CGSize kTargetSize = CGSizeMake(256, 256);
    cv::Mat mat = LTCreateGaussianMat(kTargetSize, 0.3, YES);
    expect(mat.rows).to.equal(kTargetSize.height);
    expect(mat.cols).to.equal(kTargetSize.width);
    expect(mat.type()).to.equal(CV_16U);

    cv::Mat1b convertedGray(kTargetSize.height, kTargetSize.width);
    cv::Mat4b convertedRGB(kTargetSize.height, kTargetSize.width);
    LTConvertHalfFloat<half, uchar>(mat, &convertedGray, 255);
    cv::cvtColor(convertedGray, convertedRGB, CV_GRAY2RGBA);

    cv::Mat4b expected = LTLoadMat([self class], @"GaussianSquare.png");
    cv::Mat1b expectedGray(expected.size());
    cv::cvtColor(expected, expectedGray, CV_RGBA2GRAY);
    float factor = *std::max_element(expectedGray.begin(), expectedGray.end()) / 255.0;
    std::transform(expected.begin(), expected.end(), expected.end(),
                   [factor](const cv::Vec4b &pixel) {
      return LTLTVector4ToVec4b(LTCVVec4bToLTVector4(pixel) / factor);
    });
    expect($(convertedRGB)).to.beCloseToMat($(expected));
  });
});

context(@"GLKMatrix conversion", ^{
  it(@"should convert a GLKMatrix3 to a mat", ^{
    expect($(LTMatFromGLKMatrix3(GLKMatrix3Identity))).to.beCloseToMat($(cv::Mat1f::eye(3, 3)));
    GLKMatrix3 matrix = GLKMatrix3Make(1, 2, 3, -4, -5, -6, M_PI, M_E, M_SQRT2);
    cv::Mat1f expected = (cv::Mat1f(3, 3) << 1, 2, 3, -4, -5, -6, M_PI, M_E, M_SQRT2);
    expect($(LTMatFromGLKMatrix3(matrix))).to.beCloseToMat($(expected));
  });
});

context(@"pixel value", ^{
  static const cv::Point2i kPoint(1, 0);

  it(@"should return a correct pixel value on a single channel byte mat", ^{
    cv::Mat1b mat(2, 2);
    mat(0, 0) = 0;
    mat(0, 1) = 50;
    mat(1, 0) = 100;
    mat(1, 1) = 150;

    LTVector4 actual = LTPixelValueFromImage(mat, kPoint);
    LTVector4 expected = LTVector4(cv::Vec4b(50, 0, 0, 0));
    expect(expected).to.equal(actual);
  });

  it(@"should return a correct pixel value on a single channel float mat", ^{
    cv::Mat1f mat(2, 2);
    mat(0, 0) = 0.0;
    mat(0, 1) = 0.25;
    mat(1, 0) = 0.5;
    mat(1, 1) = 0.75;

    LTVector4 actual = LTPixelValueFromImage(mat, kPoint);
    LTVector4 expected = LTVector4(0.25, 0, 0, 0);
    expect(expected).to.equal(actual);
  });

  it(@"should return a correct pixel value on a multi channel byte mat", ^{
    cv::Mat4b mat(2, 2);
    mat(0, 0) = cv::Vec4b(10, 20, 30, 40);
    mat(0, 1) = cv::Vec4b(50, 60, 70, 80);
    mat(1, 0) = cv::Vec4b(90, 100, 110, 120);
    mat(1, 1) = cv::Vec4b(130, 140, 150, 160);

    LTVector4 actual = LTPixelValueFromImage(mat, kPoint);
    LTVector4 expected = LTVector4(cv::Vec4b(50, 60, 70, 80));
    expect(expected).to.equal(actual);
  });

  it(@"should return a correct pixel value on a multi channel float mat", ^{
    cv::Mat4f mat(2, 2);
    mat(0, 0) = cv::Vec4f(0.1, 0.2, 0.3, 0.4);
    mat(0, 1) = cv::Vec4f(0.2, 0.3, 0.4, 0.5);
    mat(1, 0) = cv::Vec4f(0.3, 0.4, 0.5, 0.6);
    mat(1, 1) = cv::Vec4f(0.4, 0.5, 0.6, 0.7);

    LTVector4 actual = LTPixelValueFromImage(mat, kPoint);
    LTVector4 expected = LTVector4(0.2, 0.3, 0.4, 0.5);
    expect(expected).to.equal(actual);
  });
});

SpecEnd
