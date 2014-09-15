// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureDrawerExamples.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTTestUtils.h"
#import "NSValue+GLKitExtensions.h"

NSString * const kLTTextureDrawerExamples = @"LTTextureDrawerExamples";
NSString * const kLTTextureDrawerClass = @"LTTextureDrawerExamplesClass";

#pragma mark -
#pragma mark Shared Tests
#pragma mark -

/// @see http://answers.opencv.org/question/497/extract-a-rotatedrect-area/
cv::Mat4b LTRotatedSubrect(const cv::Mat4b input, LTRotatedRect *subrect) {
  cv::RotatedRect rect(cv::Point2f(subrect.center.x - 0.5, subrect.center.y - 0.5),
                       cv::Size2f(subrect.rect.size.width, subrect.rect.size.height),
                       subrect.angle * (180 / M_PI));

  CGFloat angle = rect.angle;
  cv::Size2f size = rect.size;
  if (rect.angle < -45.0) {
    angle += 90.0;
    size = cv::Size2f(size.height, size.width);
  }
  cv::Mat R = cv::getRotationMatrix2D(rect.center, angle, 1.0);

  // For some reason, openCV getRectSubPix does not support RGBA and needs to be performed one
  // channel at a time.
  cv::Mat1b inputR(input.rows, input.cols);
  cv::Mat1b inputG(input.rows, input.cols);
  cv::Mat1b inputB(input.rows, input.cols);
  cv::Mat1b inputA(input.rows, input.cols);
  
  cv::Mat mixIn[] = {input};
  cv::Mat mixOut[] = {inputR, inputG, inputB, inputA};
  int fromTo[] = {0, 0, 1, 1, 2, 2, 3, 3};
  cv::mixChannels(mixIn, 1, mixOut, 4, fromTo, 4);
  
  cv::Mat1b rotatedR, rotatedG, rotatedB, rotatedA;
  cv::Mat1b croppedR, croppedG, croppedB, croppedA;
  
  cv::warpAffine(inputR, rotatedR, R, inputR.size(), cv::INTER_NEAREST, cv::BORDER_CONSTANT, 0);
  cv::warpAffine(inputG, rotatedG, R, inputR.size(), cv::INTER_NEAREST, cv::BORDER_CONSTANT, 0);
  cv::warpAffine(inputB, rotatedB, R, inputR.size(), cv::INTER_NEAREST, cv::BORDER_CONSTANT, 0);
  cv::warpAffine(inputA, rotatedA, R, inputR.size(), cv::INTER_NEAREST, cv::BORDER_CONSTANT, 255);
  
  cv::getRectSubPix(rotatedR, size, rect.center, croppedR);
  cv::getRectSubPix(rotatedG, size, rect.center, croppedG);
  cv::getRectSubPix(rotatedB, size, rect.center, croppedB);
  cv::getRectSubPix(rotatedA, size, rect.center, croppedA);

  cv::Mat4b cropped(croppedR.rows, croppedR.cols);
  cv::Mat mixIn2[] = {croppedR, croppedG, croppedB, croppedA};
  cv::Mat mixOut2[] = {cropped};
  int fromTo2[] = {0, 0, 1, 1, 2, 2, 3, 3};
  cv::mixChannels(mixIn2, 4, mixOut2, 1, fromTo2, 4);

  return cropped;
}

SharedExamplesBegin(LTTextureDrawerExamples)

static NSString * const kMissingVertexSource =
    @"uniform highp mat4 modelview;"
    "uniform highp mat4 projection;"
    ""
    "attribute highp vec4 position;"
    "attribute highp vec3 texcoord;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  vec4 newpos = vec4(position.xy, 0.0, 1.0);"
    "  vTexcoord = texcoord.xy;"
    "  gl_Position = projection * modelview * newpos;"
    "}";

static NSString * const kFragmentWithUniformSource =
    @"uniform sampler2D sourceTexture;"
    "uniform highp vec4 outputColor;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  sourceTexture;"
    "  gl_FragColor = outputColor;"
    "}";

static NSString * const kFragmentWithThreeSamplersSource =
    @"uniform sampler2D sourceTexture;"
    "uniform sampler2D anotherTexture;"
    "uniform sampler2D otherTexture;"
    ""
    "varying highp vec2 vTexcoord;"
    ""
    "void main() {"
    "  highp vec4 colorA = texture2D(sourceTexture, vTexcoord);"
    "  highp vec4 colorB = texture2D(anotherTexture, vTexcoord);"
    "  highp vec4 colorC = texture2D(otherTexture, vTexcoord);"
    "  gl_FragColor = vec4(colorA.xyz - colorB.xyz + colorC.xyz, 0.0);"
    "}";

