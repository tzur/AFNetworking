// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOpenCVExtensions.h"

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

context(@"checkerboard pattern", ^{
  it(@"should raise when providing invalid board width", ^{
    cv::Vec4b firstColor = cv::Vec4b(1, 100, 200, 200);
    cv::Vec4b secondColor = cv::Vec4b(150, 50, 20, 255);
    expect(^{
      LTCheckerboardPattern(CGSizeMake(0, 1), 1, firstColor, secondColor);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when providing invalid board height", ^{
    cv::Vec4b firstColor = cv::Vec4b(1, 100, 200, 200);
    cv::Vec4b secondColor = cv::Vec4b(150, 50, 20, 255);
    expect(^{
      LTCheckerboardPattern(CGSizeMake(1, 0), 1, firstColor, secondColor);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when providing invalid tile size", ^{
    cv::Vec4b firstColor = cv::Vec4b(1, 100, 200, 200);
    cv::Vec4b secondColor = cv::Vec4b(150, 50, 20, 255);
    expect(^{
      LTCheckerboardPattern(CGSizeMake(1, 1), 0, firstColor, secondColor);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should create a checkerboard", ^{
    cv::Vec4b firstColor = cv::Vec4b(1, 100, 200, 200);
    cv::Vec4b secondColor = cv::Vec4b(150, 50, 20, 255);
    cv::Mat4b expected(3, 3, firstColor);
    expected(0, 1) = secondColor;
    expected(1, 0) = secondColor;
    expected(2, 1) = secondColor;
    expected(1, 2) = secondColor;

    cv::Mat4b board = LTCheckerboardPattern(CGSizeMakeUniform(3), 1, firstColor, secondColor);

    expect($(board)).to.equalMat($(expected));
  });

  it(@"should create a default gray and white checkerboard", ^{
    cv::Vec4b white = cv::Vec4b(255, 255, 255, 255);
    cv::Vec4b gray = cv::Vec4b(193, 193, 193, 255);
    cv::Mat4b expected(3, 3, gray);
    expected(0, 1) = white;
    expected(1, 0) = white;
    expected(2, 1) = white;
    expected(1, 2) = white;

    cv::Mat4b board = LTWhiteGrayCheckerboardPattern(CGSizeMakeUniform(3), 1);

    expect($(board)).to.equalMat($(expected));
  });

  it(@"should create a checkerboard correctly when board size isn't a multiple of the tile size", ^{
    cv::Vec4b firstColor = cv::Vec4b(70, 70, 200, 200);
    cv::Vec4b secondColor = cv::Vec4b(23, 150, 210, 255);
    cv::Mat4b expected(3, 3, firstColor);
    expected(0, 2) = secondColor;
    expected(1, 2) = secondColor;
    expected(2, 0) = secondColor;
    expected(2, 1) = secondColor;

    cv::Mat4b board = LTCheckerboardPattern(CGSizeMakeUniform(3), 2, firstColor, secondColor);

    expect($(board)).to.equalMat($(expected));
  });
});

context(@"row subset", ^{
  __block cv::Mat4b mat;

  beforeEach(^{
    mat = cv::Mat4b(8, 3);
    for (int i = 0; i < mat.rows; ++i) {
      for (int j = 0; j < mat.cols; ++j) {
        mat(i, j) = cv::Vec4b(i) + cv::Vec4b(j);
      }
    }
  });

  it(@"should return correct result on contiguous matrices", ^{
    cv::Mat4b subset = LTRowSubset(mat, {3, 4, 7});

    cv::Mat4b expected(3, mat.cols);
    mat.row(3).copyTo(expected.row(0));
    mat.row(4).copyTo(expected.row(1));
    mat.row(7).copyTo(expected.row(2));
    expect($(subset)).to.equalMat($(expected));
  });

  it(@"should return correct results on non-continuous matrices", ^{
    cv::Mat4b nonContinuous = mat(cv::Rect(0, 0, 2, 8));
    expect(nonContinuous.isContinuous()).to.beFalsy();

    cv::Mat4b subset = LTRowSubset(nonContinuous, {3, 4, 7});

    cv::Mat4b expected(3, 2);
    mat.row(3).colRange(0, 2).copyTo(expected.row(0));
    mat.row(4).colRange(0, 2).copyTo(expected.row(1));
    mat.row(7).colRange(0, 2).copyTo(expected.row(2));
    expect($(subset)).to.equalMat($(expected));
  });

  it(@"should raise when providing invalid indices", ^{
    expect(^{
      LTRowSubset(mat, {3, -1, 7});
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      LTRowSubset(mat, {3, 8, 7});
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"rotate half pi clockwise and mirror", ^{
  static const cv::Size kInputSize = cv::Size(8, 6);
  static const cv::Size kHalfSize = kInputSize / 2;

  static const cv::Rect kUpperLeft(0, 0, kHalfSize.width, kHalfSize.height);
  static const cv::Rect kUpperRight(kHalfSize.width, 0, kHalfSize.width, kHalfSize.height);
  static const cv::Rect kLowerLeft(0, kHalfSize.height, kHalfSize.width, kHalfSize.height);
  static const cv::Rect kLowerRight(kHalfSize.width, kHalfSize.height, kHalfSize.width,
                                    kHalfSize.height);

  static const cv::Scalar kColorRed(255, 0, 0, 255);
  static const cv::Scalar kColorGreen(0, 255, 0, 255);
  static const cv::Scalar kColorBlue(0, 0, 255, 255);
  static const cv::Scalar kColorWhite(255, 255, 255, 255);

  __block cv::Mat4b inputImage;

  beforeEach(^{
    inputImage = cv::Mat4b(kInputSize, cv::Vec4b(0, 0, 0, 255));
    inputImage(kUpperLeft).setTo(kColorRed);
    inputImage(kUpperRight).setTo(kColorGreen);
    inputImage(kLowerLeft).setTo(kColorBlue);
    inputImage(kLowerRight).setTo(kColorWhite);
  });

  static NSString * const kLTOpenCVExtensionsRotationExamples =
      @"LTOpenCVExtensionsRotationExamples";

  static NSString * const kLTOpenCVExtensionsRotationRotationKey =
      @"rotations";
  static NSString * const kLTOpenCVExtensionsRotationMirrorKey =
      @"mirror";
  static NSString * const kLTOpenCVExtensionsRotationUpperLeftColorKey =
      @"upperLeftColor";
  static NSString * const kLTOpenCVExtensionsRotationUpperRightColorKey =
      @"upperRightColor";
  static NSString * const kLTOpenCVExtensionsRotationLowerLeftColorKey =
      @"lowerLeftColor";
  static NSString * const kLTOpenCVExtensionsRotationLowerRightColorKey =
      @"lowerRightColor";

  sharedExamples(kLTOpenCVExtensionsRotationExamples, ^(NSDictionary *data) {
    it(@"should rotate and mirror correctly", ^{
      NSInteger cwRotations = [data[kLTOpenCVExtensionsRotationRotationKey] integerValue];
      BOOL mirror = [data[kLTOpenCVExtensionsRotationMirrorKey] boolValue];
      
      cv::Mat4b result = LTRotateHalfPiClockwise(inputImage, cwRotations, mirror);

      cv::Scalar upperLeftColor = [data[kLTOpenCVExtensionsRotationUpperLeftColorKey] scalarValue];
      cv::Scalar upperRightColor =
          [data[kLTOpenCVExtensionsRotationUpperRightColorKey] scalarValue];
      cv::Scalar lowerLeftColor = [data[kLTOpenCVExtensionsRotationLowerLeftColorKey] scalarValue];
      cv::Scalar lowerRightColor =
          [data[kLTOpenCVExtensionsRotationLowerRightColorKey] scalarValue];

      cv::Size halfOutputSize = result.size() / 2;

      cv::Rect upperLeft(0, 0, halfOutputSize.width, halfOutputSize.height);
      cv::Rect upperRight(halfOutputSize.width, 0, halfOutputSize.width, halfOutputSize.height);
      cv::Rect lowerLeft(0, halfOutputSize.height, halfOutputSize.width, halfOutputSize.height);
      cv::Rect lowerRight(halfOutputSize.width, halfOutputSize.height, halfOutputSize.width,
                          halfOutputSize.height);

      expect($(result(upperLeft))).to.equalScalar($(upperLeftColor));
      expect($(result(upperRight))).to.equalScalar($(upperRightColor));
      expect($(result(lowerLeft))).to.equalScalar($(lowerLeftColor));
      expect($(result(lowerRight))).to.equalScalar($(lowerRightColor));
    });
  });

  itBehavesLike(kLTOpenCVExtensionsRotationExamples, @{
    kLTOpenCVExtensionsRotationRotationKey: @0,
    kLTOpenCVExtensionsRotationMirrorKey: @NO,
    kLTOpenCVExtensionsRotationUpperLeftColorKey: $(kColorRed),
    kLTOpenCVExtensionsRotationUpperRightColorKey: $(kColorGreen),
    kLTOpenCVExtensionsRotationLowerLeftColorKey: $(kColorBlue),
    kLTOpenCVExtensionsRotationLowerRightColorKey: $(kColorWhite)
  });

  itBehavesLike(kLTOpenCVExtensionsRotationExamples, @{
    kLTOpenCVExtensionsRotationRotationKey: @1,
    kLTOpenCVExtensionsRotationMirrorKey: @NO,
    kLTOpenCVExtensionsRotationUpperLeftColorKey: $(kColorBlue),
    kLTOpenCVExtensionsRotationUpperRightColorKey: $(kColorRed),
    kLTOpenCVExtensionsRotationLowerLeftColorKey: $(kColorWhite),
    kLTOpenCVExtensionsRotationLowerRightColorKey: $(kColorGreen)
  });

  itBehavesLike(kLTOpenCVExtensionsRotationExamples, @{
    kLTOpenCVExtensionsRotationRotationKey: @2,
    kLTOpenCVExtensionsRotationMirrorKey: @NO,
    kLTOpenCVExtensionsRotationUpperLeftColorKey: $(kColorWhite),
    kLTOpenCVExtensionsRotationUpperRightColorKey: $(kColorBlue),
    kLTOpenCVExtensionsRotationLowerLeftColorKey: $(kColorGreen),
    kLTOpenCVExtensionsRotationLowerRightColorKey: $(kColorRed)
  });

  itBehavesLike(kLTOpenCVExtensionsRotationExamples, @{
    kLTOpenCVExtensionsRotationRotationKey: @3,
    kLTOpenCVExtensionsRotationMirrorKey: @NO,
    kLTOpenCVExtensionsRotationUpperLeftColorKey: $(kColorGreen),
    kLTOpenCVExtensionsRotationUpperRightColorKey: $(kColorWhite),
    kLTOpenCVExtensionsRotationLowerLeftColorKey: $(kColorRed),
    kLTOpenCVExtensionsRotationLowerRightColorKey: $(kColorBlue)
  });

  itBehavesLike(kLTOpenCVExtensionsRotationExamples, @{
    kLTOpenCVExtensionsRotationRotationKey: @0,
    kLTOpenCVExtensionsRotationMirrorKey: @YES,
    kLTOpenCVExtensionsRotationUpperLeftColorKey: $(kColorGreen),
    kLTOpenCVExtensionsRotationUpperRightColorKey: $(kColorRed),
    kLTOpenCVExtensionsRotationLowerLeftColorKey: $(kColorWhite),
    kLTOpenCVExtensionsRotationLowerRightColorKey: $(kColorBlue)
  });

  itBehavesLike(kLTOpenCVExtensionsRotationExamples, @{
    kLTOpenCVExtensionsRotationRotationKey: @1,
    kLTOpenCVExtensionsRotationMirrorKey: @YES,
    kLTOpenCVExtensionsRotationUpperLeftColorKey: $(kColorRed),
    kLTOpenCVExtensionsRotationUpperRightColorKey: $(kColorBlue),
    kLTOpenCVExtensionsRotationLowerLeftColorKey: $(kColorGreen),
    kLTOpenCVExtensionsRotationLowerRightColorKey: $(kColorWhite)
  });

  itBehavesLike(kLTOpenCVExtensionsRotationExamples, @{
    kLTOpenCVExtensionsRotationRotationKey: @2,
    kLTOpenCVExtensionsRotationMirrorKey: @YES,
    kLTOpenCVExtensionsRotationUpperLeftColorKey: $(kColorBlue),
    kLTOpenCVExtensionsRotationUpperRightColorKey: $(kColorWhite),
    kLTOpenCVExtensionsRotationLowerLeftColorKey: $(kColorRed),
    kLTOpenCVExtensionsRotationLowerRightColorKey: $(kColorGreen)
  });

  itBehavesLike(kLTOpenCVExtensionsRotationExamples, @{
    kLTOpenCVExtensionsRotationRotationKey: @3,
    kLTOpenCVExtensionsRotationMirrorKey: @YES,
    kLTOpenCVExtensionsRotationUpperLeftColorKey: $(kColorWhite),
    kLTOpenCVExtensionsRotationUpperRightColorKey: $(kColorGreen),
    kLTOpenCVExtensionsRotationLowerLeftColorKey: $(kColorBlue),
    kLTOpenCVExtensionsRotationLowerRightColorKey: $(kColorRed)
  });

  itBehavesLike(kLTOpenCVExtensionsRotationExamples, @{
    kLTOpenCVExtensionsRotationRotationKey: @-1,
    kLTOpenCVExtensionsRotationMirrorKey: @YES,
    kLTOpenCVExtensionsRotationUpperLeftColorKey: $(kColorWhite),
    kLTOpenCVExtensionsRotationUpperRightColorKey: $(kColorGreen),
    kLTOpenCVExtensionsRotationLowerLeftColorKey: $(kColorBlue),
    kLTOpenCVExtensionsRotationLowerRightColorKey: $(kColorRed)
  });
});

SpecEnd
