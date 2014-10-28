// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSingleQuadDrawerSpec.h"

#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTOpenCVExtensions.h"
#import "LTProgram.h"
#import "LTQuad.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTSingleQuadDrawer.h"
#import "LTTestUtils.h"
#import "LTTextureDrawerExamples.h"
#import "LTImage.h"

NSString * const kLTSingleQuadDrawerExamples = @"LTSingleQuadDrawerExamples";
NSString * const kLTSingleQuadDrawerClass = @"LTSingleQuadDrawerExamplesClass";

SharedExamplesBegin(LTSingleQuadDrawerExamples)

sharedExamplesFor(kLTSingleQuadDrawerExamples, ^(NSDictionary *data) {
  __block Class drawerClass;

  beforeEach(^{
    drawerClass = data[kLTSingleQuadDrawerClass];
    LTGLContext *context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];

    // Make sure that everything is properly drawn when face culling is enabled.
    context.faceCullingEnabled = YES;
  });

  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });

  __block LTTexture *texture;
  __block cv::Mat image;

  CGSize inputSize = CGSizeMake(16, 16);

  beforeEach(^{
    short width = inputSize.width / 2;
    short height = inputSize.height / 2;
    image = cv::Mat(inputSize.height, inputSize.width, CV_8UC4);
    image(cv::Rect(0, 0, width, height)).setTo(cv::Vec4b(255, 0, 0, 255));
    image(cv::Rect(width, 0, width, height)).setTo(cv::Vec4b(0, 255, 0, 255));
    image(cv::Rect(0, height, width, height)).setTo(cv::Vec4b(0, 0, 255, 255));
    image(cv::Rect(width, height, width, height)).setTo(cv::Vec4b(255, 255, 0, 255));

    texture = [[LTGLTexture alloc] initWithSize:inputSize
                                      precision:LTTexturePrecisionByte
                                         format:LTTextureFormatRGBA allocateMemory:NO];
    [texture load:image];
    texture.magFilterInterpolation = LTTextureInterpolationNearest;
    texture.minFilterInterpolation = LTTextureInterpolationNearest;
  });

  afterEach(^{
    texture = nil;
  });

  context(@"drawing", ^{
    __block LTProgram *program;
    __block id<LTSingleQuadDrawer> quadDrawer;
    __block LTTexture *output;
    __block LTFbo *fbo;

    beforeEach(^{
      program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                         fragmentSource:[PassthroughFsh source]];
      quadDrawer = [[drawerClass alloc] initWithProgram:program sourceTexture:texture];

      output = [[LTGLTexture alloc] initWithSize:inputSize
                                       precision:LTTexturePrecisionByte
                                          format:LTTextureFormatRGBA allocateMemory:YES];

      fbo = [[LTFbo alloc] initWithTexture:output];
    });

    afterEach(^{
      fbo = nil;
      output = nil;
      quadDrawer = nil;
      program = nil;
    });

    /// Since the \c inFramebufferWithSize drawing implementation is equal to the \c inFramebuffer
    /// implementation, there is no need to duplicate any test here.
    context(@"bound framebuffer", ^{
      it(@"should draw a quad of input to a subrect of output", ^{
        LTQuadCorners sourceCorners{{CGPointZero,
            CGPointMake(inputSize.width, 0),
            CGPointMake(inputSize.width, inputSize.height),
            CGPointMake(0, inputSize.height / 2)}};

        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect sourceRect = CGRectFromSize(inputSize);
        [quadDrawer drawQuad:[[LTQuad alloc] initWithCorners:sourceCorners]
               inFramebuffer:fbo
                    fromQuad:[LTQuad quadFromRect:sourceRect]];

        cv::Mat expected = LTLoadMat([self class], @"SingleQuadDrawerTest0.png");

        expect($(output.image)).to.equalMat($(expected));
      });
    });

    /// Things are different when rendering to a screen framebuffer, since the output is actually
    /// different, tests were added to verify its correctness.
    context(@"screen framebuffer", ^{
      __block LTTexture *expectedTexture;
      __block LTFbo *expectedFbo;
      __block cv::Mat4b expected;

      beforeEach(^{
        expectedTexture = [[LTGLTexture alloc] initWithPropertiesOf:output];
        expectedFbo = [[LTFbo alloc] initWithTexture:expectedTexture];
        [expectedFbo clearWithColor:LTVector4(0, 0, 0, 1)];
        expected.create(expectedTexture.size.height, expectedTexture.size.width);
      });

      afterEach(^{
        expectedFbo = nil;
        expectedTexture = nil;
      });

      it(@"should draw a quad of input to a subrect of output", ^{
        LTQuadCorners sourceCorners{{CGPointZero,
          CGPointMake(inputSize.width, 0),
          CGPointMake(inputSize.width, inputSize.height),
          CGPointMake(0, inputSize.height / 2)}};

        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect sourceRect = CGRectFromSize(inputSize);
        [fbo bindAndDrawOnScreen:^{
          [quadDrawer drawQuad:[[LTQuad alloc] initWithCorners:sourceCorners]
         inFramebufferWithSize:fbo.size
                      fromQuad:[LTQuad quadFromRect:sourceRect]];
        }];

        [quadDrawer drawQuad:[[LTQuad alloc] initWithCorners:sourceCorners]
               inFramebuffer:expectedFbo
                    fromQuad:[LTQuad quadFromRect:sourceRect]];
        cv::flip(expectedTexture.image, expected, 0);

        expect($(output.image)).to.equalMat($(expected));
      });
    });
  });
});

SharedExamplesEnd

SpecBegin(LTSingleQuadDrawer)

itShouldBehaveLike(kLTTextureDrawerExamples,
                   @{kLTTextureDrawerClass: [LTSingleQuadDrawer class]});

itShouldBehaveLike(kLTSingleQuadDrawerExamples,
                   @{kLTSingleQuadDrawerClass: [LTSingleQuadDrawer class]});

SpecEnd
