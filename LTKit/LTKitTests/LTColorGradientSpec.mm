// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorGradient.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTColorGradient)

static const LTColorGradientControlPoint *controlPoint0 = [[LTColorGradientControlPoint alloc]
    initWithPosition:0.0 color:GLKVector3Make(0.0, 0.0, 0.0)];
static const LTColorGradientControlPoint *controlPoint1 = [[LTColorGradientControlPoint alloc]
    initWithPosition:0.25 color:GLKVector3Make(0.25, 0.0, 0.0)];
static const LTColorGradientControlPoint *controlPoint2 = [[LTColorGradientControlPoint alloc]
    initWithPosition:0.5 color:GLKVector3Make(0.5, 0.0, 0.0)];
static const LTColorGradientControlPoint *controlPoint3 = [[LTColorGradientControlPoint alloc]
    initWithPosition:0.75 color:GLKVector3Make(0.75, 0.0, 0.0)];
static const LTColorGradientControlPoint *controlPoint4 = [[LTColorGradientControlPoint alloc]
    initWithPosition:1.0 color:GLKVector3Make(1.0, 0.0, 0.0)];
static const LTColorGradientControlPoint *controlPoint5 = [[LTColorGradientControlPoint alloc]
    initWithPosition:0.75 color:GLKVector3Make(0.5, 0.0, 0.75)];
static const LTColorGradientControlPoint *controlPoint6 = [[LTColorGradientControlPoint alloc]
    initWithPosition:1.0 color:GLKVector3Make(0.0, 0.0, 1.0)];

NSArray *oneControlPoint = @[controlPoint0];
NSArray *twoControlPoints = @[controlPoint0, controlPoint4];
NSArray *threeControlPoints = @[controlPoint0, controlPoint2, controlPoint4];
NSArray *nonIncreasingPoints = @[controlPoint1, controlPoint1, controlPoint3];
NSArray *redControlPoints = @[controlPoint0, controlPoint1, controlPoint2, controlPoint3,
                              controlPoint4];
NSArray *redBlueControlPoints = @[controlPoint0, controlPoint1, controlPoint2, controlPoint5,
                                  controlPoint6];

