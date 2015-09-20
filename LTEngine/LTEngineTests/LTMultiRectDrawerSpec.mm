// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTMultiRectDrawerSpec.h"

#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTTextureDrawerExamples.h"

NSString * const kLTMultiRectDrawerExamples = @"LTMultiRectDrawerExamples";
NSString * const kLTMultiRectDrawerClass = @"LTMultiRectDrawerExamplesClass";

SharedExamplesBegin(LTMultiRectDrawerExamples)

sharedExamplesFor(kLTMultiRectDrawerExamples, ^(NSDictionary *data) {
  __block Class drawerClass;
  
  beforeEach(^{
    drawerClass = data[kLTMultiRectDrawerClass];
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
    __block id<LTMultiRectDrawer> rectDrawer;
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
      it(@"should draw an array of rotated subrects of input to an array of subrects of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect0 = CGRectMake(0, 0, inputSize.width / 2, inputSize.height / 2);
        CGRect targetRect1 = CGRectMake(inputSize.width / 2, 0,
                                        inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat sourceAngle = M_PI / 6;
        [rectDrawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0],
                                       [LTRotatedRect rect:targetRect1]]
                       inFramebuffer:fbo
                    fromRotatedRects:@[[LTRotatedRect rect:sourceRect withAngle:sourceAngle],
                                       [LTRotatedRect rect:sourceRect withAngle:sourceAngle]]];
        
        cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
        expected.setTo(cv::Vec4b(0, 0, 0, 255));
        
        cv::Mat subrect =
        LTRotatedSubrect(image, [LTRotatedRect rect:sourceRect withAngle:sourceAngle]);
        
        subrect.copyTo(expected(LTCVRectWithCGRect(targetRect0)));
        subrect.copyTo(expected(LTCVRectWithCGRect(targetRect1)));
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw an array of subrects of input to an array of rotated subrects of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect0 = CGRectMake(inputSize.width / 8, inputSize.height / 8,
                                        inputSize.width / 4, inputSize.height / 4);
        CGRect targetRect1 = CGRectMake(5 * inputSize.width / 8, 5 * inputSize.height / 8,
                                        inputSize.width / 4, inputSize.height / 4);
        CGRect sourceRect = CGRectMake(3 * inputSize.width / 8, 3 * inputSize.height / 8,
                                       inputSize.width / 4, inputSize.height / 4);
        CGFloat targetAngle = M_PI / 6;
        [rectDrawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0 withAngle:targetAngle],
                                       [LTRotatedRect rect:targetRect1 withAngle:targetAngle]]
                       inFramebuffer:fbo
                    fromRotatedRects:@[[LTRotatedRect rect:sourceRect],
                                       [LTRotatedRect rect:sourceRect]]];
        
        cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
        expected.setTo(cv::Vec4b(0, 0, 0, 255));
        
        cv::Mat4b tempMat(inputSize.width, inputSize.height);
        tempMat.setTo(cv::Vec4b(0, 0, 0, 255));
        image(LTCVRectWithCGRect(sourceRect)).copyTo(tempMat(LTCVRectWithCGRect(sourceRect)));
        tempMat = LTRotateMat(tempMat, targetAngle);
        
        CGSize tempSize = inputSize / 2;
        CGRect tempRoi = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                    inputSize.width / 2, inputSize.height / 2);
        CGRect targetRoi0 = CGRectFromOriginAndSize(CGPointZero, tempSize);
        CGRect targetRoi1 = CGRectFromOriginAndSize(CGPointZero + tempSize, tempSize);
        tempMat(LTCVRectWithCGRect(tempRoi)).copyTo(expected(LTCVRectWithCGRect(targetRoi0)));
        tempMat(LTCVRectWithCGRect(tempRoi)).copyTo(expected(LTCVRectWithCGRect(targetRoi1)));
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw an array of rotated subrects of input to an array of rotated subrects of "
         "output", ^{
           [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
           CGRect targetRect0 = CGRectMake(inputSize.width / 8, inputSize.height / 8,
                                           inputSize.width / 4, inputSize.height / 4);
           CGRect targetRect1 = CGRectMake(5 * inputSize.width / 8, 5 * inputSize.height / 8,
                                           inputSize.width / 4, inputSize.height / 4);
           CGRect sourceRect = CGRectMake(3 * inputSize.width / 8, 3 * inputSize.height / 8,
                                          inputSize.width / 4, inputSize.height / 4);
           CGFloat targetAngle = M_PI / 6;
           CGFloat sourceAngle0 = M_PI / 6;
           CGFloat sourceAngle1 = M_PI + M_PI / 6;
           [rectDrawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0 withAngle:targetAngle],
                                          [LTRotatedRect rect:targetRect1 withAngle:targetAngle]]
                          inFramebuffer:fbo
                       fromRotatedRects:@[[LTRotatedRect rect:sourceRect withAngle:sourceAngle0],
                                          [LTRotatedRect rect:sourceRect withAngle:sourceAngle1]]];
           
           cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
           expected.setTo(cv::Vec4b(0, 0, 0, 255));
           
           
           cv::Mat4b tempMat0(inputSize.width, inputSize.height);
           cv::Mat4b tempMat1(inputSize.width, inputSize.height);
           tempMat0.setTo(cv::Vec4b(0, 0, 0, 255));
           tempMat1.setTo(cv::Vec4b(0, 0, 0, 255));
           LTRotatedSubrect(image, [LTRotatedRect rect:sourceRect withAngle:sourceAngle0]).
              copyTo(tempMat0(LTCVRectWithCGRect(sourceRect)));
           LTRotatedSubrect(image, [LTRotatedRect rect:sourceRect withAngle:sourceAngle1]).
              copyTo(tempMat1(LTCVRectWithCGRect(sourceRect)));
           tempMat0 = LTRotateMat(tempMat0, targetAngle);
           tempMat1 = LTRotateMat(tempMat1, targetAngle);
           
           CGSize tempSize = inputSize / 2;
           CGRect tempRoi = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
           CGRect targetRoi0 = CGRectFromOriginAndSize(CGPointZero, tempSize);
           CGRect targetRoi1 = CGRectFromOriginAndSize(CGPointZero + tempSize, tempSize);
           tempMat0(LTCVRectWithCGRect(tempRoi)).copyTo(expected(LTCVRectWithCGRect(targetRoi0)));
           tempMat1(LTCVRectWithCGRect(tempRoi)).copyTo(expected(LTCVRectWithCGRect(targetRoi1)));
           
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
      
      it(@"should draw an array of rotated subrects of input to an array of subrects of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect0 = CGRectMake(0, 0, inputSize.width / 2, inputSize.height / 2);
        CGRect targetRect1 = CGRectMake(inputSize.width / 2, 0,
                                        inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat sourceAngle = M_PI / 6;
        
        [fbo bindAndDrawOnScreen:^{
          [rectDrawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0],
                                         [LTRotatedRect rect:targetRect1]]
                 inFramebufferWithSize:fbo.size
                      fromRotatedRects:@[[LTRotatedRect rect:sourceRect withAngle:sourceAngle],
                                         [LTRotatedRect rect:sourceRect withAngle:sourceAngle]]];
        }];
        
        [rectDrawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0],
                                       [LTRotatedRect rect:targetRect1]]
                       inFramebuffer:expectedFbo
                    fromRotatedRects:@[[LTRotatedRect rect:sourceRect withAngle:sourceAngle],
                                       [LTRotatedRect rect:sourceRect withAngle:sourceAngle]]];
        cv::flip(expectedTexture.image, expected, 0);
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw an array of subrects of input to an array of rotated subrects of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect0 = CGRectMake(inputSize.width / 8, inputSize.height / 8,
                                        inputSize.width / 4, inputSize.height / 4);
        CGRect targetRect1 = CGRectMake(5 * inputSize.width / 8, 5 * inputSize.height / 8,
                                        inputSize.width / 4, inputSize.height / 4);
        CGRect sourceRect = CGRectMake(3 * inputSize.width / 8, 3 * inputSize.height / 8,
                                       inputSize.width / 4, inputSize.height / 4);
        CGFloat targetAngle = M_PI / 6;
        
        [fbo bindAndDrawOnScreen:^{
          [rectDrawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0 withAngle:targetAngle],
                                         [LTRotatedRect rect:targetRect1 withAngle:targetAngle]]
                 inFramebufferWithSize:fbo.size
                      fromRotatedRects:@[[LTRotatedRect rect:sourceRect],
                                         [LTRotatedRect rect:sourceRect]]];
        }];
        
        [rectDrawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0 withAngle:targetAngle],
                                       [LTRotatedRect rect:targetRect1 withAngle:targetAngle]]
                       inFramebuffer:expectedFbo
                    fromRotatedRects:@[[LTRotatedRect rect:sourceRect],
                                       [LTRotatedRect rect:sourceRect]]];
        cv::flip(expectedTexture.image, expected, 0);
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw an array of rotated subrects of input to an array of rotated subrects of "
         "output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        CGRect targetRect0 = CGRectMake(inputSize.width / 8, inputSize.height / 8,
                                        inputSize.width / 4, inputSize.height / 4);
        CGRect targetRect1 = CGRectMake(5 * inputSize.width / 8, 5 * inputSize.height / 8,
                                        inputSize.width / 4, inputSize.height / 4);
        CGRect sourceRect = CGRectMake(3 * inputSize.width / 8, 3 * inputSize.height / 8,
                                       inputSize.width / 4, inputSize.height / 4);
        CGFloat targetAngle = M_PI / 6;
        CGFloat sourceAngle0 = M_PI / 6;
        CGFloat sourceAngle1 = M_PI + M_PI / 6;

        [fbo bindAndDrawOnScreen:^{
          [rectDrawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0 withAngle:targetAngle],
                                         [LTRotatedRect rect:targetRect1 withAngle:targetAngle]]
                 inFramebufferWithSize:fbo.size
                      fromRotatedRects:@[[LTRotatedRect rect:sourceRect withAngle:sourceAngle0],
                                         [LTRotatedRect rect:sourceRect withAngle:sourceAngle1]]];
        }];
           
        [rectDrawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0 withAngle:targetAngle],
                                        [LTRotatedRect rect:targetRect1 withAngle:targetAngle]]
                       inFramebuffer:expectedFbo
                    fromRotatedRects:@[[LTRotatedRect rect:sourceRect withAngle:sourceAngle0],
                                       [LTRotatedRect rect:sourceRect withAngle:sourceAngle1]]];
        cv::flip(expectedTexture.image, expected, 0);
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
    });
  });
});

SharedExamplesEnd

SpecBegin(LTMultiRectDrawer)

itShouldBehaveLike(kLTTextureDrawerExamples,
                   @{kLTTextureDrawerClass: [LTMultiRectDrawer class]});

itShouldBehaveLike(kLTMultiRectDrawerExamples,
                   @{kLTMultiRectDrawerClass: [LTMultiRectDrawer class]});

SpecEnd
