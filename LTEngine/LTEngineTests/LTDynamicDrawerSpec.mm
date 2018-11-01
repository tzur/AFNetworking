// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTDynamicDrawer.h"

#import "LTAttributeData.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGPUStruct.h"
#import "LTIndicesData.h"
#import "LTTexture+Factory.h"

LTGPUStructMake(LTDynamicDrawerTestStruct,
                LTVector3, position,
                LTVector2, texCoord);

SpecBegin(LTDynamicDrawer)

static NSString * const kVertexSource = @"\
  attribute highp vec3 position; \
  attribute highp vec2 texCoord; \
  uniform highp mat4 projection; \
  varying highp vec2 vTexCoord; \
  void main() { \
    vTexCoord = texCoord; \
    gl_Position = projection * vec4(position, 1); \
  } \
";

static NSString * const kFragmentSource = @"\
  uniform sampler2D texture; \
  uniform sampler2D anotherTexture; \
  uniform highp float factor; \
  varying highp vec2 vTexCoord; \
  void main() { \
    gl_FragColor = \
        mix(texture2D(texture, vTexCoord), texture2D(anotherTexture, vTexCoord), factor); \
  } \
";

__block LTDynamicDrawer *drawer;
__block LTGPUStruct *gpuStruct;
__block NSOrderedSet<LTGPUStruct *> *gpuStructs;

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
  context.faceCullingEnabled = YES;

  gpuStruct = [[LTGPUStructRegistry sharedInstance] structForName:@"LTDynamicDrawerTestStruct"];
  gpuStructs = [NSOrderedSet orderedSetWithObject:gpuStruct];
  drawer = [[LTDynamicDrawer alloc] initWithVertexSource:kVertexSource
                                          fragmentSource:kFragmentSource gpuStructs:gpuStructs];
});

afterEach(^{
  drawer = nil;
  gpuStruct = nil;
  [LTGLContext setCurrentContext:nil];
});

