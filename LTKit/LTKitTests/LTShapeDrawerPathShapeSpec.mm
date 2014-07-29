// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerPathShape.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTRotatedRect.h"
#import "LTShapeDrawerParams.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"
#import "UIColor+Vector.h"

SpecBegin(LTShapeDrawerPathShape)

__block LTShapeDrawerPathShape *shape;

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
  context.faceCullingEnabled = YES;
});

afterEach(^{
  shape = nil;
  [LTGLContext setCurrentContext:nil];
  [LTCommonDrawableShape clearPrograms];
});

context(@"initialization", ^{
  it(@"should initialize without params", ^{
    shape = [[LTShapeDrawerPathShape alloc] initWithParams:nil];
    expect(shape.params).to.equal([[LTShapeDrawerParams alloc] init]);
    expect(shape.currentPoint).to.equal(CGPointZero);
    expect(shape.translation).to.equal(CGPointZero);
    expect(shape.rotationAngle).to.equal(0);
  });
  
  it(@"should initialize with params", ^{
    LTShapeDrawerParams *params = [[LTShapeDrawerParams alloc] init];
    params.lineWidth += 1;
    shape = [[LTShapeDrawerPathShape alloc] initWithParams:params];
    expect(shape.params).notTo.equal([[LTShapeDrawerParams alloc] init]);
    expect(shape.params).notTo.beIdenticalTo(params);
    expect(shape.params).to.equal(params);
    expect(shape.currentPoint).to.equal(CGPointZero);
    expect(shape.translation).to.equal(CGPointZero);
    expect(shape.rotationAngle).to.equal(0);
  });
});

context(@"properties", ^{
  beforeEach(^{
    shape = [[LTShapeDrawerPathShape alloc] initWithParams:nil];
  });
  
  it(@"should set opacity", ^{
    CGFloat newValue = 0.5;
    expect(shape.opacity).notTo.equal(newValue);
    shape.opacity = newValue;
    expect(shape.opacity).to.equal(newValue);
  });
  
  it(@"should set translation", ^{
    CGPoint newValue = CGPointMake(-4, 8);;
    expect(shape.translation).notTo.equal(newValue);
    shape.translation = newValue;
    expect(shape.translation).to.equal(newValue);
  });
  
  it(@"should set rotationAngle", ^{
    CGFloat newValue = M_PI_4;
    expect(shape.rotationAngle).notTo.equal(newValue);
    shape.rotationAngle = newValue;
    expect(shape.rotationAngle).to.equal(newValue);
  });
  
  it(@"should update current point according to drawing", ^{
    [shape addLineToPoint:CGPointMake(1, 1)];
    expect(shape.currentPoint).to.equal(CGPointMake(1, 1));
    [shape moveToPoint:CGPointMake(2, 2)];
    expect(shape.currentPoint).to.equal(CGPointMake(2, 2));
    [shape addLineToPoint:CGPointMake(3, 3)];
    expect(shape.currentPoint).to.equal(CGPointMake(3, 3));
    [shape closePath];
    expect(shape.currentPoint).to.equal(CGPointMake(2, 2));
  });
});

context(@"drawing", ^{
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block cv::Mat4b expected;
  __block LTShapeDrawerPathShape *shape;
  __block LTShapeDrawerParams *params;
  
  static const CGSize kOutputSize = CGSizeMake(64, 128);
  static const CGPoint kOutputCenter = CGPointZero + kOutputSize / 2;;
  static const GLKVector4 kBackground = GLKVector4Make(0.5, 0.5, 0.5, 1);
  
  /// A large difference is allowed since there might be a difference between the output on the
  /// simulator and on devices. There's no real good solution here, as sometimes there might be 2-3
  /// pixels with a noticable difference, and sometimes more pixels but the differences won't be
  /// noticable.
  static const NSUInteger kAcceptedDistance = 10;
  
  beforeEach(^{
    // Prepare output framebuffer.
    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:kBackground];
    
    // Prepare shape drawer params.
    params = [[LTShapeDrawerParams alloc] init];
    params.lineWidth = 8;
    params.shadowWidth = 8;
    shape = [[LTShapeDrawerPathShape alloc] initWithParams:params];
  });
  
  afterEach(^{
    fbo = nil;
    output = nil;
    shape = nil;
  });
  
  it(@"should draw a line from the initial point", ^{
    [shape addLineToPoint:kOutputCenter];
    
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerPathShapeLineFromOrigin.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should move to a point and draw a line from there", ^{
    [shape moveToPoint:kOutputCenter];
    [shape addLineToPoint:kOutputCenter + CGSizeMake(kOutputSize.width / 2, 0)];

    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerPathShapeLineFromCenter.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });

  it(@"should close a subpath", ^{
    [shape moveToPoint:kOutputCenter / 2];
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(kOutputSize.width / 2, 0)];
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(0, kOutputSize.height / 2)];
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(-kOutputSize.width / 2, 0)];
    [shape closePath];
    
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerPathShapeCloseSubpath.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should draw to seperate subpaths", ^{
    [shape moveToPoint:CGPointMake(kOutputSize.width / 4, 0)];
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(kOutputSize.width / 2, 0)];
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(0, kOutputSize.height / 4)];
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(-kOutputSize.width / 2, 0)];
    [shape closePath];
    
    [shape moveToPoint:CGPointMake(kOutputSize.width / 4, kOutputSize.height)];
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(kOutputSize.width / 2, 0)];
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(0, -kOutputSize.height / 4)];
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(-kOutputSize.width / 2, 0)];
    [shape closePath];
    
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerPathShapeTwoSubpaths.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should draw path with translation", ^{
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(kOutputSize.width / 2, 0)];
    shape.translation = kOutputCenter;
    
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerPathShapeTranslation.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should draw a path with rotation", ^{
    [shape addLineToPoint:shape.currentPoint + CGSizeMake(kOutputSize.width / 2, 0)];
    shape.rotationAngle = M_PI / 6;
    
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerPathShapeRotation.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
});

SpecEnd
