// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "LTAdjustOperations.h"

#import "LTOpenCVExtensions.h"

SpecBegin(LTAdjustOperations)

context(@"tonal adjustment", ^{
  it(@"should return a matrix leaving greyscale input unchanged on hue modification", ^{
    GLKVector4 input = GLKVector4Make(128, 128, 128, 255);
    GLKVector4 expectedOutput = GLKVector4Make(128, 128, 128, 255);
    
    GLKMatrix4 tonalTransform = LTTonalTransformMatrix(0.0, 0.0, 0.0, 0.5);
    GLKVector4 result = GLKMatrix4MultiplyVector4(tonalTransform, input);
    expect(result).to.beCloseToGLKVectorWithin(expectedOutput, 1);
  });
  
  it(@"should return a matrix processing hue correctly", ^{
    GLKVector4 input = GLKVector4Make(128, 0, 0, 255);
    GLKVector4 expectedOutput = GLKVector4Make(-51, 76, 76, 255);
    
    GLKMatrix4 tonalTransform = LTTonalTransformMatrix(0.0, 0.0, 0.0, 1.0);
    GLKVector4 result = GLKMatrix4MultiplyVector4(tonalTransform, input);
    expect(result).to.beCloseToGLKVectorWithin(expectedOutput, 1);
  });
  
  it(@"should return a matrix processing saturation correctly", ^{
    GLKVector4 input = GLKVector4Make(0, 128, 255, 255);
    GLKVector4 expectedOutput = GLKVector4Make(104, 104, 104, 255);
    
    GLKMatrix4 tonalTransform = LTTonalTransformMatrix(0.0, 0.0, -1.0, 0.0);
    GLKVector4 result = GLKMatrix4MultiplyVector4(tonalTransform, input);
    expect(result).to.beCloseToGLKVectorWithin(expectedOutput, 1);
  });
  
  it(@"should return a matrix processing temperature correctly", ^{
    GLKVector4 input = GLKVector4Make(51, 77, 102, 255);
    GLKVector4 expectedOutput = GLKVector4Make(65, 72, 85, 255);
    
    GLKMatrix4 tonalTransform = LTTonalTransformMatrix(0.2, 0.0, 0.0, 0.0);
    GLKVector4 result = GLKMatrix4MultiplyVector4(tonalTransform, input);
    expect(result).to.beCloseToGLKVectorWithin(expectedOutput, 1);
  });
  
  it(@"should return a matrix processing tint correctly", ^{
    GLKVector4 input = GLKVector4Make(51, 77, 102, 255);
    GLKVector4 expectedOutput = GLKVector4Make(61, 67, 128, 255);
    
    GLKMatrix4 tonalTransform = LTTonalTransformMatrix(0.0, 0.2, 0.0, 0.0);
    GLKVector4 result = GLKMatrix4MultiplyVector4(tonalTransform, input);
    expect(result).to.beCloseToGLKVectorWithin(expectedOutput, 1);
  });
  
  it(@"should return a matrix processing color correctly", ^{
    GLKVector4 input = GLKVector4Make(51, 77, 102, 255);
    // See lightricks-research/enlight/Adjust/runmeAdjustColorTest.m to reproduce this result.
    // Minor differences (~1-3 on 0-255 scale) are expected.
    GLKVector4 expectedOutput = GLKVector4Make(57, 79, 72, 255);
    
    GLKMatrix4 tonalTransform = LTTonalTransformMatrix(0.2, -0.1, 0.2, 0.0);
    GLKVector4 result = GLKMatrix4MultiplyVector4(tonalTransform, input);
    expect(result).to.beCloseToGLKVectorWithin(expectedOutput, 1);
  });
});

context(@"luminance adjustment", ^{
  it(@"should return a curve processing positive brightness and contrast correctly", ^{
    cv::Mat4b expectedOutput(1, 1, cv::Vec4b(101, 101, 101, 255));
    cv::Mat1b luminanceCurve = LTLuminanceCurve(0.5, 0.15, 0.0, 0.0);
    cv::Mat4b output(1, 1, cv::Vec4b(luminanceCurve(0,64), luminanceCurve(0,64),
                                     luminanceCurve(0,64), 255));
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });

  it(@"should return a curve processing negative contrast correctly", ^{
    cv::Mat4b expectedOutput(1, 1, cv::Vec4b(174, 134, 88, 255));
    
    cv::Mat1b luminanceCurve = LTLuminanceCurve(0.0, -1.0, 0.0, 0.0);
    cv::Mat4b output(1, 1, cv::Vec4b(luminanceCurve(0,192), luminanceCurve(0,128),
                                     luminanceCurve(0,64), 255));
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });
  
  it(@"should return a curve processing offset correctly", ^{
    cv::Mat4b expectedOutput(1, 1, cv::Vec4b(128, 128, 128, 255));
    
    cv::Mat1b luminanceCurve = LTLuminanceCurve(0.0, 0.0, 0.0, 0.5);
    cv::Mat4b output(1, 1, cv::Vec4b(luminanceCurve(0,0), luminanceCurve(0,0), luminanceCurve(0,0),
                                     255));
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });
  
  it(@"should return a curve processing exposure correctly", ^{
    cv::Mat4b expectedOutput(1, 1, cv::Vec4b(255, 255, 255, 255));
    
    cv::Mat1b luminanceCurve = LTLuminanceCurve(0.0, 0.0, 1.0, 0.0);
    cv::Mat4b output(1, 1, cv::Vec4b(luminanceCurve(0,128), luminanceCurve(0,128),
                                     luminanceCurve(0,128), 255));
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });
});

SpecEnd
