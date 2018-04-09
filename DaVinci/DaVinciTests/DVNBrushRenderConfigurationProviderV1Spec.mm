// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTParameterizedObjectType.h>
#import <LTEngine/LTSplineControlPoint.h>
#import <LTEngine/LTTexture+Factory.h>

#import "DVNBrushModel+Deserialization.h"
#import "DVNBrushModelV1.h"
#import "DVNBrushRenderConfigurationProvider.h"
#import "DVNBrushRenderInfoProvider.h"
#import "DVNBrushRenderModel.h"
#import "DVNBrushRenderTargetInformation.h"
#import "DVNPainter.h"

static const CGSize kSize = CGSizeMake(37, 7);

NSDictionary *DVNBrushModelJSONDictionaryFromFileWithName(NSBundle *bundle, NSString *name) {
  NSString *filePath = [bundle pathForResource:name ofType:@"json"];
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:nil];
}

DVNBrushRenderModel *DVNTestBrushRenderModel(NSDictionary *dictionary, NSDictionary *updatedValues,
                                             CGSize renderTargetSize) {
  NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
  [mutableDictionary addEntriesFromDictionary:updatedValues];
  DVNBrushModel *brushModel = [DVNBrushModel modelFromJSONDictionary:mutableDictionary error:nil];
  lt::Quad quad(CGRectFromSize(renderTargetSize));
  DVNBrushRenderTargetInformation *info =
      [DVNBrushRenderTargetInformation instanceWithRenderTargetLocation:quad
                                           renderTargetHasSingleChannel:NO
                                         renderTargetIsNonPremultiplied:NO];
  return [DVNBrushRenderModel instanceWithBrushModel:brushModel renderTargetInfo:info
                                    conversionFactor:1];
}

@interface DVNTestBrushStrokePainter : NSObject <DVNBrushRenderInfoProvider, DVNPainterDelegate>
@property (readonly, nonatomic) LTTexture *canvas;
@property (readonly, nonatomic) DVNPainter *painter;
@property (readonly, nonatomic) DVNBrushRenderConfigurationProvider *provider;
@property (strong, nonatomic) NSDictionary<NSString *, LTTexture *> *textureMapping;
@property (strong, nonatomic) DVNBrushRenderModel *model;
@property (strong, nonatomic) NSArray<LTSplineControlPoint *> *startControlPoints;
@property (strong, nonatomic) NSArray<LTSplineControlPoint *> *endControlPoints;
@end

@implementation DVNTestBrushStrokePainter

- (instancetype)initWithCanvasSize:(CGSize)size {
  if (self = [super init]) {
    _canvas = [LTTexture byteRGBATextureWithSize:size];
    [self.canvas clearColor:LTVector4::zeros()];
    _painter = [[DVNPainter alloc] initWithCanvas:self.canvas brushRenderInfoProvider:self
                                         delegate:self];
    _provider = [[DVNBrushRenderConfigurationProvider alloc] init];
  }
  return self;
}

- (LTParameterizedObjectType *)brushSplineType {
  return $(LTParameterizedObjectTypeLinear);
}

- (DVNPipelineConfiguration *)brushRenderConfiguration {
  return [self.provider configurationForModel:self.model
                           withTextureMapping:self.textureMapping];
}

- (void)paint {
  [self.painter processControlPoints:self.startControlPoints end:NO];
  [self.painter processControlPoints:self.endControlPoints end:YES];
}

@end

SpecBegin(DVNBrushRenderConfigurationProviderV1)

