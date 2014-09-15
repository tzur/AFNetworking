// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSingleRectDrawerSpec.h"

#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTTestUtils.h"
#import "LTTextureDrawerExamples.h"

NSString * const kLTSingleRectDrawerExamples = @"LTSingleRectDrawerExamples";
NSString * const kLTSingleRectDrawerClass = @"LTSingleRectDrawerExamplesClass";

SharedExamplesBegin(LTSingleRectDrawerExamples)

sharedExamplesFor(kLTSingleRectDrawerExamples, ^(NSDictionary *data) {
  __block Class drawerClass;

  beforeEach(^{
    drawerClass = data[kLTSingleRectDrawerClass];
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
  });
  
  afterEach(^{
    texture = nil;
  });
  
  context(@"drawing", ^{
    __block LTProgram *program;
    __block id<LTSingleRectDrawer> rectDrawer;
    __block LTTexture *output;
    __block LTFbo *fbo;
    
    beforeEach(^{
      program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                         fragmentSource:[PassthroughFsh source]];
      rectDrawer = [[drawerClass alloc] initWithProgram:program sourceTexture:texture];
      
      output = [[LTGLTexture alloc] initWithSize:inputSize
                                       precision:LTTexturePrecisionByte
                                          format:LTTextureFormatRGBA allocateMemory:YES];
      
      fbo = [[LTFbo alloc] initWithTexture:output];
    });
    
    afterEach(^{
      fbo = nil;
      output = nil;
      rectDrawer = nil;
      program = nil;
    });

    /// Since the \c inFramebufferWithSize drawing implenentation is no different then the
    /// \c inFramebuffer implementation, there is no need to duplicate all the tests here.
    context(@"bound framebuffer", ^{
      it(@"should draw a rotated subrect of input to subrect of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect = CGRectMake(inputSize.width / 2, 0,
                                       inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat sourceAngle = M_PI / 6;
        [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect]
                      inFramebuffer:fbo
                    fromRotatedRect:[LTRotatedRect rect:sourceRect withAngle:sourceAngle]];
        
        cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
        expected.setTo(cv::Vec4b(0, 0, 0, 255));
        
        cv::Mat subrect =
        LTRotatedSubrect(image, [LTRotatedRect rect:sourceRect withAngle:sourceAngle]);
        cv::Rect targetRoi(inputSize.width / 2, 0, inputSize.width / 2, inputSize.height / 2);
        subrect.copyTo(expected(targetRoi));
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw a subrect of input to a rotated subrect of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 2, 0,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat targetAngle = M_PI / 6;
        [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
                      inFramebuffer:fbo
                    fromRotatedRect:[LTRotatedRect rect:sourceRect]];
        
        cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
        expected.setTo(cv::Vec4b(0, 0, 0, 255));
        
        expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(0, 255, 0, 255));
        expected = LTRotateMat(expected, targetAngle);
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw a rotated subrect of input to a rotated subrect of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat targetAngle = M_PI / 6;
        CGFloat sourceAngle = M_PI / 6;
        [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
                      inFramebuffer:fbo
                    fromRotatedRect:[LTRotatedRect rect:sourceRect withAngle:sourceAngle]];
        
        cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
        expected.setTo(cv::Vec4b(0, 0, 0, 255));
        
        cv::Mat subrect =
        LTRotatedSubrect(image, [LTRotatedRect rect:sourceRect withAngle:sourceAngle]);
        subrect.copyTo(expected(LTCVRectWithCGRect(targetRect)));
        expected = LTRotateMat(expected, targetAngle);
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
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
      
      it(@"should draw a rotated subrect of input to subrect of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect = CGRectMake(inputSize.width / 2, 0,
                                       inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat sourceAngle = M_PI / 6;
        
        [fbo bindAndDrawOnScreen:^{
          [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect]
                inFramebufferWithSize:fbo.size
                      fromRotatedRect:[LTRotatedRect rect:sourceRect withAngle:sourceAngle]];
        }];
        
        [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect]
                      inFramebuffer:expectedFbo
                    fromRotatedRect:[LTRotatedRect rect:sourceRect withAngle:sourceAngle]];
        cv::flip(expectedTexture.image, expected, 0);
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw a subrect of input to a rotated subrect of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 2, 0,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat targetAngle = M_PI / 6;
        
        [fbo bindAndDrawOnScreen:^{
          [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
                inFramebufferWithSize:fbo.size
                      fromRotatedRect:[LTRotatedRect rect:sourceRect]];
        }];
        
        [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
                      inFramebuffer:expectedFbo
                    fromRotatedRect:[LTRotatedRect rect:sourceRect]];
        cv::flip(expectedTexture.image, expected, 0);
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw a rotated subrect of input to a rotated subrect of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat targetAngle = M_PI / 6;
        CGFloat sourceAngle = M_PI / 6;
        
        [fbo bindAndDrawOnScreen:^{
          [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
                inFramebufferWithSize:fbo.size
                      fromRotatedRect:[LTRotatedRect rect:sourceRect withAngle:sourceAngle]];
        }];
        
        [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
                      inFramebuffer:expectedFbo
                    fromRotatedRect:[LTRotatedRect rect:sourceRect withAngle:sourceAngle]];
        cv::flip(expectedTexture.image, expected, 0);
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
    });
  });
});

SharedExamplesEnd

SpecBegin(LTSingleRectDrawer)

itShouldBehaveLike(kLTTextureDrawerExamples,
                   @{kLTTextureDrawerClass: [LTSingleRectDrawer class]});

itShouldBehaveLike(kLTSingleRectDrawerExamples,
                   @{kLTSingleRectDrawerClass: [LTSingleRectDrawer class]});

SpecEnd
