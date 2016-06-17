// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTTextureAtlasFromMatsProvider.h"

#import "LTHorizontalPackingRectsProvider.h"
#import "LTTexture.h"
#import "LTTextureAtlas.h"

SpecBegin(LTTextureAtlasFromMatsProvider)

context(@"initialization", ^{
  __block LTHorizontalPackingRectsProvider *packingRectsProvider;

  beforeEach(^{
    packingRectsProvider = [[LTHorizontalPackingRectsProvider alloc] init];
  });

  afterEach(^{
    packingRectsProvider = nil;
  });

  it(@"should raise when matrices map is empty", ^{
    lt::unordered_map<NSString *, cv::Mat> emptyMap {};
    expect(^{
      LTTextureAtlasFromMatsProvider __unused *provider =
          [[LTTextureAtlasFromMatsProvider alloc] initWithMatrices:emptyMap
                                              packingRectsProvider:packingRectsProvider];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when matrices map continas a matrix without positive width", ^{
    lt::unordered_map<NSString *, cv::Mat> invalidMatrices {
        {@"valid", cv::Mat1f(1, 1)},
        {@"invalid", cv::Mat1f(1, 0)}
    };
    expect(^{
      LTTextureAtlasFromMatsProvider __unused *provider =
          [[LTTextureAtlasFromMatsProvider alloc] initWithMatrices:invalidMatrices
                                              packingRectsProvider:packingRectsProvider];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when matrices map continas a matrix without positive height", ^{
    lt::unordered_map<NSString *, cv::Mat> invalidMatrices {
        {@"valid", cv::Mat1f(1, 1)},
        {@"invalid", cv::Mat1f(0, 1)}
    };
    expect(^{
      LTTextureAtlasFromMatsProvider __unused *provider =
          [[LTTextureAtlasFromMatsProvider alloc] initWithMatrices:invalidMatrices
                                              packingRectsProvider:packingRectsProvider];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when matrices map contains matrices with diffferent types", ^{
    lt::unordered_map<NSString *, cv::Mat> invalidMatrices {
        {@"1f", cv::Mat1f(1, 1)},
        {@"4f", cv::Mat4f(1, 1)}
    };
    expect(^{
      LTTextureAtlasFromMatsProvider __unused *provider =
          [[LTTextureAtlasFromMatsProvider alloc] initWithMatrices:invalidMatrices
                                              packingRectsProvider:packingRectsProvider];
    }).to.raise(NSInvalidArgumentException);

    it(@"shoud raise when matrices type is not convertable to LTGLPixelFormat", ^{
      lt::unordered_map<NSString *, cv::Mat> invalidMatrices {
          {@"1", cv::Mat3f(1, 1)},
          {@"2", cv::Mat3f(2, 2)}
      };
      expect(^{
      LTTextureAtlasFromMatsProvider __unused *provider =
          [[LTTextureAtlasFromMatsProvider alloc] initWithMatrices:invalidMatrices
                                              packingRectsProvider:packingRectsProvider];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"packing", ^{
  __block cv::Mat4b redImage;
  __block cv::Mat4b greenImage;
  __block cv::Mat4b blueImage;
  __block LTTextureAtlasFromMatsProvider *provider;
  __block LTTextureAtlas *atlas;
  __block lt::unordered_map<NSString *, CGRect> packingRects;

  beforeEach(^{
    redImage = cv::Mat4b(1, 1, cv::Vec4b(255, 0, 0, 255));
    greenImage = cv::Mat4b(2, 2, cv::Vec4b(0, 255, 0, 255));
    blueImage = cv::Mat4b(3, 4, cv::Vec4b(0, 0, 255, 255));
    lt::unordered_map<NSString *, cv::Mat> matrices {
      {@"red", redImage},
      {@"green", greenImage},
      {@"blue", blueImage}
    };

    lt::unordered_map<NSString *, CGSize> packingSizes {
      {@"red", CGSizeMakeUniform(1)},
      {@"green", CGSizeMakeUniform(2)},
      {@"blue", CGSizeMake(4, 3)}
    };

    LTHorizontalPackingRectsProvider *packingRectsProvider =
        [[LTHorizontalPackingRectsProvider alloc] init];
    packingRects = [packingRectsProvider packingOfSizes:packingSizes];
    provider = [[LTTextureAtlasFromMatsProvider alloc] initWithMatrices:matrices
                                                   packingRectsProvider:packingRectsProvider];
    atlas = [provider atlas];
  });

  afterEach(^{
    provider = nil;
    atlas = nil;
  });

  it(@"should produce an atlas with correct texture pixel format", ^{
    expect(atlas.texture.pixelFormat).to.equal($(LTGLPixelFormatRGBA8Unorm));
  });

  it(@"should produce an atlas with correct texture size", ^{
    expect(atlas.texture.size).to.equal(CGSizeMake(7, 3));
  });

  it(@"should produce an atlas with correct content", ^{
    cv::Mat4b expected(atlas.texture.size.height, atlas.texture.size.width, cv::Vec4b(0, 0, 0, 0));
    redImage.copyTo(expected(LTCVRectWithCGRect(atlas.areas[@"red"])));
    greenImage.copyTo(expected(LTCVRectWithCGRect(atlas.areas[@"green"])));
    blueImage.copyTo(expected(LTCVRectWithCGRect(atlas.areas[@"blue"])));
    expect($([atlas.texture image])).to.equalMat($(expected));
  });
});

SpecEnd
