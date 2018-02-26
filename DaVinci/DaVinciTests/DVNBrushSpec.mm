// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTAttributeData.h>
#import <LTEngine/LTDynamicQuadDrawer.h>
#import <LTEngine/LTFbo.h>
#import <LTEngine/LTTexture+Factory.h>
#import <LTEngine/UIColor+Vector.h>
#import <LTKit/LTRandom.h>

#import "DVNBlendMode.h"
#import "DVNBrushTestQuads.h"
#import "DVNJitteredColorAttributeProviderModel.h"
#import "DVNQuadCenterAttributeProvider.h"
#import "LTShaderStorage+DVNBrushFsh.h"
#import "LTShaderStorage+DVNBrushVsh.h"

static dvn::GeometryValues DVNTestGeometryValuesWithQuads(const std::vector<lt::Quad> &quads) {
  std::vector<NSUInteger> indices;
  for (NSUInteger i = 0; i < quads.size(); ++i) {
    indices.push_back(i);
  }

  return dvn::GeometryValues(quads, indices, OCMProtocolMock(@protocol(LTSampleValues)));
}

static NSArray<LTAttributeData *> *DVNTestAttributeDataForQuads(const std::vector<lt::Quad> &quads,
                                                                LTVector3 color) {
  auto quadCenterModel = [[DVNQuadCenterAttributeProviderModel alloc] init];

  LTRandomState *randomState = [[LTRandom alloc] initWithSeed:0].initialState;
  auto colorModel = [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:color
                                                                     brightnessJitter:0 hueJitter:0
                                                                     saturationJitter:0
                                                                          randomState:randomState];

  id<DVNAttributeProvider> quadCenterAttributeProvider = [quadCenterModel provider];
  id<DVNAttributeProvider> colorAttributeProvider = [colorModel provider];

  dvn::GeometryValues geometryValues = DVNTestGeometryValuesWithQuads(quads);
  return @[[quadCenterAttributeProvider attributeDataFromGeometryValues:geometryValues],
           [colorAttributeProvider attributeDataFromGeometryValues:geometryValues]];
}

static LTTexture *DVNTestColoredTexture(BOOL withTransparency) {
  LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 2)];
  [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    mapped->at<cv::Vec4b>(0, 0) =
        (cv::Vec4b)(withTransparency ? LTVector4::zeros() : LTVector4(0, 0, 0, 1));
    mapped->at<cv::Vec4b>(0, 1) = (cv::Vec4b)LTVector4(0, 0, 1, 1);
    mapped->at<cv::Vec4b>(0, 2) = (cv::Vec4b)LTVector4(0, 1, 0, 1);
    mapped->at<cv::Vec4b>(0, 3) = (cv::Vec4b)LTVector4(0, 1, 1, 1);
    mapped->at<cv::Vec4b>(1, 0) = (cv::Vec4b)LTVector4(1, 0, 0, 1);
    mapped->at<cv::Vec4b>(1, 1) = (cv::Vec4b)LTVector4(1, 0, 1, 1);
    mapped->at<cv::Vec4b>(1, 2) = (cv::Vec4b)LTVector4(1, 1, 0, 1);
    mapped->at<cv::Vec4b>(1, 3) = (cv::Vec4b)LTVector4::ones();
  }];
  texture.minFilterInterpolation = LTTextureInterpolationNearest;
  texture.magFilterInterpolation = LTTextureInterpolationNearest;
  return texture;
}

SpecBegin(DVNBrush)

static const CGSize targetTextureSize = CGSizeMake(16, 32);

__block LTDynamicQuadDrawer *drawer;
__block LTTexture *brushTipTexture;
__block LTTexture *targetTexture;
__block LTFbo *fbo;
__block NSDictionary<NSString *, NSValue *> *uniforms;

