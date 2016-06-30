// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzamn.

#import "LTMeshDrawer.h"

#import <LTKit/LTRandom.h>

#import "LTFbo.h"
#import "LTForegroundBackgroundDrawer.h"
#import "LTMeshBaseDrawer.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTSingleRectDrawer.h"
#import "LTTexture+Factory.h"

@interface LTMeshDrawer ()
@property (readonly, nonatomic) LTForegroundBackgroundDrawer *foregroundBackgroundDrawer;
@end

SpecBegin(LTMeshDrawer)
static const CGSize kUnpaddedInputSize = CGSizeMake(32, 64);
static const CGFloat kPaddingLength = 20;
static const CGSize kInputSize = kUnpaddedInputSize + CGSizeMakeUniform(kPaddingLength);
static const CGSize kMeshSize = CGSizeMake(4, 8);
static NSString * const kFragmentRedFilter =
    @"uniform sampler2D sourceTexture;"
    "uniform sampler2D testAuxiliary;"
    "uniform int testUniform;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  testUniform;"
    "  testAuxiliary;"
    "  gl_FragColor = vec4(0.0, texture2D(sourceTexture, vTexcoord).gb, 1.0);"
    "}";

context(@"initialization", ^{
  __block LTTexture *inputTexture;

  beforeEach(^{
    inputTexture = [LTTexture byteRGBATextureWithSize:kInputSize];
  });

  afterEach(^{
    inputTexture = nil;
  });

  context(@"passthrough", ^{
    it(@"should initialize with a valid mesh texture", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatRG16Float)
                                           allocateMemory:YES];
      expect(^{
        __unused LTMeshDrawer *drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                                                        meshTexture:meshTexture];
      }).notTo.raiseAny();
    });

    it(@"should raise when initializing with a mesh texture of less than 2 channels", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatR16Float)
                                           allocateMemory:YES];
      expect(^{
        __unused LTMeshDrawer *drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                                                        meshTexture:meshTexture];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when initializing with a mesh texture of non half-float precision", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                           allocateMemory:YES];
      expect(^{
        __unused LTMeshDrawer *drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                                                        meshTexture:meshTexture];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"custom mesh source rect", ^{
    static const CGRect kValidMeshSourceRect = CGRectMake(10, 10, 10, 10);

    it(@"should initialize with a valid mesh texture and mesh source rect", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatRG16Float)
                                           allocateMemory:YES];
      expect(^{
        __unused LTMeshDrawer *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                         meshSourceRect:kValidMeshSourceRect
                                            meshTexture:meshTexture];
      }).notTo.raiseAny();
    });

    it(@"should raise when initializing with a mesh texture of less than 2 channels", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatR16Float)
                                           allocateMemory:YES];
      expect(^{
        __unused LTMeshDrawer *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                         meshSourceRect:kValidMeshSourceRect
                                            meshTexture:meshTexture];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when initializing with a mesh texture of non half-float precision", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                           allocateMemory:YES];
      expect(^{
        __unused LTMeshDrawer *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                         meshSourceRect:kValidMeshSourceRect
                                            meshTexture:meshTexture];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when initializing with a mesh source rect that is out of bounds", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatRG16Float)
                                           allocateMemory:YES];
      expect(^{
        LTMeshDrawer __unused *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                         meshSourceRect:CGRectMake(0, 0, 64, 64)
                                            meshTexture:meshTexture
                                         fragmentSource:[PassthroughFsh source]];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"custom fragment shader", ^{
    it(@"should initialize with a valid mesh texture", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatRG16Float)
                                           allocateMemory:YES];
      expect(^{
        LTMeshDrawer __unused *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:meshTexture
                                         fragmentSource:[PassthroughFsh source]];
      }).notTo.raiseAny();
    });

    it(@"should raise when initializing with a mesh texture of less than 2 channels", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatR16Float)
                                           allocateMemory:YES];
      expect(^{
        LTMeshDrawer __unused *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:meshTexture
                                         fragmentSource:[PassthroughFsh source]];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when initializing with a mesh texture of non half-float precision", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                           allocateMemory:YES];
      expect(^{
        LTMeshDrawer __unused *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture meshTexture:meshTexture
                                         fragmentSource:[PassthroughFsh source]];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"custom fragment shader and mesh source rect", ^{
    static const CGRect kValidMeshSourceRect = CGRectMake(10, 10, 10, 10);

    it(@"should initialize with a valid mesh texture and mesh source rect", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatRG16Float)
                                           allocateMemory:YES];
      expect(^{
        LTMeshDrawer __unused *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                         meshSourceRect:kValidMeshSourceRect
                                            meshTexture:meshTexture
                                         fragmentSource:[PassthroughFsh source]];
      }).notTo.raiseAny();
    });

    it(@"should raise when initializing with a mesh texture of less than 2 channels", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatR16Float)
                                           allocateMemory:YES];
      expect(^{
        LTMeshDrawer __unused *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                         meshSourceRect:kValidMeshSourceRect meshTexture:meshTexture
                                         fragmentSource:[PassthroughFsh source]];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when initializing with a mesh texture of non half-float precision", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                           allocateMemory:YES];
      expect(^{
        LTMeshDrawer __unused *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                         meshSourceRect:kValidMeshSourceRect meshTexture:meshTexture
                                         fragmentSource:[PassthroughFsh source]];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when initializing with a mesh source rect that is out of bounds", ^{
      LTTexture *meshTexture = [LTTexture textureWithSize:kMeshSize
                                              pixelFormat:$(LTGLPixelFormatRG16Float)
                                           allocateMemory:YES];
      expect(^{
        LTMeshDrawer __unused *drawer =
            [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                         meshSourceRect:CGRectMake(0, 0, 64, 64)
                                            meshTexture:meshTexture
                                         fragmentSource:[PassthroughFsh source]];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"drawing", ^{
  using half_float::half;

  __block CGRect meshSourceRect;
  __block LTTexture *inputTexture;
  __block LTTexture *meshTexture;
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block cv::Mat4b expected;

  beforeEach(^{
    meshSourceRect = CGRectFromOriginAndSize(CGPointMake(kPaddingLength / 2, kPaddingLength / 2),
                                             kUnpaddedInputSize);
    meshTexture = [LTTexture textureWithSize:kMeshSize + CGSizeMakeUniform(1)
                                 pixelFormat:$(LTGLPixelFormatRG16Float) allocateMemory:YES];
    [meshTexture clearWithColor:LTVector4::zeros()];
    [meshTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(cv::Vec2hf(half(0)));
      mapped->col(1).setTo(cv::Vec2hf(half(-0.5 / kMeshSize.width), half(0)));
      mapped->col(mapped->cols - 2).setTo(cv::Vec2hf(half(0.5 / kMeshSize.width), half(0)));
    }];

    inputTexture = [LTTexture byteRGBATextureWithSize:kInputSize];
    [inputTexture clearWithColor:LTVector4::ones()];
    inputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    inputTexture.minFilterInterpolation = LTTextureInterpolationNearest;
    cv::Mat4b cellsMat(kUnpaddedInputSize.height, kUnpaddedInputSize.width);
    LTRandom *random = [[LTRandom alloc] initWithSeed:0];
    CGSize cellSize = kUnpaddedInputSize / kMeshSize;
    CGSize cellRadius = cellSize / 2;
    for (int i = 0; i < kMeshSize.height; ++i) {
      for (int j = 0; j < kMeshSize.width; ++j) {
        cv::Rect rect(j * cellSize.width, i * cellSize.height, cellSize.width, cellSize.height);
        cv::Vec4b color([random randomUnsignedIntegerBelow:256],
                        [random randomUnsignedIntegerBelow:256],
                        [random randomUnsignedIntegerBelow:256], 255);
        cellsMat(rect).setTo(color);
      }
    }
    [inputTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      cellsMat.copyTo((*mapped)(LTCVRectWithCGRect(meshSourceRect)));
    }];

    output = [LTTexture textureWithPropertiesOf:inputTexture];
    fbo = [[LTFbo alloc] initWithTexture:output];

    expected = [inputTexture image];
    cv::Mat4b expectedUnpadded = expected(LTCVRectWithCGRect(meshSourceRect));
    expectedUnpadded.colRange(cellSize.width, cellSize.width + cellRadius.width)
        .copyTo(expectedUnpadded.colRange(cellRadius.width, cellSize.width));
    cv::flip(expectedUnpadded, expectedUnpadded, 1);
    expectedUnpadded.colRange(cellSize.width, cellSize.width + cellRadius.width)
        .copyTo(expectedUnpadded.colRange(cellRadius.width, cellSize.width));
    cv::flip(expectedUnpadded, expectedUnpadded, 1);
  });

  afterEach(^{
    inputTexture = nil;
    meshTexture = nil;
    output = nil;
    fbo = nil;
  });

  context(@"passthrough fragment shader", ^{
    __block LTMeshDrawer *drawer;

    beforeEach(^{
      drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                            meshSourceRect:meshSourceRect meshTexture:meshTexture
                                            fragmentSource:[PassthroughFsh source]];
    });

    afterEach(^{
      drawer = nil;
    });

    it(@"should draw in a given framebuffer", ^{
      [drawer drawRect:CGRectFromSize(output.size) inFramebuffer:fbo
              fromRect:CGRectFromSize(inputTexture.size)];
      expect($([output image])).to.equalMat($(expected));
    });

    it(@"should draw in a bound framebuffer", ^{
      [fbo bindAndDraw:^{
        [drawer drawRect:CGRectFromSize(output.size) inFramebufferWithSize:fbo.size
                fromRect:CGRectFromSize(inputTexture.size)];
      }];
      expect($([output image])).to.equalMat($(expected));
    });
  });

  context(@"custom fragment shader", ^{
    __block LTMeshDrawer *drawer;

    beforeEach(^{
      drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                            meshSourceRect:meshSourceRect meshTexture:meshTexture
                                            fragmentSource:kFragmentRedFilter];
      std::transform(expected.begin(), expected.end(), expected.begin(),
          [](const cv::Vec4b &value) {
            return cv::Vec4b(0, value[1], value[2], value[3]);
          });
    });

    afterEach(^{
      drawer = nil;
    });

    it(@"should draw in a given framebuffer", ^{
      [drawer drawRect:CGRectFromSize(output.size) inFramebuffer:fbo
              fromRect:CGRectFromSize(inputTexture.size)];
      expect($([output image])).to.equalMat($(expected));
    });

    it(@"should draw in a bound framebuffer", ^{
      [fbo bindAndDraw:^{
        [drawer drawRect:CGRectFromSize(output.size) inFramebufferWithSize:fbo.size
                fromRect:CGRectFromSize(inputTexture.size)];
      }];
      expect($([output image])).to.equalMat($(expected));
    });
  });
});

