// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSingleRectDrawerSpec.h"

#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTProcessingDrawerExamples.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTTestUtils.h"

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
      it(@"should draw to to target texture of the same size", ^{
        [fbo bindAndDraw:^{
          [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height)
         inFramebufferWithSize:fbo.size
                      fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
        }];
        
        expect(LTCompareMat(output.image, image)).to.beTruthy();
      });
    });
    
    /// Things are different when rendering to a screen framebuffer, since the output is actually
    /// different, tests were added to verify its correctness.
    context(@"screen framebuffer", ^{
      it(@"should draw to target texture of the same size", ^{
        [fbo bindAndDraw:^{
          [LTGLContext currentContext].renderingToScreen = YES;
          [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height)
         inFramebufferWithSize:fbo.size
                      fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
          [LTGLContext currentContext].renderingToScreen = NO;
        }];
        
        cv::Mat expected(image.rows, image.cols, CV_8UC4);
        cv::flip(image, expected, 0);
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw subrect of input to entire output", ^{
        const CGRect subrect = CGRectMake(2 * inputSize.width / 16, 3 * inputSize.height / 16,
                                          inputSize.width / 2, inputSize.height / 2);
        [fbo bindAndDraw:^{
          [LTGLContext currentContext].renderingToScreen = YES;
          [rectDrawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height)
              inFramebufferWithSize:fbo.size fromRect:subrect];
          [LTGLContext currentContext].renderingToScreen = NO;
        }];
        
        // Actual image should be a resized version of the subimage at the given range, flipped across
        // the x-axis.
        cv::Mat expected(inputSize.height, inputSize.width, CV_8UC4);
        cv::Mat subimage = image(cv::Rect(subrect.origin.x, subrect.origin.y,
                                          subrect.size.width, subrect.size.height));
        cv::resize(subimage, expected,
                   cv::Size(expected.cols, expected.rows), 0, 0, cv::INTER_NEAREST);
        cv::flip(expected, expected, 0);
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw all input to subrect of output", ^{
        const CGRect subrect = CGRectMake(2 * inputSize.width / 16, 3 * inputSize.height / 16,
                                          inputSize.width / 2, inputSize.height / 2);
        [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
        [fbo bindAndDraw:^{
          [LTGLContext currentContext].renderingToScreen = YES;
          [rectDrawer drawRect:subrect inFramebufferWithSize:fbo.size
                      fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
          [LTGLContext currentContext].renderingToScreen = NO;
        }];
        
        // Actual image should be a resized version positioned at the given subrect.
        cv::Mat resized;
        cv::resize(image, resized, cv::Size(), 0.5, 0.5, cv::INTER_NEAREST);
        cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
        expected.setTo(cv::Vec4b(0, 0, 0, 255));
        resized.copyTo(expected(cv::Rect(subrect.origin.x, subrect.origin.y,
                                         subrect.size.width, subrect.size.height)));
        cv::flip(expected, expected, 0);
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw subrect of input to subrect of output", ^{
        const CGRect inRect = CGRectMake(6 * inputSize.width / 16, 7 * inputSize.height / 16,
                                         inputSize.width / 4, inputSize.height / 4);
        const CGRect outRect = CGRectMake(2 * inputSize.width / 16, 3 * inputSize.height / 16,
                                          inputSize.width / 2, inputSize.height / 2);
        [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
        [fbo bindAndDraw:^{
          [LTGLContext currentContext].renderingToScreen = YES;
          [rectDrawer drawRect:outRect inFramebufferWithSize:fbo.size fromRect:inRect];
          [LTGLContext currentContext].renderingToScreen = NO;
        }];
        
        // Actual image should be a resized version of the subimage at inputSubrect positioned at the
        // given outputSubrect.
        cv::Mat resized;
        cv::Mat subimage = image(cv::Rect(inRect.origin.x, inRect.origin.y,
                                          inRect.size.width, inRect.size.height));
        cv::resize(subimage, resized,
                   cv::Size(outRect.size.width, outRect.size.height), 0, 0, cv::INTER_NEAREST);
        
        cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
        expected.setTo(cv::Vec4b(0, 0, 0, 255));
        resized.copyTo(expected(cv::Rect(outRect.origin.x, outRect.origin.y,
                                         outRect.size.width, outRect.size.height)));
        cv::flip(expected, expected, 0);
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      context(@"rotated rect", ^{
        __block LTTexture *expectedTexture;
        __block LTFbo *expectedFbo;
        __block cv::Mat4b expected;
        
        beforeEach(^{
          expectedTexture = [[LTGLTexture alloc] initWithPropertiesOf:output];
          expectedFbo = [[LTFbo alloc] initWithTexture:expectedTexture];
          [expectedFbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
          expected.create(expectedTexture.size.height, expectedTexture.size.width);
        });
        
        afterEach(^{
          expectedFbo = nil;
          expectedTexture = nil;
        });
        
        it(@"should draw a rotated subrect of input to subrect of output", ^{
          [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
          CGRect targetRect = CGRectMake(inputSize.width / 2, 0,
                                         inputSize.width / 2, inputSize.height / 2);
          CGRect sourceRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                         inputSize.width / 2, inputSize.height / 2);
          CGFloat sourceAngle = M_PI / 6;
          
          [fbo bindAndDraw:^{
            [LTGLContext currentContext].renderingToScreen = YES;
            [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect]
                  inFramebufferWithSize:fbo.size
                        fromRotatedRect:[LTRotatedRect rect:sourceRect withAngle:sourceAngle]];
            [LTGLContext currentContext].renderingToScreen = NO;
          }];
          
          [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect]
                        inFramebuffer:expectedFbo
                      fromRotatedRect:[LTRotatedRect rect:sourceRect withAngle:sourceAngle]];
          cv::flip(expectedTexture.image, expected, 0);
          
          expect(LTCompareMat(expected, output.image)).to.beTruthy();
        });
        
        it(@"should draw a subrect of input to a rotated subrect of output", ^{
          [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
          CGRect targetRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                         inputSize.width / 2, inputSize.height / 2);
          CGRect sourceRect = CGRectMake(inputSize.width / 2, 0,
                                         inputSize.width / 2, inputSize.height / 2);
          CGFloat targetAngle = M_PI / 6;
          
          [fbo bindAndDraw:^{
            [LTGLContext currentContext].renderingToScreen = YES;
            [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
                  inFramebufferWithSize:fbo.size
                        fromRotatedRect:[LTRotatedRect rect:sourceRect]];
            [LTGLContext currentContext].renderingToScreen = NO;
          }];
          
          [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
                        inFramebuffer:expectedFbo
                      fromRotatedRect:[LTRotatedRect rect:sourceRect]];
          cv::flip(expectedTexture.image, expected, 0);
          
          expect(LTCompareMat(expected, output.image)).to.beTruthy();
        });
        
        it(@"should draw a rotated subrect of input to a rotated subrect of output", ^{
          [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
          CGRect targetRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                         inputSize.width / 2, inputSize.height / 2);
          CGRect sourceRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                         inputSize.width / 2, inputSize.height / 2);
          CGFloat targetAngle = M_PI / 6;
          CGFloat sourceAngle = M_PI / 6;
          
          [fbo bindAndDraw:^{
            [LTGLContext currentContext].renderingToScreen = YES;
            [rectDrawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
                  inFramebufferWithSize:fbo.size
                        fromRotatedRect:[LTRotatedRect rect:sourceRect withAngle:sourceAngle]];
            [LTGLContext currentContext].renderingToScreen = NO;
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
});

SharedExamplesEnd

SpecBegin(LTSingleRectDrawer)

itShouldBehaveLike(kLTProcessingDrawerExamples,
                   @{kLTProcessingDrawerClass: [LTSingleRectDrawer class]});

itShouldBehaveLike(kLTSingleRectDrawerExamples,
                   @{kLTSingleRectDrawerClass: [LTSingleRectDrawer class]});

SpecEnd
