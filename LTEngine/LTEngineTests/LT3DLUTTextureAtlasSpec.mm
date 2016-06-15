// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LT3DLUTTextureAtlas.h"

#import "LTTexture+Factory.h"
#import "LTTextureAtlas.h"

SpecBegin(LT3DLUTTextureAtlas)

context(@"LT3DLUTSpatialData", ^{
  it(@"should initialize correctly", ^{
    LT3DLUTLatticeSize latticeSize{1, 2, 3};
    CGRect area = CGRectMake(4, 5, 6, 7);

    LT3DLUTSpatialData spatialData{latticeSize, area};

    expect(spatialData.latticeSize == latticeSize).to.beTruthy();
    expect(spatialData.area).to.equal(area);
  });

  it(@"should check equality of equal values correctly", ^{
    LT3DLUTSpatialData spatialData1{{1, 2, 3}, CGRectMake(4, 5, 6, 7)};
    LT3DLUTSpatialData spatialData2{{1, 2, 3}, CGRectMake(4, 5, 6, 7)};

    expect(spatialData1 == spatialData2).to.beTruthy();
    expect(spatialData1 != spatialData2).to.beFalsy();
  });

  it(@"should check equality of different values correctly", ^{
    LT3DLUTSpatialData spatialData1{{1, 1, 3}, CGRectMake(4, 5, 6, 7)};
    LT3DLUTSpatialData spatialData2{{1, 2, 3}, CGRectMake(4, 5, 6, 7)};
    expect(spatialData1 == spatialData2).to.beFalsy();
    expect(spatialData1 != spatialData2).to.beTruthy();

    LT3DLUTSpatialData spatialData3{{1, 2, 3}, CGRectMake(4, 5, 6, 7)};
    LT3DLUTSpatialData spatialData4{{1, 2, 3}, CGRectMake(5, 5, 6, 7)};
    expect(spatialData3 == spatialData4).to.beFalsy();
    expect(spatialData3 != spatialData4).to.beTruthy();
  });
});

context(@"initialization", ^{
  __block LTTextureAtlas *atlas;
  __block CGRect area1;
  __block CGRect area2;
  __block CGRect area3;

  beforeEach(^{
    area1 = CGRectMake(0, 0, 2, 4);
    area2 = CGRectMake(0, 0, 3, 9);
    area3 = CGRectMake(3, 0, 4, 6);

    lt::unordered_map<NSString *, CGRect> areas{{@"1", area1}, {@"2", area2}, {@"3", area3}};

    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(7, 9)];
    atlas = [[LTTextureAtlas alloc] initWithAtlasTexture:texture imageAreas:areas];
  });

  afterEach(^{
    atlas = nil;
  });

  it(@"should initialize with valid arguments correctly", ^{
    LT3DLUTLatticeSizeMap latticeSizes{{@"1", {2, 2, 2}}, {@"2", {3, 3, 3}}, {@"3", {4, 3, 2}}};

    LT3DLUTTextureAtlas *lutsAtlas =
        [[LT3DLUTTextureAtlas alloc] initWithTextureAtlas:atlas latticeSizes:latticeSizes];
    expect($([lutsAtlas.texture image])).to.equalMat($([atlas.texture image]));
    expect(lutsAtlas.spatialDataMap.size()).to.equal(3);

    LT3DLUTSpatialDataMap spatialDataMap = lutsAtlas.spatialDataMap;

    LT3DLUTSpatialData spatialData1 = spatialDataMap[@"1"];
    LT3DLUTSpatialData expectedSpatialData1{{2, 2, 2}, area1};
    expect(spatialData1 == expectedSpatialData1).to.beTruthy();
    LT3DLUTSpatialData spatialData2 = spatialDataMap[@"2"];
    LT3DLUTSpatialData expectedSpatialData2{{3, 3, 3}, area2};
    expect(spatialData2 == expectedSpatialData2).to.beTruthy();
    LT3DLUTSpatialData spatialData3 = spatialDataMap[@"3"];
    LT3DLUTSpatialData expectedSpatialData3{{4, 3, 2}, area3};
    expect(spatialData3 == expectedSpatialData3).to.beTruthy();
  });

  it(@"should raise when lattice size map and atlas areas map are of different sizes", ^{
    LT3DLUTLatticeSizeMap latticeSizes {{@"1", {2, 2, 2}}, {@"2", {3, 3, 3}}};

    expect(^{
      LT3DLUTTextureAtlas __unused *lutsAtlas =
          [[LT3DLUTTextureAtlas alloc] initWithTextureAtlas:atlas latticeSizes:latticeSizes];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when lattice size map and atlas areas map have different keys sets", ^{
    LT3DLUTLatticeSizeMap latticeSizes {{@"1", {2, 2, 2}}, {@"2", {3, 3, 3}}, {@"4", {4, 3, 2}}};

    expect(^{
      LT3DLUTTextureAtlas __unused *lutsAtlas =
          [[LT3DLUTTextureAtlas alloc] initWithTextureAtlas:atlas latticeSizes:latticeSizes];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when lattice size map values don't fit the atlas area size values", ^{
    LT3DLUTLatticeSizeMap latticeSizes {{@"1", {2, 2, 2}}, {@"2", {3, 3, 3}}, {@"3", {4, 3, 3}}};

    expect(^{
      LT3DLUTTextureAtlas __unused *lutsAtlas =
          [[LT3DLUTTextureAtlas alloc] initWithTextureAtlas:atlas latticeSizes:latticeSizes];
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