context(@"initialization", ^{
  __block NSOrderedSet<LTGPUStruct *> *gpuStructs;

  beforeEach(^{
    gpuStructs = [NSOrderedSet orderedSetWithObject:gpuStruct];
  });

  it(@"should correctly initialize", ^{
    expect(drawer).toNot.beNil();
  });

  context(@"invalid calls", ^{
    it(@"should raise when attempting to initialize without gpu structs", ^{
      expect(^{
        drawer = [[LTDynamicDrawer alloc] initWithVertexSource:kVertexSource
                                                fragmentSource:kFragmentSource
                                                    gpuStructs:[NSOrderedSet orderedSet]];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize with gpu structs with overlapping fields", ^{
      LTGPUStruct *gpuStructWithSameAttribute =
          [[LTGPUStruct alloc] initWithName:@"anotherName" size:gpuStruct.size + 1
                                  andFields:[gpuStruct.fields allValues]];
      gpuStructs = [NSOrderedSet orderedSetWithArray:@[gpuStruct, gpuStructWithSameAttribute]];
      expect(^{
        drawer = [[LTDynamicDrawer alloc] initWithVertexSource:kVertexSource
                                                fragmentSource:kFragmentSource
                                                    gpuStructs:gpuStructs];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize with gpu structs with same name", ^{
      LTGPUStruct *gpuStructWithSameName = [[LTGPUStruct alloc] initWithName:gpuStruct.name size:1
                                                                   andFields:@[]];
      gpuStructs = [NSOrderedSet orderedSetWithArray:@[gpuStruct, gpuStructWithSameName]];
      expect(^{
        drawer = [[LTDynamicDrawer alloc] initWithVertexSource:kVertexSource
                                                fragmentSource:kFragmentSource
                                                    gpuStructs:gpuStructs];
      }).to.raise(NSInternalInconsistencyException);
    });
  });
});

context(@"execution", ^{
  static const cv::Vec4b kRed(255, 0, 0, 255);
  static const cv::Vec4b kDarkRed(128, 0, 0, 255);
  static const cv::Vec4b kGreen(0, 255, 0, 255);
  static const cv::Vec4b kDarkGreen(0, 128, 0, 255);
  static const cv::Vec4b kBlue(0, 0, 255, 255);
  static const cv::Vec4b kDarkBlue(0, 0, 128, 255);
  static const cv::Vec4b kYellow(255, 255, 0, 255);
  static const cv::Vec4b kDarkYellow(128, 128, 0, 255);

  static const CGFloat kWidth = 10;
  static const CGFloat kHalfWidth = kWidth / 2;
  static const CGFloat kHeight = 20;
  static const CGFloat kHalfHeight = kHeight / 2;

  static const GLKMatrix4 kProjection = GLKMatrix4MakeOrtho(-1, 1, -1, 1, 1, -1);

  __block LTTexture *mappedTexture;
  __block LTTexture *anotherMappedTexture;
  __block LTTexture *outputTexture;
  __block LTFbo *fbo;
  __block NSDictionary<NSString *, LTTexture *> *mapping;

  beforeEach(^{
    cv::Mat4b mat = (cv::Mat4b(2, 2) << kRed, kGreen, kBlue, kYellow);
    mappedTexture = [LTTexture textureWithImage:mat];
    mappedTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    mappedTexture.minFilterInterpolation = LTTextureInterpolationNearest;

    anotherMappedTexture = [LTTexture textureWithPropertiesOf:mappedTexture];
    [anotherMappedTexture clearColor:LTVector4(0, 0, 0, 1)];

    outputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(kWidth, kHeight)];
    outputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    outputTexture.minFilterInterpolation = LTTextureInterpolationNearest;
    [outputTexture clearColor:LTVector4::zeros()];
    fbo = [[LTFbo alloc] initWithTexture:outputTexture];

    mapping = @{@"texture": mappedTexture};
  });

  afterEach(^{
    mappedTexture = nil;
    anotherMappedTexture = nil;
    outputTexture = nil;
    fbo = nil;
    mapping = nil;
  });

  context(@"drawing triangular geometry", ^{
    static const LTDynamicDrawerTestStruct fullQuad[] = {
      {.position = LTVector3(-1, -1, 0), .texCoord = LTVector2(0, 0)},
      {.position = LTVector3(1, -1, 0), .texCoord = LTVector2(1, 0)},
      {.position = LTVector3(1, 1, 0), .texCoord = LTVector2(1, 1)},
      {.position = LTVector3(-1, -1, 0), .texCoord = LTVector2(0, 0)},
      {.position = LTVector3(1, 1, 0), .texCoord = LTVector2(1, 1)},
      {.position = LTVector3(-1, 1, 0), .texCoord = LTVector2(0, 1)}
    };

    static const LTDynamicDrawerTestStruct overlappingQuads[] = {
      {.position = LTVector3(-1, -1, 0), .texCoord = LTVector2(0, 0)},
      {.position = LTVector3(0, -1, 0), .texCoord = LTVector2(0.5, 0)},
      {.position = LTVector3(0, 0, 0), .texCoord = LTVector2(0.5, 0.5)},
      {.position = LTVector3(-1, -1, 0), .texCoord = LTVector2(0, 0)},
      {.position = LTVector3(0, 0, 0), .texCoord = LTVector2(0.5, 0.5)},
      {.position = LTVector3(-1, 0, 0), .texCoord = LTVector2(0, 0.5)},

      {.position = LTVector3(-0.5, -0.5, 0), .texCoord = LTVector2(0.5, 0)},
      {.position = LTVector3(0.5, -0.5, 0), .texCoord = LTVector2(1, 0)},
      {.position = LTVector3(0.5, 0.5, 0), .texCoord = LTVector2(1, 0.5)},
      {.position = LTVector3(-0.5, -0.5, 0), .texCoord = LTVector2(0.5, 0)},
      {.position = LTVector3(0.5, 0.5, 0), .texCoord = LTVector2(1, 0.5)},
      {.position = LTVector3(-0.5, 0.5, 0), .texCoord = LTVector2(0.5, 0.5)}
    };

    context(@"non-overlapping geometry", ^{
      __block LTAttributeData *attributeData;

      beforeEach(^{
        NSData *binaryData = [NSData dataWithBytes:&fullQuad[0] length:sizeof(fullQuad)];
        attributeData =
            [[LTAttributeData alloc] initWithData:binaryData inFormatOfGPUStruct:gpuStruct];
      });

      afterEach(^{
        attributeData = nil;
      });

      it(@"should correctly draw with texture mapping", ^{
        cv::Mat4b expectedMat(kHeight, kWidth);
        expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kRed;
        expectedMat(cv::Rect(kHalfWidth, 0, kHalfWidth, kHalfHeight)) = kGreen;
        expectedMat(cv::Rect(0, kHalfHeight, kHalfWidth, kHalfHeight)) = kBlue;
        expectedMat(cv::Rect(kHalfWidth, kHalfHeight, kHalfWidth, kHalfHeight)) = kYellow;

        [fbo bindAndDraw:^{
          [drawer drawWithAttributeData:@[attributeData] samplerUniformsToTextures:mapping
                               uniforms:@{@"projection": $(kProjection)}];
        }];

        expect($(outputTexture.image)).to.equalMat($(expectedMat));
      });

      it(@"should correctly draw with texture mapping and uniforms", ^{
        cv::Mat4b expectedMat(kHeight, kWidth);
        expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kDarkRed;
        expectedMat(cv::Rect(kHalfWidth, 0, kHalfWidth, kHalfHeight)) = kDarkGreen;
        expectedMat(cv::Rect(0, kHalfHeight, kHalfWidth, kHalfHeight)) = kDarkBlue;
        expectedMat(cv::Rect(kHalfWidth, kHalfHeight, kHalfWidth, kHalfHeight)) = kDarkYellow;

        mapping = @{@"texture": mappedTexture, @"anotherTexture": anotherMappedTexture};

        [fbo bindAndDraw:^{
          [drawer drawWithAttributeData:@[attributeData] samplerUniformsToTextures:mapping
                               uniforms:@{@"factor": @0.5, @"projection": $(kProjection)}];
        }];

        expect($(outputTexture.image)).to.equalMat($(expectedMat));
      });
    });

    context(@"overlapping geometry", ^{
      __block LTAttributeData *attributeData;

      beforeEach(^{
        NSData *binaryData = [NSData dataWithBytes:&overlappingQuads[0]
                                            length:sizeof(overlappingQuads)];
        attributeData =
            [[LTAttributeData alloc] initWithData:binaryData inFormatOfGPUStruct:gpuStruct];
      });

      afterEach(^{
        attributeData = nil;
      });

      it(@"should correctly draw with texture mapping", ^{
        cv::Mat4b expectedMat(kHeight, kWidth);
        expectedMat.setTo(cv::Vec4b::zeros());
        expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kRed;
        expectedMat(cv::Rect(kHalfWidth / 2, kHalfHeight / 2, kHalfWidth, kHalfHeight)) = kGreen;

        [fbo bindAndDraw:^{
          [drawer drawWithAttributeData:@[attributeData] samplerUniformsToTextures:mapping
                               uniforms:@{@"projection": $(kProjection)}];
        }];

        expect($(outputTexture.image)).to.equalMat($(expectedMat));
      });

      it(@"should correctly draw with texture mapping and uniforms", ^{
        cv::Mat4b expectedMat(kHeight, kWidth);
        expectedMat.setTo(cv::Vec4b::zeros());
        expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kDarkRed;
        expectedMat(cv::Rect(kHalfWidth / 2, kHalfHeight / 2, kHalfWidth,
                             kHalfHeight)) = kDarkGreen;

        mapping = @{@"texture": mappedTexture, @"anotherTexture": anotherMappedTexture};

        [fbo bindAndDraw:^{
          [drawer drawWithAttributeData:@[attributeData] samplerUniformsToTextures:mapping
                               uniforms:@{@"factor": @0.5, @"projection": $(kProjection)}];
        }];

        expect($(outputTexture.image)).to.equalMat($(expectedMat));
      });
    });

    context(@"invalid calls", ^{
      __block LTAttributeData *attributeData;

      beforeEach(^{
        NSData *binaryData = [NSData dataWithBytes:&fullQuad[0] length:sizeof(fullQuad)];
        attributeData =
            [[LTAttributeData alloc] initWithData:binaryData inFormatOfGPUStruct:gpuStruct];
      });

      afterEach(^{
        attributeData = nil;
      });

      it(@"should raise when attempting to draw with attribute data of invalid count", ^{
        expect(^{
          [drawer drawWithAttributeData:@[] samplerUniformsToTextures:mapping uniforms:@{}];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when attempting to draw with attribute data holding invalid GPU struct", ^{
        LTGPUStruct *anotherGPUStruct = [[LTGPUStruct alloc] initWithName:@"anotherGPUStruct" size:1
                                                                andFields:@[]];
        LTAttributeData *attributeData = [[LTAttributeData alloc] initWithData:[NSData data]
                                                           inFormatOfGPUStruct:anotherGPUStruct];
        expect(^{
          [drawer drawWithAttributeData:@[attributeData] samplerUniformsToTextures:mapping
                               uniforms:@{}];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when attempting to draw with attribute data of incorrect length", ^{
        LTDynamicDrawerTestStruct nonTriangularData[] = {
          {.position = LTVector3(-1, -1, 0), .texCoord = LTVector2(0, 0)},
        };
        NSData *data = [NSData dataWithBytes:&nonTriangularData[0]
                                      length:sizeof(nonTriangularData)];
        LTAttributeData *attributeData = [[LTAttributeData alloc] initWithData:data
                                                           inFormatOfGPUStruct:gpuStruct];
        expect(^{
          [drawer drawWithAttributeData:@[attributeData] samplerUniformsToTextures:mapping
                               uniforms:@{}];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when attempting to draw with non-existing sampler uniform", ^{
        mapping = @{@"nonExistingSamplerUniform": mappedTexture};
        expect(^{
          [drawer drawWithAttributeData:@[attributeData] samplerUniformsToTextures:mapping
                               uniforms:@{}];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when attempting to draw with non-existing uniform", ^{
        expect(^{
          [drawer drawWithAttributeData:@[attributeData] samplerUniformsToTextures:mapping
                               uniforms:@{@"nonExistingUniform": @0}];
        }).to.raise(NSInternalInconsistencyException);
      });
    });
  });

  context(@"indexed drawing of triangular geometry", ^{
    static const LTDynamicDrawerTestStruct nonOverlappingQuads[] = {
      {.position = LTVector3(-1, -1, 0), .texCoord = LTVector2(0, 0)},
      {.position = LTVector3(0, -1, 0), .texCoord = LTVector2(0.5, 0)},
      {.position = LTVector3(0, 1, 0), .texCoord = LTVector2(0.5, 1)},
      {.position = LTVector3(-1, 1, 0), .texCoord = LTVector2(0, 1)},
      {.position = LTVector3(1, -1, 0), .texCoord = LTVector2(1, 0)},
      {.position = LTVector3(1, 1, 0), .texCoord = LTVector2(1, 1)},
    };

    static const LTDynamicDrawerTestStruct overlappingQuads[] = {
      {.position = LTVector3(-1, -1, 0), .texCoord = LTVector2(0, 0)},
      {.position = LTVector3(0, -1, 0), .texCoord = LTVector2(0.5, 0)},
      {.position = LTVector3(0, 0, 0), .texCoord = LTVector2(0.5, 0.5)},
      {.position = LTVector3(-1, 0, 0), .texCoord = LTVector2(0, 0.5)},

      {.position = LTVector3(-0.5, -0.5, 0), .texCoord = LTVector2(0.5, 0)},
      {.position = LTVector3(0.5, -0.5, 0), .texCoord = LTVector2(1, 0)},
      {.position = LTVector3(0.5, 0.5, 0), .texCoord = LTVector2(1, 0.5)},
      {.position = LTVector3(-0.5, 0.5, 0), .texCoord = LTVector2(0.5, 0.5)}
    };

    context(@"non-overlapping geometry", ^{
      __block LTAttributeData *attributeData;
      __block LTIndicesData *fullQuadIndices;

      beforeEach(^{
        NSData *binaryData = [NSData dataWithBytes:&nonOverlappingQuads[0]
                                            length:sizeof(nonOverlappingQuads)];
        attributeData =
            [[LTAttributeData alloc] initWithData:binaryData inFormatOfGPUStruct:gpuStruct];

        fullQuadIndices = [LTIndicesData dataWithByteIndices:{0, 4, 5, 0, 5, 3}];
      });

      afterEach(^{
        attributeData = nil;
        fullQuadIndices = nil;
      });

      it(@"should correctly draw with texture mapping", ^{
        cv::Mat4b leftQuadExpectedMat(kHeight, kWidth, cv::Vec4b(0, 0, 0, 0));
        leftQuadExpectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kRed;
        leftQuadExpectedMat(cv::Rect(0, kHalfHeight, kHalfWidth, kHalfHeight)) = kBlue;

        LTIndicesData *leftQuadIndices = [LTIndicesData dataWithByteIndices:{0, 1, 2, 0, 2, 3}];
        [fbo bindAndDraw:^{
          [drawer drawWithAttributeData:@[attributeData] indices:leftQuadIndices
              samplerUniformsToTextures:mapping
                               uniforms:@{@"projection": $(kProjection)}];
        }];
        expect($(outputTexture.image)).to.equalMat($(leftQuadExpectedMat));

        [outputTexture clearColor:LTVector4::zeros()];
        cv::Mat4b rightQuadExpectedMat(kHeight, kWidth, cv::Vec4b(0, 0, 0, 0));
        rightQuadExpectedMat(cv::Rect(kHalfWidth, 0, kHalfWidth, kHalfHeight)) = kGreen;
        rightQuadExpectedMat(cv::Rect(kHalfWidth, kHalfHeight, kHalfWidth, kHalfHeight)) = kYellow;

        LTIndicesData *rightQuadIndices = [LTIndicesData dataWithByteIndices:{1, 4, 5, 1, 5, 2}];
        [fbo bindAndDraw:^{
          [drawer drawWithAttributeData:@[attributeData] indices:rightQuadIndices
              samplerUniformsToTextures:mapping
                               uniforms:@{@"projection": $(kProjection)}];
        }];
        expect($(outputTexture.image)).to.equalMat($(rightQuadExpectedMat));

        [outputTexture clearColor:LTVector4::zeros()];
        cv::Mat4b fullQuadExpectedMat(kHeight, kWidth);
        fullQuadExpectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kRed;
        fullQuadExpectedMat(cv::Rect(0, kHalfHeight, kHalfWidth, kHalfHeight)) = kBlue;
        fullQuadExpectedMat(cv::Rect(kHalfWidth, 0, kHalfWidth, kHalfHeight)) = kGreen;
        fullQuadExpectedMat(cv::Rect(kHalfWidth, kHalfHeight, kHalfWidth, kHalfHeight)) = kYellow;

        [fbo bindAndDraw:^{
          [drawer drawWithAttributeData:@[attributeData] indices:fullQuadIndices
              samplerUniformsToTextures:mapping
                               uniforms:@{@"projection": $(kProjection)}];
        }];
        expect($(outputTexture.image)).to.equalMat($(fullQuadExpectedMat));
      });

      it(@"should correctly draw with texture mapping and uniforms", ^{
        cv::Mat4b expectedMat(kHeight, kWidth);
        expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kDarkRed;
        expectedMat(cv::Rect(kHalfWidth, 0, kHalfWidth, kHalfHeight)) = kDarkGreen;
        expectedMat(cv::Rect(0, kHalfHeight, kHalfWidth, kHalfHeight)) = kDarkBlue;
        expectedMat(cv::Rect(kHalfWidth, kHalfHeight, kHalfWidth, kHalfHeight)) = kDarkYellow;

        mapping = @{@"texture": mappedTexture, @"anotherTexture": anotherMappedTexture};

        [fbo bindAndDraw:^{
          [drawer drawWithAttributeData:@[attributeData] indices:fullQuadIndices
              samplerUniformsToTextures:mapping
                               uniforms:@{@"factor": @0.5, @"projection": $(kProjection)}];
        }];

        expect($(outputTexture.image)).to.equalMat($(expectedMat));
      });
    });

    context(@"overlapping geometry", ^{
      __block LTAttributeData *attributeData;
      __block LTIndicesData *overlappingQuadsIndices;

      beforeEach(^{
        NSData *binaryData = [NSData dataWithBytes:&overlappingQuads[0]
                                            length:sizeof(overlappingQuads)];
        attributeData =
            [[LTAttributeData alloc] initWithData:binaryData inFormatOfGPUStruct:gpuStruct];

        overlappingQuadsIndices = [LTIndicesData dataWithByteIndices:{0, 1, 2, 0, 2, 3,
                                                                      4, 5, 6, 4, 6, 7}];
      });

      afterEach(^{
        attributeData = nil;
        overlappingQuadsIndices = nil;
      });

      it(@"should correctly draw with texture mapping", ^{
        cv::Mat4b expectedMat(kHeight, kWidth);
        expectedMat.setTo(cv::Vec4b::zeros());
        expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kRed;
        expectedMat(cv::Rect(kHalfWidth / 2, kHalfHeight / 2, kHalfWidth, kHalfHeight)) = kGreen;

        [fbo bindAndDraw:^{
          [drawer drawWithAttributeData:@[attributeData] indices:overlappingQuadsIndices
              samplerUniformsToTextures:mapping uniforms:@{@"projection": $(kProjection)}];
        }];

        expect($(outputTexture.image)).to.equalMat($(expectedMat));
      });

      it(@"should correctly draw with texture mapping and uniforms", ^{
        cv::Mat4b expectedMat(kHeight, kWidth);
        expectedMat.setTo(cv::Vec4b::zeros());
        expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kDarkRed;
        expectedMat(cv::Rect(kHalfWidth / 2, kHalfHeight / 2, kHalfWidth,
                             kHalfHeight)) = kDarkGreen;

        mapping = @{@"texture": mappedTexture, @"anotherTexture": anotherMappedTexture};

        [fbo bindAndDraw:^{
          [drawer drawWithAttributeData:@[attributeData] indices:overlappingQuadsIndices
              samplerUniformsToTextures:mapping
                               uniforms:@{@"factor": @0.5, @"projection": $(kProjection)}];
        }];

        expect($(outputTexture.image)).to.equalMat($(expectedMat));
      });
    });

    context(@"invalid calls", ^{
      __block LTAttributeData *attributeData;
      __block LTIndicesData *triangularIndices;

      beforeEach(^{
        NSData *binaryData = [NSData dataWithBytes:&nonOverlappingQuads[0]
                                            length:sizeof(nonOverlappingQuads)];
        attributeData =
            [[LTAttributeData alloc] initWithData:binaryData inFormatOfGPUStruct:gpuStruct];

        triangularIndices = [LTIndicesData dataWithByteIndices:{0, 1, 2}];
      });

      afterEach(^{
        attributeData = nil;
        triangularIndices = nil;
      });

      it(@"should raise when attempting to draw with attribute data of invalid count", ^{
        expect(^{
          [drawer drawWithAttributeData:@[] indices:triangularIndices
              samplerUniformsToTextures:mapping uniforms:@{}];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when attempting to draw with attribute data holding invalid GPU struct", ^{
        LTGPUStruct *anotherGPUStruct = [[LTGPUStruct alloc] initWithName:@"anotherGPUStruct" size:1
                                                                andFields:@[]];
        LTAttributeData *attributeData = [[LTAttributeData alloc] initWithData:[NSData data]
                                                           inFormatOfGPUStruct:anotherGPUStruct];
        expect(^{
          [drawer drawWithAttributeData:@[attributeData] indices:triangularIndices
              samplerUniformsToTextures:mapping uniforms:@{}];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when attempting to draw with indices data of incorrect count", ^{
        LTIndicesData *nonTriangularIndices = [LTIndicesData dataWithByteIndices:{0, 1}];

        expect(^{
          [drawer drawWithAttributeData:@[attributeData] indices:nonTriangularIndices
              samplerUniformsToTextures:mapping uniforms:@{}];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when attempting to draw with non-existing sampler uniform", ^{
        mapping = @{@"nonExistingSamplerUniform": mappedTexture};
        expect(^{
          [drawer drawWithAttributeData:@[attributeData] indices:triangularIndices
              samplerUniformsToTextures:mapping uniforms:@{}];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when attempting to draw with non-existing uniform", ^{
        expect(^{
          [drawer drawWithAttributeData:@[attributeData] indices:triangularIndices
              samplerUniformsToTextures:mapping uniforms:@{@"nonExistingUniform": @0}];
        }).to.raise(NSInternalInconsistencyException);
      });
    });
  });
});

context(@"properties", ^{
  it(@"should return identifier of program source code", ^{
    NSString *sourceIdentifier = drawer.sourceIdentifier;

    drawer = [[LTDynamicDrawer alloc]
              initWithVertexSource:[kVertexSource stringByAppendingString:@" "]
              fragmentSource:kFragmentSource gpuStructs:gpuStructs];

    expect(drawer.sourceIdentifier).toNot.equal(sourceIdentifier);
  });

  it(@"should return GPU structs provided upon initialization", ^{
    expect(drawer.gpuStructs).to.equal(gpuStructs);
  });
});

SpecEnd
