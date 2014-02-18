// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTProcessingDrawerExamples.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTProgram.h"
#import "LTRotatedRect.h"
#import "LTShaderStorage+PassthroughVsh.h"
#import "LTShaderStorage+PassthroughFsh.h"
#import "LTTestUtils.h"
#import "NSValue+GLKitExtensions.h"

NSString * const kLTProcessingDrawerExamples = @"LTProcessingDrawerExamples";
NSString * const kLTProcessingDrawerClass = @"LTProcessingDrawerExamplesClass";

#pragma mark -
#pragma mark Shared Tests
#pragma mark -

/// Returns a rotated subrect of the given \c cv::Mat.
///
/// @see http://answers.opencv.org/question/497/extract-a-rotatedrect-area/
static cv::Mat4b LTRotatedSubrect(const cv::Mat4b input, LTRotatedRect *subrect) {
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

/// Rotates (clockwise) the given mat by the given angle (in radians) around its center.
static cv::Mat4b LTRotateMat(const cv::Mat4b input, CGFloat angle) {
  angle = angle * (-180 / M_PI);
  cv::Point2f center((input.cols / 2.0) - 0.5, (input.rows / 2.0) - 0.5);
  cv::Mat R = cv::getRotationMatrix2D(center, angle, 1.0);
  cv::Mat4b rotated;
  cv::warpAffine(input, rotated, R, input.size(), cv::INTER_NEAREST, cv::BORDER_REPLICATE);
  return rotated;
}

SharedExamplesBegin(LTProcessingDrawerExamples)

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

sharedExamplesFor(kLTProcessingDrawerExamples, ^(NSDictionary *data) {
  __block Class drawerClass;
  
  beforeEach(^{
    drawerClass = data[kLTProcessingDrawerClass];
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
    __block id<LTProcessingDrawer> drawer;
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
      it(@"should draw to to target texture of the same size", ^{
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
        [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
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
        [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
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
    
    context(@"rotated rect", ^{
      it(@"should draw a rotated subrect of input to subrect of output", ^{
        [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
        CGRect targetRect = CGRectMake(inputSize.width / 2, 0,
                                       inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat sourceAngle = M_PI / 6;
        [drawer drawRotatedRect:[LTRotatedRect rect:targetRect]
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
        [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
        CGRect targetRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 2, 0,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat targetAngle = M_PI / 6;
        [drawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
                  inFramebuffer:fbo
                fromRotatedRect:[LTRotatedRect rect:sourceRect]];
        
        cv::Mat expected(inputSize.width, inputSize.height, CV_8UC4);
        expected.setTo(cv::Vec4b(0, 0, 0, 255));
        
        expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(0, 255, 0, 255));
        expected = LTRotateMat(expected, targetAngle);
        
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
        [drawer drawRotatedRect:[LTRotatedRect rect:targetRect withAngle:targetAngle]
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
    
    context(@"array of rotated rects", ^{
      it(@"should draw an array of rotated subrects of input to an array of subrects of output", ^{
        [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
        CGRect targetRect0 = CGRectMake(0, 0, inputSize.width / 2, inputSize.height / 2);
        CGRect targetRect1 = CGRectMake(inputSize.width / 2, 0,
                                        inputSize.width / 2, inputSize.height / 2);
        CGRect sourceRect = CGRectMake(inputSize.width / 4, inputSize.height / 4,
                                       inputSize.width / 2, inputSize.height / 2);
        CGFloat sourceAngle = M_PI / 6;
        [drawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0],
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
        [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
        CGRect targetRect0 = CGRectMake(inputSize.width / 8, inputSize.height / 8,
                                        inputSize.width / 4, inputSize.height / 4);
        CGRect targetRect1 = CGRectMake(5 * inputSize.width / 8, 5 * inputSize.height / 8,
                                        inputSize.width / 4, inputSize.height / 4);
        CGRect sourceRect = CGRectMake(3 * inputSize.width / 8, 3 * inputSize.height / 8,
                                       inputSize.width / 4, inputSize.height / 4);
        CGFloat targetAngle = M_PI / 6;
        [drawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0 withAngle:targetAngle],
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
           [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
           CGRect targetRect0 = CGRectMake(inputSize.width / 8, inputSize.height / 8,
                                           inputSize.width / 4, inputSize.height / 4);
           CGRect targetRect1 = CGRectMake(5 * inputSize.width / 8, 5 * inputSize.height / 8,
                                           inputSize.width / 4, inputSize.height / 4);
           CGRect sourceRect = CGRectMake(3 * inputSize.width / 8, 3 * inputSize.height / 8,
                                          inputSize.width / 4, inputSize.height / 4);
           CGFloat targetAngle = M_PI / 6;
           CGFloat sourceAngle0 = M_PI / 6;
           CGFloat sourceAngle1 = M_PI + M_PI / 6;
           [drawer drawRotatedRects:@[[LTRotatedRect rect:targetRect0 withAngle:targetAngle],
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
    __block id<LTProcessingDrawer> drawer;
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
    __block id<LTProcessingDrawer> drawer;
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
      GLKVector4 outputColor = GLKVector4Make(1, 0, 0, 1);
      NSValue *value = $(outputColor);
      drawer[@"outputColor"] = value;
      
      expect(drawer[@"outputColor"]).to.equal(value);
    });
    
    it(@"should draw given color to target", ^{
      GLKVector4 outputColor = GLKVector4Make(1, 0, 0, 1);
      drawer[@"outputColor"] = $(outputColor);
      
      [drawer drawRect:CGRectMake(0, 0, inputSize.width, inputSize.height) inFramebuffer:fbo
              fromRect:CGRectMake(0, 0, inputSize.width, inputSize.height)];
      
      cv::Mat expected(inputSize.height, inputSize.width, CV_8UC4);
      expected.setTo(LTGLKVector4ToVec4b(outputColor));
      
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
  });
});

SharedExamplesEnd