context(@"version 1", ^{
  static NSDictionary * const kDictionary =
      DVNBrushModelJSONDictionaryFromFileWithName([NSBundle bundleForClass:[self class]],
                                                  @"DVNDefaultTestBrushModelV1");

  static NSArray<LTSplineControlPoint *> * const kStartControlPoints = @[
    [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(3.5,
                                                                           kSize.height / 2)],
    [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointFromSize(kSize / 2)]
  ];

  static NSArray<LTSplineControlPoint *> * const kEndControlPoints = @[
    [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(kSize.width - 3.5,
                                                                           kSize.height / 2)]
  ];

  __block LTTexture *sourceTexture;
  __block LTTexture *maskTexture;
  __block NSDictionary<NSString *, LTTexture *> *textureMapping;
  __block DVNTestBrushStrokePainter *painter;

  beforeEach(^{
    sourceTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    [sourceTexture clearColor:LTVector4::ones()];
    maskTexture = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    [maskTexture clearColor:LTVector4::ones()];
    textureMapping = @{
      @"sourceImageURL": sourceTexture,
      @"maskImageURL": maskTexture
    };
    painter = [[DVNTestBrushStrokePainter alloc] initWithCanvasSize:kSize];
    painter.textureMapping = textureMapping;
    painter.startControlPoints = kStartControlPoints;
    painter.endControlPoints = kEndControlPoints;
  });

  afterEach(^{
    painter = nil;
    textureMapping = nil;
    sourceTexture = nil;
    maskTexture = nil;
  });

  it(@"should render", ^{
    painter.model = DVNTestBrushRenderModel(kDictionary, @{}, kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_Default.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to scale", ^{
    painter.model = DVNTestBrushRenderModel(kDictionary,
                                            @{@instanceKeypath(DVNBrushModelV1, scale): @3},
                                            kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_Scale.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to spacing", ^{
    painter.model = DVNTestBrushRenderModel(kDictionary,
                                            @{@instanceKeypath(DVNBrushModelV1, spacing): @2},
                                            kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_Spacing.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to sequence distance", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, sequenceDistance): @2},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_SequenceDistance.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to distance jitter factor range", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1,
                                                   distanceJitterFactorRange): @"[0, 1]"},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_DistanceJitter.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to count range", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1,
                                                   distanceJitterFactorRange): @"[0, 1]",
                                  @instanceKeypath(DVNBrushModelV1, countRange): @"[1, 2]"},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_Count.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to initial seed", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1,
                                                   distanceJitterFactorRange): @"[0, 1]",
                                  @instanceKeypath(DVNBrushModelV1, initialSeed): @1},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_InitialSeed.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to angle range", ^{
    cv::Mat1b mat(3, 3, (unsigned char)0);
    mat.col(1) = 255;
    LTTexture *maskTexture = [LTTexture textureWithImage:mat];
    auto textureMapping = [painter.textureMapping mutableCopy];
    [textureMapping addEntriesFromDictionary:@{
      @"maskImageURL": maskTexture
    }];
    painter.textureMapping = textureMapping;

    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, scale): @3,
                                  @instanceKeypath(DVNBrushModelV1, angleRange): @"[0, 3.1415]"},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_AngleJitter.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to scale jitter range", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1,
                                                   scaleJitterRange): @"(0, 3]"},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_ScaleJitter.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to tapering lengths", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, scale): @5,
                                  @instanceKeypath(DVNBrushModelV1, taperingLengths): @"(15, 10)"},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_TaperingLengths.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to minimum tapering scale factor", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, scale): @5,
                                  @instanceKeypath(DVNBrushModelV1, taperingLengths): @"(15, 10)",
                                  @instanceKeypath(DVNBrushModelV1,
                                                   minimumTaperingScaleFactor): @0.5},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_TaperingScaleFactor.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to tapering factors", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, scale): @5,
                                  @instanceKeypath(DVNBrushModelV1, taperingLengths): @"(15, 10)",
                                  @instanceKeypath(DVNBrushModelV1, taperingFactors):
                                      @"(0, 0.5)"},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_TaperingExponent.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to flow", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, flow): @0.5},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_Flow.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to flow exponent", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, flow): @0.5,
                                  @instanceKeypath(DVNBrushModelV1, flowExponent): @0.2},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_FlowExponent.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to color", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, color): @"(1, 0, 0)"},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_Color.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to brightness jitter", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, brightnessJitter): @0.5},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_BrightnessJitter.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to hue jitter", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, color): @"(1, 0, 0)",
                                  @instanceKeypath(DVNBrushModelV1, hueJitter): @0.5},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_HueJitter.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  it(@"should render according to saturation jitter", ^{
    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, color): @"(1, 0, 0)",
                                  @instanceKeypath(DVNBrushModelV1, saturationJitter): @0.5},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_SaturationJitter.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  context(@"source sampling mode", ^{
    __block NSDictionary *dictionary;

    beforeEach(^{
      cv::Mat4b source(kSize.height, kSize.width);
      for (int i = 0; i < source.cols; ++i) {
        unsigned char value = (CGFloat)i / source.cols * 255;
        source.col(i) = cv::Vec4b(value, value, value, 255);
      }

      sourceTexture = [LTTexture textureWithImage:source];

      auto textureMapping = [painter.textureMapping mutableCopy];
      [textureMapping addEntriesFromDictionary:@{
        @"sourceImageURL": sourceTexture,
      }];
      painter.textureMapping = textureMapping;

      dictionary = [kDictionary mtl_dictionaryByAddingEntriesFromDictionary:@{
        @instanceKeypath(DVNBrushModelV1, scale): @3,
        @instanceKeypath(DVNBrushModelV1, numberOfSamplesPerSequence): @1,
        @instanceKeypath(DVNBrushModelV1, sequenceDistance): @2
      }];
    });

    it(@"should render according to fixed source sampling mode", ^{
      expect(DVNSourceSamplingMode.fields.count).to.equal(3);

      painter.model =
          DVNTestBrushRenderModel(kDictionary,
                                  @{@instanceKeypath(DVNBrushModelV1, sourceSamplingMode):
                                        @"fixed"},
                                  kSize);

      [painter paint];

      cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_SamplingMode_Fixed.png");
      expect($(painter.canvas.image)).to.equalMat($(expected));
    });

    it(@"should render according to center source sampling mode", ^{
      painter.model =
          DVNTestBrushRenderModel(kDictionary,
                                  @{@"scale": @3,
                                    @instanceKeypath(DVNBrushModelV1, sourceSamplingMode):
                                        @"center"},
                                  kSize);

      [painter paint];

      cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_SamplingMode_Center.png");
      expect($(painter.canvas.image)).to.equalMat($(expected));
    });

    it(@"should render according to subimage source sampling mode", ^{
      painter.model =
          DVNTestBrushRenderModel(kDictionary,
                                  @{@instanceKeypath(DVNBrushModelV1, sourceSamplingMode):
                                        @"subimage"},
                                  kSize);

      [painter paint];

      cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_SamplingMode_Subimage.png");
      expect($(painter.canvas.image)).to.equalMat($(expected));
    });
  });

  it(@"should render according to brush tip image grid size", ^{
    cv::Mat4b source = (cv::Mat4b(1, 2) << cv::Vec4b(255, 255, 255, 255),
                                           cv::Vec4b(0, 0, 0, 255));
    sourceTexture = [LTTexture textureWithImage:source];
    sourceTexture.magFilterInterpolation = LTTextureInterpolationNearest;

    auto textureMapping = [painter.textureMapping mutableCopy];
    [textureMapping addEntriesFromDictionary:@{
      @"sourceImageURL": sourceTexture,
    }];
    painter.textureMapping = textureMapping;

    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, scale): @5,
                                  @instanceKeypath(DVNBrushModelV1, numberOfSamplesPerSequence): @1,
                                  @instanceKeypath(DVNBrushModelV1, sequenceDistance): @2,
                                  @instanceKeypath(DVNBrushModelV1, brushTipImageGridSize):
                                      @"(2, 1)"},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_GridSize.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  context(@"indication whether source texture is premultiplied", ^{
    beforeEach(^{
      [sourceTexture clearColor:LTVector4(1, 1, 1, 0.5)];
    });

    it(@"should render according to indication that source texture is premultiplied", ^{
      painter.model =
          DVNTestBrushRenderModel(kDictionary,
                                  @{@instanceKeypath(DVNBrushModelV1, scale): @7,
                                    @instanceKeypath(DVNBrushModelV1,
                                                     sourceImageIsNonPremultiplied): @NO},
                                  kSize);

      [painter paint];
      expect(LTVector4(painter.canvas.image.at<cv::Vec4b>(0, 0)))
          .to.equal(LTVector4(cv::Vec4b(255, 255, 255, 128)));
    });

    it(@"should render according to indication that source texture is non-premultiplied", ^{
      [sourceTexture clearColor:LTVector4(1, 1, 1, 0.5)];

      painter.model =
          DVNTestBrushRenderModel(kDictionary,
                                  @{@instanceKeypath(DVNBrushModelV1, scale): @7,
                                    @instanceKeypath(DVNBrushModelV1,
                                                     sourceImageIsNonPremultiplied): @YES},
                                  kSize);

      [painter paint];

      expect(LTVector4(painter.canvas.image.at<cv::Vec4b>(0, 0)))
          .to.equal(LTVector4(cv::Vec4b(128, 128, 128, 128)));
    });
  });

  it(@"should render with correct mask image", ^{
    cv::Mat1b mat(3, 3, (unsigned char)0);
    mat.col(1) = 255;
    LTTexture *maskTexture = [LTTexture textureWithImage:mat];
    auto textureMapping = [painter.textureMapping mutableCopy];
    [textureMapping addEntriesFromDictionary:@{
      @"maskImageURL": maskTexture
    }];
    painter.textureMapping = textureMapping;

    painter.model =
        DVNTestBrushRenderModel(kDictionary,
                                @{@instanceKeypath(DVNBrushModelV1, scale): @3},
                                kSize);

    [painter paint];

    cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_Mask.png");
    expect($(painter.canvas.image)).to.equalMat($(expected));
  });

  context(@"edge avoidance", ^{
    it(@"should render with edge avoidance", ^{
      NSDictionary *edgeAvoidanceDictionary = @{
        @instanceKeypath(DVNBrushModelV1, scale): @5,
        @instanceKeypath(DVNBrushModelV1, edgeAvoidance): @1,
        @instanceKeypath(DVNBrushModelV1, edgeAvoidanceSamplingOffset): @0.1
      };
      painter.model = DVNTestBrushRenderModel(kDictionary, edgeAvoidanceDictionary, kSize);

      cv::Mat4b image = (cv::Mat4b(3, 1) << cv::Vec4b(255, 255, 255, 255), cv::Vec4b(0, 0, 0, 255),
                                            cv::Vec4b(0, 0, 0, 255));
      LTTexture *edgeAvoidanceGuideTexture = [LTTexture textureWithImage:image];

      auto textureMapping = [painter.textureMapping mutableCopy];
      [textureMapping addEntriesFromDictionary:@{
        @"edgeAvoidanceGuideImageURL": edgeAvoidanceGuideTexture
      }];
      painter.textureMapping = textureMapping;

      [painter paint];

      cv::Mat4b expected = LTLoadMat([self class], @"DVNBrushModelV1_EdgeAvoidance.png");
      expect($(painter.canvas.image)).to.equalMat($(expected));
    });
  });
});

SpecEnd