beforeEach(^{
  std::vector<lt::Quad> quads = {lt::Quad::canonicalSquare()};
  NSArray<LTAttributeData *> *attributeData = DVNTestAttributeDataForQuads(quads,
                                                                           LTVector3::zeros());
  NSArray<LTGPUStruct *> *gpuStructs = @[attributeData[0].gpuStruct, attributeData[1].gpuStruct];
  drawer = [[LTDynamicQuadDrawer alloc]
            initWithVertexSource:[DVNBrushVsh source] fragmentSource:[DVNBrushFsh source]
            gpuStructs:[NSOrderedSet orderedSetWithArray:gpuStructs]];
  brushTipTexture = DVNTestColoredTexture(YES);
  targetTexture = [LTTexture byteRGBATextureWithSize:targetTextureSize];
  [targetTexture clearColor:LTVector4::zeros()];
  fbo = [[LTFbo alloc] initWithTexture:targetTexture];
  uniforms = @{[DVNBrushVsh modelview]: $(GLKMatrix4Identity),
               [DVNBrushFsh blendMode]: @($(DVNBlendModeNormal).value),
               [DVNBrushFsh opacity]: @1,
               [DVNBrushFsh sourceType]: @1,
               [DVNBrushFsh overlayTextureCoordTransform]: $(GLKMatrix4Identity)};
});

afterEach(^{
  drawer = nil;
  brushTipTexture = nil;
  targetTexture = nil;
  fbo = nil;
});

