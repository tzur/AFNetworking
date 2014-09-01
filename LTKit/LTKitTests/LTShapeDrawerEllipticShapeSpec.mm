// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerEllipticShape.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTRotatedRect.h"
#import "LTShapeDrawerParams.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"
#import "UIColor+Vector.h"

SpecBegin(LTShapeDrawerEllipticShape)

__block LTShapeDrawerEllipticShape *shape;

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
  __block LTRotatedRect *rect;
  
  beforeEach(^{
    rect = [LTRotatedRect rect:CGRectMake(0, 0, 16, 16)];
  });
  
  it(@"should initialize without params", ^{
    shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rect filled:NO params:nil];
    expect(shape.params).to.equal([[LTShapeDrawerParams alloc] init]);
    expect(shape.filled).to.beFalsy();
  });
  
  it(@"should initialize with params", ^{
    LTShapeDrawerParams *params = [[LTShapeDrawerParams alloc] init];
    params.lineWidth += 1;
    shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rect filled:NO params:params];
    expect(shape.params).notTo.equal([[LTShapeDrawerParams alloc] init]);
    expect(shape.params).notTo.beIdenticalTo(params);
    expect(shape.params).to.equal(params);
    expect(shape.filled).to.beFalsy();
  });
  
  it(@"should initialize filled shape", ^{
    shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rect filled:YES params:nil];
    expect(shape.params).to.equal([[LTShapeDrawerParams alloc] init]);
    expect(shape.filled).to.beTruthy();
  });
  
  it(@"should not initialize without rotated rect", ^{
    expect(^{
      LTShapeDrawerParams *params = [[LTShapeDrawerParams alloc] init];
      shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:nil filled:NO params:params];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should set translation and rotation angle according to rect", ^{
    CGPoint center = CGPointMake(8, 8);
    CGFloat angle = M_PI_4;
    rect = [LTRotatedRect rectWithCenter:center size:CGSizeMake(16, 16) angle:angle];
    shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rect filled:NO params:nil];
    expect(shape.translation).to.equal(center);
    expect(shape.rotationAngle).to.equal(angle);
  });
});

context(@"properties", ^{
  beforeEach(^{
    LTRotatedRect *rect =
        [LTRotatedRect rectWithCenter:CGPointZero size:CGSizeMakeUniform(8) angle:0];
    shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rect filled:NO params:nil];
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
});

context(@"drawing", ^{
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block cv::Mat4b expected;
  __block LTShapeDrawerEllipticShape *shape;
  __block LTShapeDrawerParams *params;
  
  static const CGSize kOutputSize = CGSizeMake(64, 128);
  static const CGPoint kOutputCenter = CGPointZero + kOutputSize / 2;;
  static const LTVector4 kBackground = LTVector4(0.5, 0.5, 0.5, 1);
  
  /// A large difference is allowed since there might be a difference between the output on the
  /// simulator and on devices. There's no real good solution here, as sometimes there might be 2-3
  /// pixels with a noticable difference, and sometimes more pixels but the differences won't be
  /// noticable.
  static const NSUInteger kAcceptedDistance = 15;
  
  beforeEach(^{
    // Prepare output framebuffer.
    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:kBackground];

    // Prepare shape drawer params.
    params = [[LTShapeDrawerParams alloc] init];
    params.lineWidth = 8;
    params.shadowWidth = 8;
  });
  
  afterEach(^{
    fbo = nil;
    output = nil;
    shape = nil;
  });
  
  it(@"should draw a circle", ^{
    CGFloat diameter = std::min(kOutputSize / 2);
    LTRotatedRect *rect =
        [LTRotatedRect rectWithCenter:kOutputCenter size:CGSizeMakeUniform(diameter) angle:0];
    shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rect filled:NO params:params];
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:fbo.size];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerEllipticShapeCircle.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should draw an ellipse", ^{
    LTRotatedRect *rect = [LTRotatedRect rectWithCenter:kOutputCenter size:kOutputSize / 2 angle:0];
    shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rect filled:NO params:params];
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:fbo.size];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerEllipticShapeEllipse.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should draw a rotated ellipse", ^{
    LTRotatedRect *rect = [LTRotatedRect rectWithCenter:kOutputCenter size:kOutputSize / 2
                                                  angle:M_PI / 6];
    shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rect filled:NO params:params];
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:fbo.size];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerEllipticShapeRotatedEllipse.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should fill a rotated ellipse", ^{
    LTRotatedRect *rect = [LTRotatedRect rectWithCenter:kOutputCenter size:kOutputSize / 2
                                                  angle:M_PI / 6];
    shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rect filled:YES params:params];
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:fbo.size];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerEllipticShapeFilledEllipse.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should draw to screen framebuffer", ^{
    LTRotatedRect *rect = [LTRotatedRect rectWithCenter:kOutputCenter size:kOutputSize / 2
                                                  angle:M_PI / 6];
    shape = [[LTShapeDrawerEllipticShape alloc] initWithRotatedRect:rect filled:YES params:params];
    [fbo bindAndDrawOnScreen:^{
      [shape drawInFramebufferWithSize:fbo.size];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerEllipticShapeFilledEllipse.png");
    cv::flip(expected, expected, 0);
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
});

SpecEnd
