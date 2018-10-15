// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LT3DLUT+Operations.h"

static LT3DLUT *LTCreateLinearLUT(int rSize, float rCoeff, float rBias, int gSize, float gCoeff,
                                  float gBias, int bSize, float bCoeff, float bBias) {
  std::vector<int> dimensions = {bSize, gSize, rSize};

  cv::Mat4b mat((int)dimensions.size(), dimensions.data());
  uchar *rgbaColor = mat.data;
  for (int b = 0; b < bSize; ++b) {
    for (int g = 0; g < gSize; ++g) {
      for (int r = 0; r < rSize; ++r) {
        rgbaColor[0] = std::clamp<uchar>(rBias + rCoeff * (r * 255.0 / (rSize - 1)), 0, 255);
        rgbaColor[1] = std::clamp<uchar>(gBias + gCoeff * (g * 255.0 / (gSize - 1)), 0, 255);
        rgbaColor[2] = std::clamp<uchar>(bBias + bCoeff * (b * 255.0 / (bSize - 1)), 0, 255);
        rgbaColor[3] = 255;

        rgbaColor += 4;
      }
    }
  }
  return [[LT3DLUT alloc] initWithLatticeMat:mat];;
}

SpecBegin(LT3DLUTComposer)

context(@"positive testing", ^{
  it(@"should create LUT equal to second when first is identity", ^{
    LT3DLUT *first = [LT3DLUT identity];
    LT3DLUT *second = LTCreateLinearLUT(2, 0.5, 0, 2, 1, 0, 2, 1, 0);
    LT3DLUT *result = [first composeWith:second];

    expect($(result.packedMat)).to.equalMat($(second.packedMat));
  });

  it(@"should create LUT equal to first when second is identity", ^{
    LT3DLUT *first = LTCreateLinearLUT(2, 0.5, 0, 2, 1, 0, 2, 1, 0);
    LT3DLUT *second = [LT3DLUT identity];
    LT3DLUT *result = [first composeWith:second];

    expect($(result.packedMat)).to.equalMat($(first.packedMat));
  });

  it(@"should create correct LUT from 2 linear transformations on red channel", ^{
    LT3DLUT *first = LTCreateLinearLUT(2, 0.5, 0, 2, 1, 0, 2, 1, 0);
    LT3DLUT *second = LTCreateLinearLUT(2, 0.5, 0.5, 2, 1, 0, 2, 1, 0);
    LT3DLUT *expectedResult = LTCreateLinearLUT(2, 0.25, 0.5, 2, 1, 0, 2, 1, 0);

    LT3DLUT *result = [first composeWith:second];
    expect($(result.packedMat)).to.equalMat($(expectedResult.packedMat));
  });

  it(@"should create correct LUT from 2 linear transformations on green channel", ^{
    LT3DLUT *first = LTCreateLinearLUT(2, 1, 0, 2, 0.5, 0, 2, 1, 0);
    LT3DLUT *second = LTCreateLinearLUT(2, 1, 0, 2, 0.5, 0.5, 2, 1, 0);
    LT3DLUT *expectedResult = LTCreateLinearLUT(2, 1, 0, 2, 0.25, 0.5, 2, 1, 0);

    LT3DLUT *result = [first composeWith:second];
    expect($(result.packedMat)).to.equalMat($(expectedResult.packedMat));
  });

  it(@"should create correct LUT from 2 linear transformations on blue channel", ^{
    LT3DLUT *first = LTCreateLinearLUT(2, 1, 0, 2, 1, 0, 2, 0.5, 0);
    LT3DLUT *second = LTCreateLinearLUT(2, 1, 0, 2, 1, 0, 2, 0.5, 0.5);
    LT3DLUT *expectedResult = LTCreateLinearLUT(2, 1, 0, 2, 1, 0, 2, 0.25, 0.5);

    LT3DLUT *result = [first composeWith:second];
    expect($(result.packedMat)).to.equalMat($(expectedResult.packedMat));
  });

  it(@"should create correct LUT from linear transformations on red and green channels", ^{
    LT3DLUT *first = LTCreateLinearLUT(2, 0.5, 0, 2, 1, 0, 2, 1, 0);
    LT3DLUT *second = LTCreateLinearLUT(2, 1, 0, 2, 0.5, 0, 2, 1, 0);
    LT3DLUT *expectedResult = LTCreateLinearLUT(2, 0.5, 0, 2, 0.5, 0, 2, 1, 0);

    LT3DLUT *result = [first composeWith:second];
    expect($(result.packedMat)).to.equalMat($(expectedResult.packedMat));
  });

  it(@"should create correct LUT from linear transformations on red and blue channels", ^{
    LT3DLUT *first = LTCreateLinearLUT(2, 0.5, 0, 2, 1, 0, 2, 1, 0);
    LT3DLUT *second = LTCreateLinearLUT(2, 1, 0, 2, 1, 0, 2, 0.5, 0);
    LT3DLUT *expectedResult = LTCreateLinearLUT(2, 0.5, 0, 2, 1, 0, 2, 0.5, 0);

    LT3DLUT *result = [first composeWith:second];
    expect($(result.packedMat)).to.equalMat($(expectedResult.packedMat));
  });

  it(@"should create correct LUT from linear transformations on green and blue channels", ^{
    LT3DLUT *first = LTCreateLinearLUT(2, 1, 0, 2, 0.5, 0, 2, 1, 0);
    LT3DLUT *second = LTCreateLinearLUT(2, 1, 0, 2, 1, 0, 2, 0.5, 0);
    LT3DLUT *expectedResult = LTCreateLinearLUT(2, 1, 0, 2, 0.5, 0, 2, 0.5, 0);

    LT3DLUT *result = [first composeWith:second];
    expect($(result.packedMat)).to.equalMat($(expectedResult.packedMat));
  });

  it(@"should create correct LUT for 2 non-cubic LUTs of same lattice size", ^{
    LT3DLUT *first = LTCreateLinearLUT(4, 0.5, 0, 5, 1, 0, 6, 1, 0);
    LT3DLUT *second = LTCreateLinearLUT(4, 0.5, 0.5, 5, 1, 0, 6, 1, 0);
    LT3DLUT *expectedResult = LTCreateLinearLUT(4, 0.25, 0.5, 5, 1, 0, 6, 1, 0);

    LT3DLUT *result = [first composeWith:second];
    expect($(result.packedMat)).to.beCloseToMatWithin($(expectedResult.packedMat), @1);
  });
});

context(@"negative testing", ^{
  it(@"should raise when input lattice has size smaller than 2", ^{
    LT3DLUT *first = LTCreateLinearLUT(2, 0.5, 0, 2, 1, 0, 2, 1, 0);
    LT3DLUT *second = LTCreateLinearLUT(3, 0.5, 0.5, 3, 1, 0, 3, 1, 0);
    expect(^{
      __unused LT3DLUT *result = [first composeWith:second];
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