context(@"rendering", ^{
  __block std::vector<lt::Quad> quads;
  __block NSArray<LTAttributeData *> *attributeData;

  beforeEach(^{
    quads = {lt::Quad(CGRectMake(0, 0.25, 1, 0.5))};
    attributeData = DVNTestAttributeDataForQuads(quads, LTVector3::ones());
  });

  it(@"should render", ^{
    [fbo bindAndDraw:^{
      [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
          attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
               uniforms:uniforms];
    }];

    cv::Mat expectedMat = LTLoadMat([self class], @"DVNBrushTip.png");
    expect($(targetTexture.image)).to.equalMat($(expectedMat));
  });

  context(@"source type equaling kSourceTypeColor", ^{
    __block NSMutableDictionary<NSString *, NSValue *> *mutableUniforms;

    beforeEach(^{
      attributeData = DVNTestAttributeDataForQuads(quads, LTVector3(1, 0, 0));
      NSArray<LTGPUStruct *> *gpuStructs =
          @[attributeData[0].gpuStruct, attributeData[1].gpuStruct];
      drawer = [[LTDynamicQuadDrawer alloc]
                initWithVertexSource:[DVNBrushVsh source] fragmentSource:[DVNBrushFsh source]
                gpuStructs:[NSOrderedSet orderedSetWithArray:gpuStructs]];

      mutableUniforms = [uniforms mutableCopy];
      mutableUniforms[[DVNBrushFsh sourceType]] = @0;
    });

    afterEach(^{
      mutableUniforms = nil;
    });

    it(@"should render with color", ^{
      [brushTipTexture clearColor:LTVector4::zeros()];

      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(targetTexture.size.height, targetTexture.size.width,
                            cv::Vec4b(0, 0, 0, 0));
      expectedMat(cv::Rect(0, targetTexture.size.height / 4, targetTexture.size.width,
                           targetTexture.size.height / 2)) = cv::Vec4b(255, 0, 0, 255);
      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with color and mask", ^{
      mutableUniforms[[DVNBrushFsh useSourceTextureAsMask]] = @YES;
      cv::Mat image = LTLoadMat([self class], @"DVNBrushTipsRound64Hardness75.png");
      LTTexture *rgbaBrushTipTexture = [LTTexture textureWithImage:image];
      brushTipTexture = [LTTexture byteRedTextureWithSize:rgbaBrushTipTexture.size];
      [rgbaBrushTipTexture cloneTo:brushTipTexture];

      [fbo clearColor:LTVector4::ones()];

      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat expectedMat = LTLoadMat([self class], @"DVNBrushColorWithMask.png");
      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });
  });

  it(@"should render with opacity", ^{
    auto mutableUniforms = [uniforms mutableCopy];
    mutableUniforms[[DVNBrushFsh opacity]] = @0.5;

    [brushTipTexture clearColor:LTVector4::ones()];

    [fbo bindAndDraw:^{
      [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
          attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
               uniforms:mutableUniforms];
    }];

    cv::Mat4b expectedMat(targetTexture.size.height, targetTexture.size.width,
                          cv::Vec4b(0, 0, 0, 0));
    expectedMat(cv::Rect(0, targetTexture.size.height / 4, targetTexture.size.width,
                         targetTexture.size.height / 2)) = cv::Vec4b(255, 255, 255, 128);
    expect($(targetTexture.image)).to.equalMat($(expectedMat));
  });

  it(@"should render with modelview", ^{
    auto mutableUniforms = [uniforms mutableCopy];
    mutableUniforms[[DVNBrushVsh modelview]] = $(GLKMatrix4MakeScale(2, 1, 1));

    [fbo bindAndDraw:^{
      [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
          attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
               uniforms:mutableUniforms];
    }];

    cv::Mat expectedMat = LTLoadMat([self class], @"DVNBrushTipModelview.png");
    expect($(targetTexture.image)).to.equalMat($(expectedMat));
  });

  it(@"should render with non-trivial modelview matrix", ^{
    std::vector<lt::Quad> quads;
    std::vector<lt::Quad> texcoordQuads;

    for (const LTQuadCorners &corners : kCornersOfOverlappingQuads) {
      quads.push_back(lt::Quad(corners));
      texcoordQuads.push_back(lt::Quad::canonicalSquare());
    }

    NSMutableDictionary<NSString *, NSValue *> *mutableUniforms = [uniforms mutableCopy];
    mutableUniforms[[DVNBrushVsh modelview]] = $(kQuadTransformForTesting);
    uniforms = [mutableUniforms copy];

    attributeData = DVNTestAttributeDataForQuads(quads, LTVector3::ones());

    [fbo bindAndDraw:^{
      [drawer drawQuads:quads textureMapQuads:texcoordQuads
          attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
               uniforms:uniforms];
    }];

    cv::Mat expectedMat(LTLoadMat([self class], @"DVNBrushTipNonTrivialModelview.png"));
    expect($(targetTexture.image)).to.equalMat($(expectedMat));
  });

  context(@"edge avoidance", ^{
    __block LTTexture *edgeAvoidanceGuideTexture;
    __block NSDictionary<NSString *, LTTexture *> *auxiliaryTextures;

    beforeEach(^{
      edgeAvoidanceGuideTexture = DVNTestColoredTexture(YES);
      [edgeAvoidanceGuideTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->at<cv::Vec4b>(0, 2) = (cv::Vec4b)LTVector4(0, 0, 0.9, 1);
      }];

      targetTexture = [LTTexture byteRedTextureWithSize:targetTextureSize];
      [targetTexture clearColor:LTVector4::zeros()];
      fbo = [[LTFbo alloc] initWithTexture:targetTexture];
      cv::Mat image = LTLoadMat([self class], @"DVNBrushTipsRound64Hardness75.png");
      LTTexture *rgbaBrushTipTexture = [LTTexture textureWithImage:image];
      brushTipTexture = [LTTexture byteRedTextureWithSize:rgbaBrushTipTexture.size];
      [rgbaBrushTipTexture cloneTo:brushTipTexture];

      quads = {lt::Quad(CGRectCenteredAt(CGPointMake(0.375, 0.375), CGSizeMake(1, 0.5)))};
      attributeData = DVNTestAttributeDataForQuads(quads, LTVector3::ones());

      auxiliaryTextures = @{[DVNBrushFsh edgeAvoidanceGuideTexture]: edgeAvoidanceGuideTexture};

      auto mutableUniforms = [uniforms mutableCopy];
      mutableUniforms[[DVNBrushFsh edgeAvoidance]] = @0;
      mutableUniforms[[DVNBrushFsh useSourceTextureAsMask]] = @YES;
      mutableUniforms[[DVNBrushFsh renderTargetHasSingleChannel]] = @YES;
      mutableUniforms[[DVNBrushVsh edgeAvoidanceSamplingOffset]] = $(LTVector2::zeros());
      uniforms = [mutableUniforms copy];
    });

    afterEach(^{
      edgeAvoidanceGuideTexture = nil;
      auxiliaryTextures = nil;
    });

    it(@"should not be edge avoiding", ^{
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:auxiliaryTextures
                 uniforms:uniforms];
      }];

      cv::Mat expectedMat = LTLoadMat([self class], @"DVNBrushEdgeAvoidance0.png");
      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    context(@"edge avoidance enabled", ^{
      beforeEach(^{
        auto mutableUniforms = [uniforms mutableCopy];
        mutableUniforms[[DVNBrushFsh edgeAvoidance]] = @1;
        uniforms = [mutableUniforms copy];
      });

      it(@"should be edge avoiding without offset", ^{
        [fbo bindAndDraw:^{
          [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
           attributeData:attributeData texture:brushTipTexture
           auxiliaryTextures:auxiliaryTextures uniforms:uniforms];
        }];

        cv::Mat expectedMat = LTLoadMat([self class], @"DVNBrushEdgeAvoidance1.png");
        expect($(targetTexture.image)).to.equalMat($(expectedMat));
      });

      it(@"should be partially edge avoiding without offset", ^{
        auto mutableUniforms = [uniforms mutableCopy];
        mutableUniforms[[DVNBrushFsh edgeAvoidance]] = @0.95;
        uniforms = [mutableUniforms copy];

        [fbo bindAndDraw:^{
          [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
              attributeData:attributeData texture:brushTipTexture
          auxiliaryTextures:auxiliaryTextures uniforms:mutableUniforms];
        }];

        cv::Mat expectedMat = LTLoadMat([self class], @"DVNBrushEdgeAvoidance95.png");
        expect($(targetTexture.image)).to.equalMat($(expectedMat));
      });

      it(@"should be edge avoiding without offset on gray background", ^{
        [targetTexture clearColor:LTVector4(0.9, 0.9, 0.9, 1)];

        [fbo bindAndDraw:^{
          [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
              attributeData:attributeData texture:brushTipTexture
          auxiliaryTextures:auxiliaryTextures uniforms:uniforms];
        }];

        cv::Mat expectedMat = LTLoadMat([self class], @"DVNBrushEdgeAvoidance1Gray.png");
        expect($(targetTexture.image)).to.equalMat($(expectedMat));
      });

      it(@"should be edge avoiding with offset", ^{
        auto mutableUniforms = [uniforms mutableCopy];
        mutableUniforms[[DVNBrushVsh edgeAvoidanceSamplingOffset]] = $(LTVector2(0.1875));

        [fbo bindAndDraw:^{
          [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
           attributeData:attributeData texture:brushTipTexture auxiliaryTextures:auxiliaryTextures
           uniforms:mutableUniforms];
        }];

        cv::Mat expectedMat = LTLoadMat([self class], @"DVNBrushEdgeAvoidance1WithOffset.png");
        expect($(targetTexture.image)).to.equalMat($(expectedMat));
      });
    });
  });

  context(@"sampling from overlay texture", ^{
    __block NSMutableDictionary<NSString *, NSValue *> *mutableUniforms;
    __block NSDictionary<NSString *, LTTexture *> *auxiliaryTextures;

    beforeEach(^{
      cv::Mat image = LTLoadMat([self class], @"DVNBrushTipsRound64Hardness75.png");
      brushTipTexture = [LTTexture textureWithImage:image];

      auxiliaryTextures = @{[DVNBrushFsh overlayTexture]: DVNTestColoredTexture(NO)};

      mutableUniforms = [uniforms mutableCopy];
      mutableUniforms[[DVNBrushFsh sourceType]] = @2;
      mutableUniforms[[DVNBrushFsh useSourceTextureAsMask]] = @YES;

      [targetTexture clearColor:LTVector4(0, 0, 0, 1)];
    });

    afterEach(^{
      mutableUniforms = nil;
      auxiliaryTextures = nil;
    });

    it(@"should sample from overlay texture", ^{
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:auxiliaryTextures
                 uniforms:mutableUniforms];
      }];

      cv::Mat expectedMat = LTLoadMat([self class], @"DVNBrushOverlayTexture.png");
      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should sample from overlay texture with overlay texture coord transform", ^{
      mutableUniforms[[DVNBrushFsh overlayTextureCoordTransform]] =
          $(GLKMatrix4MakeTranslation(0.25, 0, 0));

      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:auxiliaryTextures
                 uniforms:mutableUniforms];
      }];

      cv::Mat expectedMat = LTLoadMat([self class], @"DVNBrushOverlayTextureWithTransform.png");
      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });
  });

  context(@"blend modes", ^{
    static const CGFloat kTargetTextureWidth = 2;
    static const CGFloat kTargetTextureHeight = 1;
    static const cv::Vec4b kBackColor(cv::Vec4b(128, 64, 255, 255));
    static const cv::Vec4b kFrontColor(cv::Vec4b(64, 128, 32, 255));

    __block NSMutableDictionary<NSString *, NSValue *> *mutableUniforms;

    beforeEach(^{
      quads = {lt::Quad(CGRectFromSize(CGSizeMake(0.5, 1)))};
      targetTexture =
          [LTTexture byteRGBATextureWithSize:CGSizeMake(kTargetTextureWidth, kTargetTextureHeight)];
      [targetTexture clearColor:LTVector4(kBackColor)];
      [brushTipTexture clearColor:LTVector4(kFrontColor)];
      fbo = [[LTFbo alloc] initWithTexture:targetTexture];
      mutableUniforms = [uniforms mutableCopy];
      mutableUniforms[[DVNBrushFsh opacity]] = @0.5;
    });

    it(@"should render with normal blending mode on default", ^{
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Vec4b resultColor;
      cv::addWeighted(kFrontColor, 0.5, kBackColor, 0.5, 0, resultColor);
      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = resultColor;

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with darken blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeDarken);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(96, 64, 144, 255);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with multiply blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeMultiply);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(80, 48, 144, 255);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with hard-light blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeHardLight);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(96, 64, 160, 255);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with soft-light blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeSoftLight);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(112, 64, 255, 255);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with lighten blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeLighten);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(128, 96, 255, 255);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with screen blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeScreen);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(144, 112, 255, 255);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    context(@"color burn blend mode", ^{
      it(@"should render with color burn blend mode", ^{
        mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeColorBurn);
        [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

        cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
        expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(64, 32, 255, 255);

        expect($(targetTexture.image)).to.equalMat($(expectedMat));
      });

      it(@"should yield correct results in all channels for color burn blend mode", ^{
        cv::Vec4b newBackColor(0, 128, 255, 255);
        cv::Vec4b newFrontColor(0, 192, 255, 255);
        [targetTexture clearColor:LTVector4(newBackColor)];
        [brushTipTexture clearColor:LTVector4(newFrontColor)];
        mutableUniforms[[DVNBrushFsh opacity]] = @1;

        mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeColorBurn);
        [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
        }];

        cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, newBackColor);
        expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(0, 86, 255, 255);

        expect($(targetTexture.image)).to.equalMat($(expectedMat));
      });
    });

    it(@"should render with overlay blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeOverlay);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(96, 64, 255, 255);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with plus lighter blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModePlusLighter);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(160, 128, 255, 255);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with plus darker blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModePlusDarker);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(64, 32, 144, 255);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with subtract blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeSubtract);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat.at<cv::Vec4b>(0, 0) = cv::Vec4b(192, 64, 255, 128);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with opaque source blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeOpaqueSource);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expectedMat(0, 0) = cv::Vec4b(96, 96, 144, 255);

      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should render with opaque destination blend mode", ^{
      mutableUniforms[[DVNBrushFsh blendMode]] = @(DVNBlendModeOpaqueDestination);
      [fbo bindAndDraw:^{
        [drawer drawQuads:quads textureMapQuads:{lt::Quad::canonicalSquare()}
            attributeData:attributeData texture:brushTipTexture auxiliaryTextures:@{}
                 uniforms:mutableUniforms];
      }];

      cv::Mat4b expectedMat(kTargetTextureHeight, kTargetTextureWidth, kBackColor);
      expect($(targetTexture.image)).to.equalMat($(expectedMat));
    });
  });
});

SpecEnd