sharedExamplesFor(kLTTextureDrawerExamples, ^(NSDictionary *data) {
  __block Class drawerClass;
  
  beforeEach(^{
    drawerClass = data[kLTTextureDrawerClass];
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
    texture.minFilterInterpolation = LTTextureInterpolationNearest;
    texture.magFilterInterpolation = LTTextureInterpolationNearest;
  });
  
  afterEach(^{
    texture = nil;
  });
  
  context(@"initialization", ^{
    it(@"should initialize with valid program", ^{
      LTProgram *program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                                    fragmentSource:[PassthroughFsh source]];
      
      expect(^{
        __unused id drawer = [[drawerClass alloc] initWithProgram:program
                                                    sourceTexture:texture];
      }).toNot.raiseAny();
    });
    
    it(@"should not initialize with program with missing uniforms", ^{
      LTProgram *program = [[LTProgram alloc] initWithVertexSource:kMissingVertexSource
                                                    fragmentSource:[PassthroughFsh source]];
      
      expect(^{
        __unused id drawer = [[drawerClass alloc] initWithProgram:program
                                                    sourceTexture:texture];
      }).to.raise(NSInvalidArgumentException);
    });
  });
  
  context(@"drawing", ^{
    __block LTProgram *program;
    __block id<LTTextureDrawer> drawer;
    __block LTTexture *output;
    __block LTFbo *fbo;
    
    beforeEach(^{
      program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                         fragmentSource:[PassthroughFsh source]];
      drawer = [[drawerClass alloc] initWithProgram:program sourceTexture:texture];
      
      output = [[LTGLTexture alloc] initWithSize:inputSize
                                       precision:LTTexturePrecisionByte
                                          format:LTTextureFormatRGBA allocateMemory:YES];
      
      fbo = [[LTFbo alloc] initWithTexture:output];
    });
    
    afterEach(^{
      fbo = nil;
      output = nil;
      drawer = nil;
      program = nil;
    });
    
    context(@"framebuffer", ^{
      it(@"should draw to target texture of the same size", ^{
        [drawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height) inFramebuffer:fbo
                fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
        
        expect(LTCompareMat(output.image, image)).to.beTruthy();
      });
      
      it(@"should draw subrect of input to entire output", ^{
        [drawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height) inFramebuffer:fbo
                fromRect:CGRectMake(inputSize.width / 2, 0,
                                    inputSize.width / 2, inputSize.height / 2)];
        
        cv::Mat expected(inputSize.height, inputSize.width, CV_8UC4);
        expected.setTo(image.at<cv::Vec4b>(0, inputSize.width / 2));
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw all input to subrect of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        [drawer drawRect:CGRectMake(inputSize.width / 2, 0,
                                    inputSize.width / 2, inputSize.height / 2)
           inFramebuffer:fbo fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
        
        // Actual image should be a resized version at (0, w/2). Prepare the resized version and put
        // it where it belongs.
        cv::Mat resized;
        cv::resize(image, resized, cv::Size(), 0.5, 0.5, cv::INTER_NEAREST);
        
        cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
        expected.setTo(cv::Vec4b(0, 0, 0, 255));
        
        cv::Rect roi(inputSize.width / 2, 0, inputSize.width / 2, inputSize.height / 2);
        resized.copyTo(expected(roi));
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
      
      it(@"should draw subrect of input to subrect of output", ^{
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        [drawer drawRect:CGRectMake(inputSize.width / 2, 0,
                                    inputSize.width / 2, inputSize.height / 2)
           inFramebuffer:fbo fromRect:CGRectMake(0, 0, inputSize.width / 2, inputSize.height / 2)];
        
        cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
        expected.setTo(cv::Vec4b(0, 0, 0, 255));
        
        cv::Rect targetRoi(inputSize.width / 2, 0, inputSize.width / 2, inputSize.height / 2);
        cv::Rect sourceRoi(0, 0, inputSize.width / 2, inputSize.height / 2);
        image(sourceRoi).copyTo(expected(targetRoi));
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
    });
    
    context(@"screen framebuffer", ^{
      it(@"should draw subrect of input to entire output", ^{
        const CGRect subrect = CGRectMake(2 * inputSize.width / 16, 3 * inputSize.height / 16,
                                          inputSize.width / 2, inputSize.height / 2);
        [fbo bindAndDrawOnScreen:^{
          [drawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height)
         inFramebufferWithSize:fbo.size fromRect:subrect];
        }];
        
        // Actual image should be a resized version of the subimage at the given range, flipped
        // across the x-axis.
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
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        [fbo bindAndDrawOnScreen:^{
          [drawer drawRect:subrect inFramebufferWithSize:fbo.size
                      fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
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
        [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
        [fbo bindAndDrawOnScreen:^{
          [drawer drawRect:outRect inFramebufferWithSize:fbo.size fromRect:inRect];
        }];
        
        // Actual image should be a resized version of the subimage at inputSubrect positioned at
        // the given outputSubrect.
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
    });
    
    context(@"source texture switching", ^{
      it(@"should switch source texture", ^{
        cv::Mat expected(inputSize.height, inputSize.width, CV_8UC4);
        expected.setTo(cv::Vec4b(137, 137, 0, 255));
        
        LTTexture *secondTexture = [[LTGLTexture alloc] initWithImage:expected];
        [drawer setSourceTexture:secondTexture];
        
        CGRect rect = CGRectMake(0, 0, inputSize.width, inputSize.height);
        [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];
        
        expect(LTCompareMat(expected, output.image)).to.beTruthy();
      });
    
      it(@"should raise when switching to nil source texture", ^{
        expect(^{
          [drawer setSourceTexture:nil];
        }).to.raise(NSInvalidArgumentException);
      });
    });
  });
  
  context(@"auxiliary texture inputs", ^{
    __block LTProgram *program;
    __block id<LTTextureDrawer> drawer;
    __block LTTexture *clearTexture;
    __block LTTexture *output;
    __block LTFbo *fbo;
    
    beforeEach(^{
      program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                         fragmentSource:kFragmentWithThreeSamplersSource];
      drawer = [[drawerClass alloc] initWithProgram:program sourceTexture:texture
                                  auxiliaryTextures:@{@"otherTexture": texture}];
      
      output = [[LTGLTexture alloc] initWithSize:inputSize
                                       precision:LTTexturePrecisionByte
                                          format:LTTextureFormatRGBA
                                  allocateMemory:YES];
      clearTexture = [[LTGLTexture alloc] initWithImage:cv::Mat4b::zeros(image.rows, image.cols)];
      
      fbo = [[LTFbo alloc] initWithTexture:output];
    });
    
    afterEach(^{
      fbo = nil;
      output = nil;
      drawer = nil;
      program = nil;
    });
    
    it(@"should contain initial auxiliary texture", ^{
      expect(^{
        [drawer setAuxiliaryTexture:texture withName:@"anotherTexture"];
        
        CGRect rect = CGRectMake(0, 0, inputSize.width, inputSize.height);
        [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];
        
        expect(LTCompareMat([texture image], [output image])).to.beTruthy();
      });
    });
    
    it(@"should set valid texture with correct name", ^{
      expect(^{
        [drawer setAuxiliaryTexture:texture withName:@"anotherTexture"];
      }).toNot.raiseAny();
    });
    
    it(@"should raise when setting a nil texture", ^{
      expect(^{
        [drawer setAuxiliaryTexture:nil withName:@"anotherTexture"];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise when setting a nil name", ^{
      expect(^{
        [drawer setAuxiliaryTexture:texture withName:nil];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise when setting a non existing name", ^{
      expect(^{
        [drawer setAuxiliaryTexture:texture withName:@"foo"];
      }).to.raise(NSInternalInconsistencyException);
    });
    
    it(@"should draw multiple inputs correctly", ^{
      [drawer setAuxiliaryTexture:texture withName:@"anotherTexture"];
      [drawer setAuxiliaryTexture:clearTexture withName:@"otherTexture"];
      
      CGRect rect = CGRectMake(0, 0, inputSize.width, inputSize.height);
      [drawer drawRect:rect inFramebuffer:fbo fromRect:rect];
      
      expect(LTCompareMatWithValue(cv::Scalar(0, 0, 0, 0), [output image])).to.beTruthy();
    });
  });
  
  context(@"custom uniforms", ^{
    __block LTProgram *program;
    __block id<LTTextureDrawer> drawer;
    __block LTTexture *output;
    __block LTFbo *fbo;
    
    beforeEach(^{
      program = [[LTProgram alloc] initWithVertexSource:[PassthroughVsh source]
                                         fragmentSource:kFragmentWithUniformSource];
      drawer = [[drawerClass alloc] initWithProgram:program sourceTexture:texture];
      
      output = [[LTGLTexture alloc] initWithSize:inputSize
                                       precision:LTTexturePrecisionByte
                                          format:LTTextureFormatRGBA allocateMemory:YES];
      
      fbo = [[LTFbo alloc] initWithTexture:output];
    });
    
    afterEach(^{
      fbo = nil;
      output = nil;
      drawer = nil;
      program = nil;
    });
    
    it(@"should set and retrieve uniform", ^{
      LTVector4 outputColor = LTVector4(1, 0, 0, 1);
      NSValue *value = $(outputColor);
      drawer[@"outputColor"] = value;
      
      expect(drawer[@"outputColor"]).to.equal(value);
    });
    
    it(@"should draw given color to target", ^{
      LTVector4 outputColor = LTVector4(1, 0, 0, 1);
      drawer[@"outputColor"] = $(outputColor);
      
      [drawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height) inFramebuffer:fbo
              fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
      
      cv::Mat expected(inputSize.height, inputSize.width, CV_8UC4);
      expected.setTo(LTLTVector4ToVec4b(outputColor));
      
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
  });
});

SharedExamplesEnd