context(@"proxying", ^{
  __block LTMeshDrawer *meshBaseDrawer;
  __block LTSingleRectDrawer *backgroundDrawer;
  __block LTMeshDrawer *drawer;

  beforeEach(^{
    LTTexture *inputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    LTTexture *meshTexture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                            pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                         allocateMemory:YES];
    drawer = [[LTMeshDrawer alloc] initWithSourceTexture:inputTexture
                                          meshSourceRect:CGRectFromSize(inputTexture.size)
                                             meshTexture:meshTexture
                                          fragmentSource:kFragmentRedFilter];
    meshBaseDrawer = drawer.foregroundBackgroundDrawer.foregroundDrawer;
    backgroundDrawer = (LTSingleRectDrawer *)drawer.foregroundBackgroundDrawer.backgroundDrawer;
  });

  afterEach(^{
    drawer = nil;
    meshBaseDrawer = nil;
    backgroundDrawer = nil;
  });

  context(@"uniforms", ^{
    __block NSString *unifromName = @"testUniform";

    it(@"should set source texture", ^{
      LTTexture *sourceTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
      [drawer setSourceTexture:sourceTexture];
      OCMExpect([meshBaseDrawer setSourceTexture:sourceTexture]);
      OCMExpect([backgroundDrawer setSourceTexture:sourceTexture]);
    });

    it(@"should set auxliary texture", ^{
      LTTexture *auxiliaryTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
      NSString *auxliaryName = @"testAuxiliary";
      [drawer setAuxiliaryTexture:auxiliaryTexture withName:auxliaryName];
      OCMExpect([meshBaseDrawer setAuxiliaryTexture:auxiliaryTexture withName:auxliaryName]);
      OCMExpect([backgroundDrawer setAuxiliaryTexture:auxiliaryTexture withName:auxliaryName]);
    });

    it(@"should set unifor with value", ^{
      [meshBaseDrawer setUniform:unifromName withValue:@1];
      [backgroundDrawer setUniform:unifromName withValue:@1];

      NSNumber *uniform = @2;
      [drawer setUniform:unifromName withValue:uniform];

      expect([meshBaseDrawer uniformForName:unifromName]).to.equal(uniform);
      expect([backgroundDrawer uniformForName:unifromName]).to.equal(uniform);
    });

    it(@"should set object for key subscript", ^{
      [meshBaseDrawer setUniform:unifromName withValue:@1];
      [backgroundDrawer setUniform:unifromName withValue:@1];

      NSNumber *uniform = @2;
      [drawer setObject:uniform forKeyedSubscript:unifromName];
      expect([meshBaseDrawer uniformForName:unifromName]).to.equal(uniform);
      expect([backgroundDrawer uniformForName:unifromName]).to.equal(uniform);
    });

    it(@"shoud get object for key subscript", ^{
      NSNumber *expected = @2;
      [meshBaseDrawer setUniform:unifromName withValue:expected];
      [backgroundDrawer setUniform:unifromName withValue:expected];

      NSNumber *uniform = [drawer objectForKeyedSubscript:unifromName];
      expect(uniform).to.equal(expected);
    });

    it(@"should get uniform for name", ^{
      NSNumber *expected = @2;
      [meshBaseDrawer setUniform:unifromName withValue:expected];
      [backgroundDrawer setUniform:unifromName withValue:expected];

      NSNumber *uniform = [drawer uniformForName:unifromName];
      expect(uniform).to.equal(expected);
    });

    it(@"shoud get mandatory uniforms", ^{
      NSSet<NSString *> *expected = [meshBaseDrawer.mandatoryUniforms
                                     setByAddingObjectsFromSet:backgroundDrawer.mandatoryUniforms];
      expect(drawer.mandatoryUniforms).to.equal(expected);
    });
  });

  context(@"draw wire frame property", ^{
    it(@"should set drawWireframe", ^{
      meshBaseDrawer.drawWireframe = NO;
      drawer.drawWireframe = YES;
      expect(meshBaseDrawer.drawWireframe).to.beTruthy();
    });

    it(@"should get drawWireframe", ^{
      meshBaseDrawer.drawWireframe = YES;
      expect(drawer.drawWireframe).to.beTruthy();
      meshBaseDrawer.drawWireframe = NO;
      expect(drawer.drawWireframe).to.beFalsy();
    });
  });
});

SpecEnd
