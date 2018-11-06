// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LT3DLUTTextureAtlasProvider.h"

#import "LT3DLUT.h"
#import "LT3DLUTTextureAtlas.h"
#import "LTTexture.h"

SpecBegin(LT3DLUTTextureAtlasProvider)

context(@"initialization", ^{
  it(@"should raise when initializing with an empty LUTs map", ^{
    expect(^{
      LT3DLUTTextureAtlasProvider __unused *provider =
          [[LT3DLUTTextureAtlasProvider alloc] initWithLUTs:@{}];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"atlas producing", ^{
  static NSString * const kLUTsKey1 = @"LUT1";
  static NSString * const kLUTsKey2 = @"LUT2";

  __block cv::Mat4b lut1PackedMat;
  __block cv::Mat4b lut2PackedMat;
  __block NSDictionary<NSString *, LT3DLUT *> *luts;
  __block LT3DLUTTextureAtlas *atlas;

  beforeEach(^{
    LT3DLUT *lut1 = [LT3DLUT identity];
    lut1PackedMat = [lut1 packedMat];

    int lut2Dims[]{4, 3, 2};
    cv::Mat4b lut2Lattice(3, lut2Dims, cv::Vec4b(128, 128, 128, 255));
    LT3DLUT *lut2 = [[LT3DLUT alloc] initWithLatticeMat:lut2Lattice];
    lut2PackedMat = [lut2 packedMat];

    luts = @{kLUTsKey1 : lut1, kLUTsKey2 : lut2};
    atlas = [[[LT3DLUTTextureAtlasProvider alloc] initWithLUTs:luts] textureAtlas];
  });

  context(@"spatial data map", ^{
    it(@"should have correct keys", ^{
      expect(atlas.spatialDataMap.size()).to.equal(2);
      const auto &spatialData1 = atlas.spatialDataMap.find(kLUTsKey1);
      expect(spatialData1 != atlas.spatialDataMap.end()).to.beTruthy();
      const auto &spatialData2 = atlas.spatialDataMap.find(kLUTsKey2);
      expect(spatialData2 != atlas.spatialDataMap.end()).to.beTruthy();
    });

    it(@"should have correct area x origins", ^{
      it(@"should produce areas with correct origins", ^{
        std::vector<CGRect> areasSortedByXOrigin;

        for (const auto &keyValue : atlas.spatialDataMap) {
          areasSortedByXOrigin.push_back(keyValue.second.area);
        }

        std::sort(areasSortedByXOrigin.begin(), areasSortedByXOrigin.end(),
            [] (auto &lhs, auto &rhs) {
              return lhs.origin.x < rhs.origin.x;
            });

        CGFloat widthsSum = 0;
        for (NSUInteger i = 0; i < areasSortedByXOrigin.size(); ++i) {
          expect(areasSortedByXOrigin[i].origin.x).to.equal(widthsSum);
          widthsSum += areasSortedByXOrigin[i].size.width;
        }
      });
    });

    it(@"should have correct area y origins", ^{
      LT3DLUTSpatialData spatialData1 = atlas.spatialDataMap[kLUTsKey1];
      expect(spatialData1.area.origin.y).to.equal(0);
      LT3DLUTSpatialData spatialData2 = atlas.spatialDataMap[kLUTsKey2];
      expect(spatialData2.area.origin.y).to.equal(0);
    });

    it(@"should have correct area sizes", ^{
      LT3DLUTSpatialData spatialData1 = atlas.spatialDataMap[kLUTsKey1];
      expect(spatialData1.area.size).to.equal(CGSizeMake(lut1PackedMat.cols, lut1PackedMat.rows));
      LT3DLUTSpatialData spatialData2 = atlas.spatialDataMap[kLUTsKey2];
      expect(spatialData2.area.size).to.equal(CGSizeMake(lut2PackedMat.cols, lut2PackedMat.rows));
    });

    it(@"should have correct lattice sizes", ^{
      LT3DLUTSpatialData spatialData1 = atlas.spatialDataMap[kLUTsKey1];
      expect(spatialData1.latticeSize == luts[kLUTsKey1].latticeSize).to.beTruthy();
      LT3DLUTSpatialData spatialData2 = atlas.spatialDataMap[kLUTsKey2];
      expect(spatialData2.latticeSize == luts[kLUTsKey2].latticeSize).to.beTruthy();
    });
  });

  context(@"atlas texturew", ^{
    it(@"should have a correct atlas texture", ^{
      cv::Mat4b atlasMat = [atlas.texture image];

      cv::Mat4b expected(atlas.texture.size.height, atlas.texture.size.width,
                         cv::Vec4b(0, 0, 0, 0));
      CGRect lut1PackingArea = atlas.spatialDataMap[kLUTsKey1].area;
      lut1PackedMat.copyTo(expected(LTCVRectWithCGRect(lut1PackingArea)));
      CGRect lut2PackingArea = atlas.spatialDataMap[kLUTsKey2].area;
      lut2PackedMat.copyTo(expected(LTCVRectWithCGRect(lut2PackingArea)));

      expect($(atlasMat)).to.equalMat($(expected));
    });
  });
});

SpecEnd
