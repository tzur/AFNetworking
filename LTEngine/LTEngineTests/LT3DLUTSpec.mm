// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LT3DLUT.h"

#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"

SpecBegin(LT3DLUT);

static const int kUnapportedMatType = CV_32FC4;

context(@"3D mat initialization", ^{
  context(@"properties set validation", ^{
    it(@"should initialized 3D mat property correctly", ^{
      int matDims[] = {4, 4, 4};
      cv::Mat4b mat(3, matDims, cv::Scalar(cv::Vec4b(1, 1, 1, 1)));
      LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];
      expect($(lut.mat)).to.equalMat($(mat));
    });

    it(@"should have correct dimension sizes", ^{
      int matDims[] = {2, 3, 4};
      cv::Mat4b lattice(3, matDims);
      LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:lattice];
      expect(lut.latticeSizes.rDimensionSize).to.equal(4);
      expect(lut.latticeSizes.gDimensionSize).to.equal(3);
      expect(lut.latticeSizes.bDimensionSize).to.equal(2);
    });
  });

  context(@"packed mat validation", ^{
    it(@"should return a correct packed mat", ^{
      int matDims[] = {2, 2, 2};
      cv::Mat4b mat(3, matDims);
      for (int z = 0; z < 2; ++z) {
        for (int y = 0; y < 2; ++y) {
          for (int x = 0; x < 2; ++x) {
            char value = (char)(4 * z + 2 * y + x);
            mat(z, y, x) = cv::Vec4b(value, value, value, value);
          }
        }
      }
      LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];

      cv::Mat4b packedMat(4, 2);
      for (int y = 0; y < 4; ++y) {
        for (int x = 0; x < 2; ++x) {
          char value = (char)(2 * y + x);
          packedMat(y, x) = cv::Vec4b(value, value, value, value);
        }
      }
      expect($([lut packedMat])).to.equalMat($(packedMat));
    });
  });

  context(@"initialization with non valid arguments", ^{
    it(@"should raise when initializing with a non 3D matrix", ^{
      cv::Mat4b mat(2, 2);
      expect(^{
        __unused LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input lattice has size smaller than 2", ^{
      cv::Mat4b mat;

      int dimSizes1[]{1, 4, 4};
      mat = cv::Mat4b(3, dimSizes1);
      expect(^{
        __unused LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];
      }).to.raise(NSInvalidArgumentException);

      int dimSizes2[]{4, 1, 4};
      mat = cv::Mat4b(3, dimSizes2);
      expect(^{
        __unused LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];
      }).to.raise(NSInvalidArgumentException);

      int dimSizes3[]{4, 4, 1};
      mat = cv::Mat4b(3, dimSizes3);
      expect(^{
        __unused LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input lattice has size that is out of limits", ^{
      cv::Mat4b mat;

      int dimSizes1[]{257, 4, 4};
      mat = cv::Mat4b(3, dimSizes1);
      expect(^{
        __unused LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];
      }).to.raise(NSInvalidArgumentException);

      int dimSizes2[]{4, 257, 4};
      mat = cv::Mat4b(3, dimSizes2);
      expect(^{
        __unused LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];
      }).to.raise(NSInvalidArgumentException);

      int dimSizes3[]{4, 4, 257};
      mat = cv::Mat4b(3, dimSizes3);
      expect(^{
        __unused LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input lattice has an unsupported type", ^{
      int dimSizes3[]{4, 4, 4};
      cv::Mat mat(3, dimSizes3, kUnapportedMatType);
      expect(^{
        __unused LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"factory", ^{
  context(@"packed mat factory", ^{
    context(@"properties set validation", ^{
      it(@"should initialize 3D mat correctly", ^{
        cv::Mat4b packedMat(4, 2);
        for (int y = 0; y < 4; ++y) {
          for (int x = 0; x < 2; ++x) {
            char value = (char)(2 * y + x);
            packedMat(y, x) = cv::Vec4b(value, value, value, value);
          }
        }
        LT3DLUT *lut = [LT3DLUT lutFromPackedMat:packedMat];

        int expectedMatDims[] = {2, 2, 2};
        cv::Mat4b expected(3, expectedMatDims);
        for (int z = 0; z < 2; ++z) {
          for (int y = 0; y < 2; ++y) {
            for (int x = 0; x < 2; ++x) {
              char value = (char)(4 * z + 2 * y + x);
              expected(z, y, x) = cv::Vec4b(value, value, value, value);
            }
          }
        }
        expect($(lut.mat)).to.equalMat($(expected));
      });

      it(@"should have correct dimension sizes", ^{
        int matDims[] = {2, 2, 2};
        cv::Mat4b mat(3, matDims);
        int textureDims[] = {4, 2};
        cv::Mat4b packedMat(2, textureDims);
        LT3DLUT *lut = [LT3DLUT lutFromPackedMat:packedMat];

        expect(lut.latticeSizes.rDimensionSize).to.equal(2);
        expect(lut.latticeSizes.gDimensionSize).to.equal(2);
        expect(lut.latticeSizes.bDimensionSize).to.equal(2);
      });

    });

    context(@"packed mat validation", ^{
      it(@"should have the same packed mat when created from packed mat", ^{
        cv::Mat4b packedMat(4, 2, cv::Scalar(cv::Vec4b(1, 1, 1, 1)));
        LT3DLUT *lut = [LT3DLUT lutFromPackedMat:packedMat];
        expect($([lut packedMat])).to.equalMat($(packedMat));
      });
    });

    context(@"non valid packed mat", ^{
      it(@"should raise when packed mat is not 2 dimensional", ^{
        int matDims[] = {2, 2, 2};
        cv::Mat4b packedMat(3, matDims);
        expect(^{
          __unused LT3DLUT *lut = [LT3DLUT lutFromPackedMat:packedMat];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when packed mat dimensions are not of the form (x^2, x)", ^{
        cv::Mat4b packedMat(2, 4);
        expect(^{
          __unused LT3DLUT *lut = [LT3DLUT lutFromPackedMat:packedMat];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when packed mat has size smaller than 2", ^{
        cv::Mat4b packedMat(1, 1);
        expect(^{
          __unused LT3DLUT *lut = [LT3DLUT lutFromPackedMat:packedMat];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when packed mat is of unsupported type", ^{
        cv::Mat packedMat(4, 2, kUnapportedMatType);
        expect(^{
          __unused LT3DLUT *lut = [LT3DLUT lutFromPackedMat:packedMat];
        }).to.raise(NSInvalidArgumentException);
      });
    });

    context(@"identity factory", ^{
      __block LT3DLUT *identity;

      beforeEach(^{
        identity = [LT3DLUT identity];
      });

      afterEach(^{
        identity = nil;
      });

      it(@"should have a correct identity mat", ^{
        cv::Mat identityLUTImage =  LTLoadMat([self class], @"LT3DLUTIdentity2x2x2.png");
        expect($([identity packedMat])).to.beCloseToMat($(identityLUTImage));
      });

      it(@"should have correct size", ^{
        expect(identity.latticeSizes.rDimensionSize).to.equal(2);
        expect(identity.latticeSizes.gDimensionSize).to.equal(2);
        expect(identity.latticeSizes.bDimensionSize).to.equal(2);
      });
    });
  });
});

context(@"equality", ^{
  it(@"should identify identical lookup tables", ^{
    int matDims[] = {2, 3, 4};
    cv::Mat4b mat1 = cv::Mat4b(3, matDims, cv::Scalar(0));
    LT3DLUT *lut1 = [[LT3DLUT alloc] initWithLatticeMat:mat1];

    cv::Mat4b mat2 = cv::Mat4b(3, matDims, cv::Scalar(0));
    LT3DLUT *lut2 = [[LT3DLUT alloc] initWithLatticeMat:mat2];
    expect(lut1).to.equal(lut2);
  });

  it(@"should identify difference between a lookup table and an object of another type", ^{
    int matDims[] = {2, 3, 4};
    cv::Mat4b mat = cv::Mat4b(3, matDims, cv::Scalar(0));
    LT3DLUT *lut = [[LT3DLUT alloc] initWithLatticeMat:mat];

    NSObject *dummyObject = [[NSObject alloc] init];
    expect(lut).notTo.equal(dummyObject);
  });

  it(@"should identify differences in lookup table sizes", ^{
    int matDims1[] = {2, 2, 2};
    cv::Mat4b mat1 = cv::Mat4b(3, matDims1, cv::Scalar(0));
    LT3DLUT *lut1 = [[LT3DLUT alloc] initWithLatticeMat:mat1];

    int matDims2[] = {3, 2, 2};
    cv::Mat4b mat2 = cv::Mat4b(3, matDims2, cv::Scalar(0));
    LT3DLUT *lut2 = [[LT3DLUT alloc] initWithLatticeMat:mat2];
    expect(lut1).notTo.equal(lut2);

    int matDims3[] = {2, 3, 2};
    cv::Mat4b mat3 = cv::Mat4b(3, matDims3, cv::Scalar(0));
    LT3DLUT *lut3 = [[LT3DLUT alloc] initWithLatticeMat:mat3];
    expect(lut1).notTo.equal(lut3);

    int matDims4[] = {2, 2, 3};
    cv::Mat4b mat4 = cv::Mat4b(3, matDims4, cv::Scalar(0));
    LT3DLUT *lut4 = [[LT3DLUT alloc] initWithLatticeMat:mat4];
    expect(lut1).notTo.equal(lut4);
  });

  it(@"should identify difference in lookup table lattice mat", ^{
    int matDims[] = {2, 3, 4};
    cv::Mat4b mat1 = cv::Mat4b(3, matDims, cv::Scalar(0));
    LT3DLUT *lut1 = [[LT3DLUT alloc] initWithLatticeMat:mat1];

    cv::Mat4b mat2 = cv::Mat4b(3, matDims, cv::Scalar(0));
    mat2(0, 0) = cv::Vec4b(255, 0, 0, 0);
    LT3DLUT *lut2 = [[LT3DLUT alloc] initWithLatticeMat:mat2];

    expect(lut1).notTo.equal(lut2);
  });
});

SpecEnd
