// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTDynamicQuadDrawer.h"

#import "LTAttributeData.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGPUStruct.h"
#import "LTOpenCVExtensions.h"
#import "LTShaderStorage+MixFsh.h"
#import "LTShaderStorage+MixVsh.h"
#import "LTShaderStorage+MixWithAttributeFsh.h"
#import "LTShaderStorage+MixWithAttributeVsh.h"
#import "LTTexture+Factory.h"

LTGPUStructMake(LTDynamicQuadDrawerTestStruct,
                float, vertexFactor);

SpecBegin(LTDynamicQuadDrawer)

__block LTDynamicQuadDrawer *drawer;

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
  context.faceCullingEnabled = YES;

  drawer = [[LTDynamicQuadDrawer alloc] initWithVertexSource:[MixVsh source]
                                              fragmentSource:[MixFsh source]
                                                  gpuStructs:[NSOrderedSet orderedSet]];
});

afterEach(^{
  drawer = nil;
  [LTGLContext setCurrentContext:nil];
});

context(@"initialization", ^{
  it(@"should correctly initialize", ^{
    expect(drawer).toNot.beNil();
  });

  context(@"invalid calls", ^{
    it(@"should raise when attempting to initialize with gpu structs with overlapping fields", ^{
      LTGPUStructField *field =
          [[LTGPUStructField alloc] initWithName:@"fieldName" type:@"float" size:1 andOffset:0];
      LTGPUStruct *gpuStruct =[[LTGPUStruct alloc] initWithName:@"name" size:1 andFields:@[field]];
      LTGPUStruct *gpuStructWithSameAttribute =
          [[LTGPUStruct alloc] initWithName:@"anotherName" size:gpuStruct.size + 1
                                  andFields:@[field]];
      NSOrderedSet<LTGPUStruct *> *gpuStructs =
          [NSOrderedSet orderedSetWithArray:@[gpuStruct, gpuStructWithSameAttribute]];
      expect(^{
        drawer = [[LTDynamicQuadDrawer alloc] initWithVertexSource:[MixVsh source]
                                                    fragmentSource:[MixFsh source]
                                                        gpuStructs:gpuStructs];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize with gpu structs with same name", ^{
      LTGPUStruct *gpuStruct = [[LTGPUStruct alloc] initWithName:@"name" size:1 andFields:@[]];
      LTGPUStruct *gpuStructWithSameName = [[LTGPUStruct alloc] initWithName:gpuStruct.name size:1
                                                                   andFields:@[]];
      NSOrderedSet<LTGPUStruct *> *gpuStructs =
          [NSOrderedSet orderedSetWithArray:@[gpuStruct, gpuStructWithSameName]];
      expect(^{
        drawer = [[LTDynamicQuadDrawer alloc] initWithVertexSource:[MixVsh source]
                                                    fragmentSource:[MixFsh source]
                                                        gpuStructs:gpuStructs];
      }).to.raise(NSInternalInconsistencyException);
    });

    it(@"should raise when attempting to initialize with gpu struct with forbidden name", ^{
      LTGPUStruct *gpuStructWithForbiddenName =
          [[LTGPUStruct alloc] initWithName:kLTQuadDrawerGPUStructName size:1
                                  andFields:@[]];
      NSOrderedSet<LTGPUStruct *> *gpuStructs =
          [NSOrderedSet orderedSetWithArray:@[gpuStructWithForbiddenName]];
      expect(^{
        drawer = [[LTDynamicQuadDrawer alloc] initWithVertexSource:[MixVsh source]
                                                    fragmentSource:[MixFsh source]
                                                        gpuStructs:gpuStructs];
      }).to.raise(NSInternalInconsistencyException);
    });

    it(@"should raise when attempting to initialize with gpu structs with forbidden field names", ^{
      LTGPUStructField *fieldWithForbiddenName =
          [[LTGPUStructField alloc] initWithName:kLTQuadDrawerAttributePosition type:@"float" size:1
                                       andOffset:0];
      LTGPUStructField *anotherFieldWithForbiddenName =
          [[LTGPUStructField alloc] initWithName:kLTQuadDrawerAttributeTexCoord type:@"float" size:1
                                       andOffset:0];

      LTGPUStruct *gpuStructWithForbiddenFieldNames =
          [[LTGPUStruct alloc] initWithName:kLTQuadDrawerGPUStructName size:1
                                  andFields:@[fieldWithForbiddenName,
                                              anotherFieldWithForbiddenName]];
      NSOrderedSet<LTGPUStruct *> *gpuStructs =
          [NSOrderedSet orderedSetWithArray:@[gpuStructWithForbiddenFieldNames]];
      expect(^{
        drawer = [[LTDynamicQuadDrawer alloc] initWithVertexSource:[MixVsh source]
                                                    fragmentSource:[MixFsh source]
                                                        gpuStructs:gpuStructs];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"drawing", ^{
  static const cv::Vec4b kRed(255, 0, 0, 255);
  static const cv::Vec4b kDarkRed(128, 0, 0, 255);
  static const cv::Vec4b kGreen(0, 255, 0, 255);
  static const cv::Vec4b kDarkGreen(0, 128, 0, 255);
  static const cv::Vec4b kBlue(0, 0, 255, 255);
  static const cv::Vec4b kDarkBlue(0, 0, 128, 255);
  static const cv::Vec4b kYellow(255, 255, 0, 255);
  static const cv::Vec4b kDarkYellow(128, 128, 0, 255);

  static const CGFloat kWidth = 100;
  static const CGFloat kHalfWidth = kWidth / 2;
  static const CGFloat kHeight = 200;
  static const CGFloat kHalfHeight = kHeight / 2;

  static const lt::Quad fullQuad(CGPointMake(0, 0),
                                 CGPointMake(1, 0),
                                 CGPointMake(1, 1),
                                 CGPointMake(0, 1));

  static const lt::Quad halfSizedQuad(CGPointMake(0, 0),
                                      CGPointMake(0.5, 0),
                                      CGPointMake(0.5, 0.5),
                                      CGPointMake(0, 0.5));

  static const lt::Quad shiftedHalfSizedQuad = halfSizedQuad.translatedBy(CGPointMake(0.25, 0.25));

  static const lt::Quad allColorsTexCoords(CGPointMake(0, 0),
                                           CGPointMake(1, 0),
                                           CGPointMake(1, 1),
                                           CGPointMake(0, 1));

  static const LTDynamicQuadDrawerTestStruct singleQuadFactorStruct[] = {
    {.vertexFactor = 0.5},
    {.vertexFactor = 0.5},
    {.vertexFactor = 0.5},
    {.vertexFactor = 0.5},
    {.vertexFactor = 0.5},
    {.vertexFactor = 0.5}
  };

  static const LTDynamicQuadDrawerTestStruct doubleQuadFactorStruct[] = {
    {.vertexFactor = 0.5},
    {.vertexFactor = 0.5},
    {.vertexFactor = 0.5},
    {.vertexFactor = 0.5},
    {.vertexFactor = 0.5},
    {.vertexFactor = 0.5},
    {.vertexFactor = 1},
    {.vertexFactor = 1},
    {.vertexFactor = 1},
    {.vertexFactor = 1},
    {.vertexFactor = 1},
    {.vertexFactor = 1}
  };

  static const lt::Quad redColorTexCoords = halfSizedQuad;
  static const lt::Quad greenColorTexCoords = halfSizedQuad.translatedBy(CGPointMake(0.5, 0));

  __block LTTexture *mappedTexture;
  __block LTTexture *anotherMappedTexture;
  __block LTTexture *outputTexture;
  __block LTFbo *fbo;

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
  });

  afterEach(^{
    mappedTexture = nil;
    anotherMappedTexture = nil;
    outputTexture = nil;
    fbo = nil;
  });

  context(@"non-overlapping geometry", ^{
    it(@"should correctly draw", ^{
      cv::Mat4b expectedMat(kHeight, kWidth);
      expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kRed;
      expectedMat(cv::Rect(kHalfWidth, 0, kHalfWidth, kHalfHeight)) = kGreen;
      expectedMat(cv::Rect(0, kHalfHeight, kHalfWidth, kHalfHeight)) = kBlue;
      expectedMat(cv::Rect(kHalfWidth, kHalfHeight, kHalfWidth, kHalfHeight)) = kYellow;

      [fbo bindAndDraw:^{
        [drawer drawQuads:{fullQuad} textureMapQuads:{allColorsTexCoords}
            attributeData:@[] texture:mappedTexture auxiliaryTextures:@{} uniforms:@{}];
      }];

      expect($(outputTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should correctly draw with texture mapping and uniforms", ^{
      cv::Mat4b expectedMat(kHeight, kWidth);
      expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kDarkRed;
      expectedMat(cv::Rect(kHalfWidth, 0, kHalfWidth, kHalfHeight)) = kDarkGreen;
      expectedMat(cv::Rect(0, kHalfHeight, kHalfWidth, kHalfHeight)) = kDarkBlue;
      expectedMat(cv::Rect(kHalfWidth, kHalfHeight, kHalfWidth, kHalfHeight)) = kDarkYellow;

      NSDictionary<NSString *, LTTexture *> *mapping = @{@"anotherTexture": anotherMappedTexture};

      [fbo bindAndDraw:^{
        [drawer drawQuads:{fullQuad} textureMapQuads:{allColorsTexCoords}
            attributeData:@[] texture:mappedTexture auxiliaryTextures:mapping
                 uniforms:@{@"factor": @0.5}];
      }];

      expect($(outputTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should correctly draw with additional attributes", ^{
      LTGPUStruct *gpuStruct =
          [[LTGPUStructRegistry sharedInstance] structForName:@"LTDynamicQuadDrawerTestStruct"];

      drawer = [[LTDynamicQuadDrawer alloc]
                initWithVertexSource:[MixWithAttributeVsh source]
                fragmentSource:[MixWithAttributeFsh source]
                gpuStructs:[NSOrderedSet orderedSetWithObject:gpuStruct]];

      cv::Mat4b expectedMat(kHeight, kWidth);
      expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kDarkRed;
      expectedMat(cv::Rect(kHalfWidth, 0, kHalfWidth, kHalfHeight)) = kDarkGreen;
      expectedMat(cv::Rect(0, kHalfHeight, kHalfWidth, kHalfHeight)) = kDarkBlue;
      expectedMat(cv::Rect(kHalfWidth, kHalfHeight, kHalfWidth, kHalfHeight)) = kDarkYellow;

      NSData *binaryData = [NSData dataWithBytes:&singleQuadFactorStruct[0]
                                          length:sizeof(singleQuadFactorStruct)];
      LTAttributeData *data = [[LTAttributeData alloc] initWithData:binaryData
                                                inFormatOfGPUStruct:gpuStruct];

      [fbo bindAndDraw:^{
        [drawer drawQuads:{fullQuad} textureMapQuads:{allColorsTexCoords}
            attributeData:@[data] texture:mappedTexture auxiliaryTextures:@{} uniforms:@{}];
      }];

      expect($(outputTexture.image)).to.equalMat($(expectedMat));
    });
  });

  context(@"overlapping geometry", ^{
    it(@"should correctly draw", ^{
      cv::Mat4b expectedMat(kHeight, kWidth);
      expectedMat.setTo(cv::Vec4b::zeros());
      expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kRed;
      expectedMat(cv::Rect(kHalfWidth / 2, kHalfHeight / 2, kHalfWidth, kHalfHeight)) = kGreen;

      [fbo bindAndDraw:^{
        [drawer drawQuads:{halfSizedQuad, shiftedHalfSizedQuad}
          textureMapQuads:{redColorTexCoords, greenColorTexCoords}
            attributeData:@[] texture:mappedTexture auxiliaryTextures:@{} uniforms:@{}];
      }];

      expect($(outputTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should correctly draw with texture mapping and uniforms", ^{
      cv::Mat4b expectedMat(kHeight, kWidth);
      expectedMat.setTo(cv::Vec4b::zeros());
      expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kDarkRed;
      expectedMat(cv::Rect(kHalfWidth / 2, kHalfHeight / 2, kHalfWidth, kHalfHeight)) = kDarkGreen;

      NSDictionary<NSString *, LTTexture *> *mapping = @{@"anotherTexture": anotherMappedTexture};

      [fbo bindAndDraw:^{
        [drawer drawQuads:{halfSizedQuad, shiftedHalfSizedQuad}
          textureMapQuads:{redColorTexCoords, greenColorTexCoords}
            attributeData:@[] texture:mappedTexture auxiliaryTextures:mapping
                 uniforms:@{@"factor": @0.5}];
      }];

      expect($(outputTexture.image)).to.equalMat($(expectedMat));
    });

    it(@"should correctly draw with additional attributes", ^{
      LTGPUStruct *gpuStruct =
          [[LTGPUStructRegistry sharedInstance] structForName:@"LTDynamicQuadDrawerTestStruct"];

      drawer = [[LTDynamicQuadDrawer alloc]
                initWithVertexSource:[MixWithAttributeVsh source]
                fragmentSource:[MixWithAttributeFsh source]
                gpuStructs:[NSOrderedSet orderedSetWithObject:gpuStruct]];

      cv::Mat4b expectedMat(kHeight, kWidth);
      expectedMat.setTo(cv::Vec4b::zeros());
      expectedMat(cv::Rect(0, 0, kHalfWidth, kHalfHeight)) = kDarkRed;
      expectedMat(cv::Rect(kHalfWidth / 2, kHalfHeight / 2, kHalfWidth, kHalfHeight)) = kGreen;

      NSData *binaryData = [NSData dataWithBytes:&doubleQuadFactorStruct[0]
                                          length:sizeof(doubleQuadFactorStruct)];
      LTAttributeData *data = [[LTAttributeData alloc] initWithData:binaryData
                                                inFormatOfGPUStruct:gpuStruct];

      [fbo bindAndDraw:^{
        [drawer drawQuads:{halfSizedQuad, shiftedHalfSizedQuad}
          textureMapQuads:{redColorTexCoords, greenColorTexCoords}
            attributeData:@[data] texture:mappedTexture auxiliaryTextures:@{} uniforms:@{}];
      }];

      expect($(outputTexture.image)).to.equalMat($(expectedMat));
    });
  });

  context(@"general quad drawing", ^{
    __block LTTexture *checkerboardTexture;

    beforeEach(^{
      cv::Mat4b checkerboard =
          LTCheckerboardPattern(CGSizeMakeUniform(8), 1, cv::Vec4b(0, 0, 0, 255),
                                cv::Vec4b(255, 255, 255, 255));
      checkerboardTexture = [LTTexture textureWithImage:checkerboard];
      checkerboardTexture.magFilterInterpolation = LTTextureInterpolationLinear;
      checkerboardTexture.minFilterInterpolation = LTTextureInterpolationLinear;
    });

    afterEach(^{
      checkerboardTexture = nil;
    });

    context(@"general quad geometry", ^{
      it(@"should draw a perspectively distorted quad", ^{
        lt::Quad quad({{CGPointZero, CGPointMake(1, 0.4), CGPointMake(1, 0.6), CGPointMake(0, 1)}});
        [fbo bindAndDraw:^{
          [drawer drawQuads:{quad} textureMapQuads:{lt::Quad::canonicalSquare()} attributeData:@[]
                    texture:checkerboardTexture auxiliaryTextures:@{} uniforms:@{}];
        }];

        cv::Mat expected(LTLoadMat([self class], @"PerspectiveQuad0.png"));
        expect($([outputTexture image])).to.beCloseToMatWithin($(expected), 1);
      });

      it(@"should draw another perspectively distorted quad", ^{
        lt::Quad quad({{
          CGPointMake(0.4, 0),
          CGPointMake(0.6, 0),
          CGPointMake(1, 1),
          CGPointMake(0, 1)
        }});
        [fbo bindAndDraw:^{
          [drawer drawQuads:{quad} textureMapQuads:{lt::Quad::canonicalSquare()} attributeData:@[]
                    texture:checkerboardTexture auxiliaryTextures:@{} uniforms:@{}];
        }];

        cv::Mat expected(LTLoadMat([self class], @"PerspectiveQuad1.png"));
        expect($([outputTexture image])).to.beCloseToMatPSNR($(expected), 50);
      });

      it(@"should draw a general quad", ^{
        lt::Quad quad({{
          CGPointZero,
          CGPointMake(0.8, 0.2),
          CGPointMake(0.9, 0.7),
          CGPointMake(0.1, 0.3)
        }});
        [fbo bindAndDraw:^{
          [drawer drawQuads:{quad} textureMapQuads:{lt::Quad::canonicalSquare()} attributeData:@[]
                    texture:checkerboardTexture auxiliaryTextures:@{} uniforms:@{}];
        }];

        cv::Mat expected(LTLoadMat([self class], @"PerspectiveGeneralQuad.png"));
        expect($([outputTexture image])).to.beCloseToMatWithin($(expected), 1);
      });
    });

    context(@"general texture quads", ^{
      it(@"should draw with a quad portion of a texture", ^{
        lt::Quad quad({{CGPointZero, CGPointMake(1, 0.4), CGPointMake(1, 0.6), CGPointMake(0, 1)}});
        [fbo bindAndDraw:^{
          [drawer drawQuads:{lt::Quad::canonicalSquare()} textureMapQuads:{quad} attributeData:@[]
                    texture:checkerboardTexture auxiliaryTextures:@{} uniforms:@{}];
        }];

        cv::Mat expected(LTLoadMat([self class], @"PerspectiveTextureQuad0.png"));
        expect($([outputTexture image])).to.beCloseToMatWithin($(expected), 1);
      });

      it(@"should draw with another quad portion of a texture", ^{
        lt::Quad quad({{
          CGPointMake(0.4, 0),
          CGPointMake(0.6, 0),
          CGPointMake(1, 1),
          CGPointMake(0, 1)
        }});
        [fbo bindAndDraw:^{
          [drawer drawQuads:{lt::Quad::canonicalSquare()} textureMapQuads:{quad} attributeData:@[]
                    texture:checkerboardTexture auxiliaryTextures:@{} uniforms:@{}];
        }];

        cv::Mat expected(LTLoadMat([self class], @"PerspectiveTextureQuad1.png"));
        expect($([outputTexture image])).to.beCloseToMatPSNR($(expected), 50);
      });

      it(@"should draw with yet another quad portion of a texture", ^{
        lt::Quad quad({{
          CGPointZero,
          CGPointMake(0.8, 0.2),
          CGPointMake(0.9, 0.7),
          CGPointMake(0.1, 0.3)
        }});
        [fbo bindAndDraw:^{
          [drawer drawQuads:{lt::Quad::canonicalSquare()} textureMapQuads:{quad} attributeData:@[]
                    texture:checkerboardTexture auxiliaryTextures:@{} uniforms:@{}];
        }];

        cv::Mat expected(LTLoadMat([self class], @"PerspectiveTextureQuad2.png"));
        expect($([outputTexture image])).to.beCloseToMatPSNR($(expected), 50);
      });
    });

    context(@"general quad geometry and general texture quads", ^{
      __block lt::Quad quad;

      beforeEach(^{
        quad = lt::Quad({{
          CGPointZero,
          CGPointMake(0.8, 0.2),
          CGPointMake(0.9, 0.7),
          CGPointMake(0.1, 0.9)
        }});
      });

      it(@"should draw a general quad with a rectangular subregion of a texture", ^{
        lt::Quad rectangularQuad(CGRectMake(0, 0, 1.0 / 4.0, 1.0 / 4.0));
        [fbo bindAndDraw:^{
          [drawer drawQuads:{quad} textureMapQuads:{rectangularQuad} attributeData:@[]
                    texture:checkerboardTexture auxiliaryTextures:@{} uniforms:@{}];
        }];

        cv::Mat expected(LTLoadMat([self class],
                                   @"PerspectiveGeneralQuadWithRectPortionOfTexture.png"));
        expect($([outputTexture image])).to.beCloseToMatPSNR($(expected), 50);
      });

      it(@"should draw a general quad with a quad portion of a texture", ^{
        [fbo bindAndDraw:^{
          [drawer drawQuads:{quad} textureMapQuads:{quad} attributeData:@[]
                    texture:checkerboardTexture auxiliaryTextures:@{} uniforms:@{}];
        }];

        cv::Mat expected(LTLoadMat([self class],
                                   @"PerspectiveGeneralQuadWithQuadPortionOfTexture0.png"));
        expect($([outputTexture image])).to.beCloseToMatPSNR($(expected), 50);
      });

      it(@"should draw a general quad with another quad portion of a texture", ^{
        lt::Quad textureQuad({{
          CGPointMake(0.4, 0),
          CGPointMake(0.6, 0),
          CGPointMake(1, 1),
          CGPointMake(0, 1)
        }});
        [fbo bindAndDraw:^{
          [drawer drawQuads:{quad} textureMapQuads:{textureQuad} attributeData:@[]
                    texture:checkerboardTexture auxiliaryTextures:@{} uniforms:@{}];
        }];

        cv::Mat expected(LTLoadMat([self class],
                                   @"PerspectiveGeneralQuadWithQuadPortionOfTexture1.png"));
        expect($([outputTexture image])).to.beCloseToMatPSNR($(expected), 50);
      });
    });
  });

  context(@"invalid calls", ^{
    it(@"should raise when attempting to draw with mismatching number of quads and tex coords", ^{
      expect(^{
        [drawer drawQuads:{fullQuad} textureMapQuads:{redColorTexCoords, greenColorTexCoords}
            attributeData:@[] texture:mappedTexture auxiliaryTextures:@{} uniforms:@{}];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to draw with texture mapped with forbidden name", ^{
      expect(^{
        [drawer drawQuads:{fullQuad} textureMapQuads:{redColorTexCoords, greenColorTexCoords}
            attributeData:@[] texture:mappedTexture
        auxiliaryTextures:@{kLTQuadDrawerSamplerUniformTextureMap: anotherMappedTexture}
                 uniforms:@{}];
      }).to.raise(NSInvalidArgumentException);
    });

#if defined(DEBUG) && DEBUG
    it(@"should raise when attempting to draw with uniform overriding internally set projection", ^{
      expect(^{
        [drawer drawQuads:{fullQuad} textureMapQuads:{allColorsTexCoords} attributeData:@[]
                  texture:mappedTexture auxiliaryTextures:@{}
                 uniforms:@{kLTQuadDrawerUniformProjection: $(GLKMatrix4Identity)}];
      }).to.raise(NSInvalidArgumentException);
    });
#endif
  });
});

context(@"properties", ^{
  it(@"should return identifier of program source code", ^{
    NSString *sourceIdentifier = drawer.sourceIdentifier;

    drawer = [[LTDynamicQuadDrawer alloc]
              initWithVertexSource:[[MixVsh source] stringByAppendingString:@" "]
              fragmentSource:[MixFsh source] gpuStructs:[NSOrderedSet orderedSet]];

    expect(drawer.sourceIdentifier).toNot.equal(sourceIdentifier);
  });

  context(@"GPU structs", ^{
    __block NSOrderedSet<LTGPUStruct *> *gpuStructs;

    beforeEach(^{
      LTGPUStruct *gpuStruct =
          [[LTGPUStructRegistry sharedInstance] structForName:@"LTDynamicQuadDrawerTestStruct"];
      gpuStructs = [NSOrderedSet orderedSetWithObject:gpuStruct];

      drawer = [[LTDynamicQuadDrawer alloc]
                initWithVertexSource:[MixWithAttributeVsh source]
                fragmentSource:[MixWithAttributeFsh source]
                gpuStructs:gpuStructs];
    });

    it(@"should return GPU structs provided upon initialization", ^{
      expect(drawer.initialGPUStructs).to.equal(gpuStructs);
    });

    it(@"should return GPU structs used by instance", ^{
      NSMutableOrderedSet<LTGPUStruct *> *augmentedGPUStructs = [gpuStructs mutableCopy];
      [augmentedGPUStructs addObject:[[LTGPUStructRegistry sharedInstance]
                                      structForName:kLTQuadDrawerGPUStructName]];
      expect(drawer.gpuStructs).to.equal(augmentedGPUStructs);
    });
  });
});

SpecEnd