context(@"LTColorGradientControlPoint intialization", ^{
  it(@"should not initialize on position which is out of range", ^{
    expect(^{
      __unused LTColorGradientControlPoint *controlPoint = [[LTColorGradientControlPoint alloc]
          initWithPosition:2.0 color:GLKVector3Make(0.0, 0.0, 1.0)];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should initialize on position within the range", ^{
    expect(^{
      __unused LTColorGradientControlPoint *controlPoint = [[LTColorGradientControlPoint alloc]
          initWithPosition:0.5 color:GLKVector3Make(0.0, 0.0, 1.0)];
    }).toNot.raiseAny();
  });
  
  it(@"should initialize using class method on position within the range", ^{
    expect(^{
      GLKVector3 whiteColor = GLKVector3Make(1.0, 1.0, 1.0);
      __unused LTColorGradientControlPoint *controlPoint =
          [LTColorGradientControlPoint controlPointWithPosition:0.5 color:whiteColor];
    }).toNot.raiseAny();
  });
  
  it(@"should not initialize using class method on position out the range", ^{
    expect(^{
      GLKVector4 blueColor = GLKVector4Make(0.0, 0.0, 1.0, 1.0);
      __unused LTColorGradientControlPoint *controlPoint =
          [LTColorGradientControlPoint controlPointWithPosition:2.0 colorWithAlpha:blueColor];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"LTColorGradient intialization", ^{
  it(@"should not initialize on nil", ^{
    expect(^{
      __unused LTColorGradient *colorGradient = [[LTColorGradient alloc] initWithControlPoints:nil];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not initialize on one control point", ^{
    expect(^{
      __unused LTColorGradient *colorGradient =
          [[LTColorGradient alloc] initWithControlPoints:oneControlPoint];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not initialize on non-monotonically increasing control points", ^{
    expect(^{
      __unused LTColorGradient *colorGradient =
          [[LTColorGradient alloc] initWithControlPoints:nonIncreasingPoints];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should initialize on two control points", ^{
    expect(^{
      __unused LTColorGradient *colorGradient =
          [[LTColorGradient alloc] initWithControlPoints:twoControlPoints];
    }).toNot.raiseAny();
  });
  
  it(@"should initialize on three control points", ^{
    expect(^{
      __unused LTColorGradient *colorGradient =
          [[LTColorGradient alloc] initWithControlPoints:threeControlPoints];
    }).toNot.raiseAny();
  });
});

context(@"writing gradient values to mat", ^{
  it(@"should be equal to [0-1] linear gradient with two points", ^{
    cv::Mat4b identity = [[LTColorGradient identityGradient] matWithSamplingPoints:2];
    cv::Mat4b grid(1, 2);
    grid = cv::Vec4b(255, 0, 0, 255);
    grid(0, 0) = cv::Vec4b(0, 0, 0, 255);
    grid(0, 1) = cv::Vec4b(255, 255, 255, 255);
    expect($(identity)).to.equalMat($(grid));
  });
  
  it(@"should be equal to [0-1] linear gradient with three points", ^{
    cv::Mat4b identity = [[LTColorGradient identityGradient] matWithSamplingPoints:3];
    cv::Mat4b grid(1, 3);
    grid = cv::Vec4b(255, 0, 0, 255);
    grid(0, 0) = cv::Vec4b(0, 0, 0, 255);
    grid(0, 1) = cv::Vec4b(128, 128, 128, 255);
    grid(0, 2) = cv::Vec4b(255, 255, 255, 255);
    expect($(identity)).to.equalMat($(grid));
  });
  
  it(@"should be equal to pre-computed red gradient", ^{
    LTColorGradient *gradient = [[LTColorGradient alloc] initWithControlPoints:redControlPoints];
    cv::Mat4b mat = [gradient matWithSamplingPoints:256];

    cv::Mat image = LTLoadMat([self class], @"RedGradient.png");
    expect($(mat)).to.beCloseToMat($(image));
  });
  
  it(@"should be equal to pre-computed red/blue gradient", ^{
    LTColorGradient *gradient = [[LTColorGradient alloc] initWithControlPoints:redBlueControlPoints];
    cv::Mat4b mat = [gradient matWithSamplingPoints:256];

    cv::Mat image = LTLoadMat([self class], @"RedBlueGradient.png");
    expect($(mat)).to.beCloseToMatWithin($(image), 3);
  });
  
  it(@"should be equal to semi-transparent grdient", ^{
    LTColorGradientControlPoint *transparentBlack = [[LTColorGradientControlPoint alloc]
        initWithPosition:0.0 colorWithAlpha:GLKVector4Make(0.0, 0.0, 0.0, 0.0)];
    LTColorGradientControlPoint *opaqueWhite = [[LTColorGradientControlPoint alloc]
        initWithPosition:1.0 colorWithAlpha:GLKVector4Make(1.0, 1.0, 1.0, 1.0)];
    
    NSArray *controlPoints = @[transparentBlack, opaqueWhite];
    
    LTColorGradient *gradient = [[LTColorGradient alloc] initWithControlPoints:controlPoints];
    cv::Mat4b mat = [gradient matWithSamplingPoints:256];
    
    cv::Mat image = LTLoadMat([self class], @"SemiTransparentBlack.png");
    expect($(mat)).to.beCloseToMatWithin($(image), 3);
  });
});

context(@"writing gradient values to texture", ^{
  beforeEach(^{
    [LTGLContext setCurrentContext:[[LTGLContext alloc] init]];
  });

  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });

  it(@"should produce texture that is equal to mat", ^{
    cv::Mat4b identityMat = [[LTColorGradient identityGradient] matWithSamplingPoints:256];
    LTTexture *identityTexture = [[LTColorGradient identityGradient] textureWithSamplingPoints:256];
    expect($(identityTexture.image)).to.equalMat($(identityMat));
  });
});

SpecEnd
