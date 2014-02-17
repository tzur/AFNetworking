// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorGradient.h"

#import "LTTestUtils.h"
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
  
  it(@"should not initialize on position within the range", ^{
    expect(^{
      __unused LTColorGradientControlPoint *controlPoint = [[LTColorGradientControlPoint alloc]
          initWithPosition:0.5 color:GLKVector3Make(0.0, 0.0, 1.0)];
    }).toNot.raiseAny();
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

context(@"writing gradient values to texture", ^{
  __block LTColorGradient *gradient;
  __block LTTexture *texture;
  
  beforeEach(^{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:context];
  });
  
  afterEach(^{
    gradient = nil;
    texture = nil;
    
    [EAGLContext setCurrentContext:nil];
  });
  
  it(@"should be equal to [0-1] linear gradient with two points", ^{
    LTTexture *identity = [[LTColorGradient identityGradient] textureWithSamplingPoints:2];
    cv::Mat4b grid(1, 2);
    grid = cv::Vec4b(255, 0, 0, 255);
    grid(0, 0) = cv::Vec4b(0, 0, 0, 255);
    grid(0, 1) = cv::Vec4b(255, 255, 255, 255);
    expect(LTCompareMat(identity.image, grid)).to.beTruthy();
  });
  
  it(@"should be equal to [0-1] linear gradient with three points", ^{
    LTTexture *identity = [[LTColorGradient identityGradient] textureWithSamplingPoints:3];
    cv::Mat4b grid(1, 3);
    grid = cv::Vec4b(255, 0, 0, 255);
    grid(0, 0) = cv::Vec4b(0, 0, 0, 255);
    grid(0, 1) = cv::Vec4b(128, 128, 128, 255);
    grid(0, 2) = cv::Vec4b(255, 255, 255, 255);
    expect(LTCompareMat(identity.image, grid)).to.beTruthy();
  });
  
  it(@"should be equal to pre-computed red gradient", ^{
    gradient = [[LTColorGradient alloc] initWithControlPoints:redControlPoints];
    texture = [gradient textureWithSamplingPoints:256];

    cv::Mat image = LTLoadMatWithName([self class], @"RedGradient.png");
    expect(LTFuzzyCompareMat(texture.image, image)).to.beTruthy();
  });
  
  it(@"should be equal to pre-computed red/blue gradient", ^{
    gradient = [[LTColorGradient alloc] initWithControlPoints:redBlueControlPoints];
    texture = [gradient textureWithSamplingPoints:256];

    cv::Mat image = LTLoadMatWithName([self class], @"RedBlueGradient.png");
    expect(LTFuzzyCompareMat(texture.image, image, 3)).to.beTruthy();
  });
});

SpecEnd
