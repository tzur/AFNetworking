// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerTriangularMeshShape.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTRotatedRect.h"
#import "LTShapeDrawerParams.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"
#import "UIColor+Vector.h"

SpecBegin(LTShapeDrawerTriangularMeshShape)

__block LTShapeDrawerTriangularMeshShape *shape;

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
    shape = [[LTShapeDrawerTriangularMeshShape alloc] initWithParams:nil];
    expect(shape.params).to.equal([[LTShapeDrawerParams alloc] init]);
    expect(shape.translation).to.equal(CGPointZero);
    expect(shape.rotationAngle).to.equal(0);
  });
  
  it(@"should initialize with params", ^{
    LTShapeDrawerParams *params = [[LTShapeDrawerParams alloc] init];
    params.lineWidth += 1;
    shape = [[LTShapeDrawerTriangularMeshShape alloc] initWithParams:params];
    expect(shape.params).notTo.equal([[LTShapeDrawerParams alloc] init]);
    expect(shape.params).notTo.beIdenticalTo(params);
    expect(shape.params).to.equal(params);
    expect(shape.translation).to.equal(CGPointZero);
    expect(shape.rotationAngle).to.equal(0);
  });
});

context(@"properties", ^{
  beforeEach(^{
    shape = [[LTShapeDrawerTriangularMeshShape alloc] initWithParams:nil];
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
  __block LTShapeDrawerTriangularMeshShape *shape;
  __block LTShapeDrawerParams *params;
  __block CGTriangle triangle;
  __block CGTriangle arrowLeftHalf;
  __block CGTriangle arrowRightHalf;
  
  static const CGSize kOutputSize = CGSizeMake(64, 128);
  static const CGPoint kOutputCenter = CGPointZero + kOutputSize / 2;;
  static const GLKVector4 kBackground = GLKVector4Make(0.5, 0.5, 0.5, 1);
  
  /// A large difference is allowed since there might be a difference between the output on the
  /// simulator and on devices. There's no real good solution here, as sometimes there might be 2-3
  /// pixels with a noticable difference, and sometimes more pixels but the differences won't be
  /// noticable.
  static const NSUInteger kAcceptedDistance = 5;

  beforeEach(^{
    // Prepare output framebuffer.
    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:kBackground];
    
    // Prepare shape drawer params.
    params = [[LTShapeDrawerParams alloc] init];
    params.lineWidth = 8;
    params.shadowWidth = 8;
    shape = [[LTShapeDrawerTriangularMeshShape alloc] initWithParams:params];
    
    // Prepare common triangles.
    CGSize size = kOutputSize / 4;
    triangle = CGTriangleMake(kOutputCenter,
                              kOutputCenter + CGSizeMake(-size.width, -size.height),
                              kOutputCenter + CGSizeMake(size.width, -size.height));
    
    arrowLeftHalf = CGTriangleMake(CGPointZero, CGPointZero + CGSizeMake(0, -30),
                                   CGPointZero + CGSizeMake(-15, 15));
    arrowRightHalf = CGTriangleMake(CGPointZero, CGPointZero + CGSizeMake(0, -30),
                                    CGPointZero + CGSizeMake(15, 15));
  });
  
  afterEach(^{
    fbo = nil;
    output = nil;
    shape = nil;
  });
  
  it(@"should fill a triangle", ^{
    [shape fillTriangle:triangle withShadowOnEdges:CGTriangleEdgeAll];
    
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerTriangularMeshShapeTriangle.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should fill a triangle with shadows according to edge mask", ^{
    [shape fillTriangle:triangle withShadowOnEdges:CGTriangleEdgeBC];
    
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerTriangularMeshShapeTriangleWithShadowMask.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });

  it(@"should fill multiple triangles", ^{
    arrowLeftHalf.a = arrowLeftHalf.a + kOutputSize / 2;
    arrowLeftHalf.b = arrowLeftHalf.b + kOutputSize / 2;
    arrowLeftHalf.c = arrowLeftHalf.c + kOutputSize / 2;
    arrowRightHalf.a = arrowRightHalf.a + kOutputSize / 2;
    arrowRightHalf.b = arrowRightHalf.b + kOutputSize / 2;
    arrowRightHalf.c = arrowRightHalf.c + kOutputSize / 2;
    [shape fillTriangle:arrowLeftHalf withShadowOnEdges:CGTriangleEdgeBC | CGTriangleEdgeCA];
    [shape fillTriangle:arrowRightHalf withShadowOnEdges:CGTriangleEdgeBC | CGTriangleEdgeCA];
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerTriangularMeshShapeMultipleTriangles.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should draw a triangle with translation", ^{
    [shape fillTriangle:arrowLeftHalf withShadowOnEdges:CGTriangleEdgeBC | CGTriangleEdgeCA];
    [shape fillTriangle:arrowRightHalf withShadowOnEdges:CGTriangleEdgeBC | CGTriangleEdgeCA];
    shape.translation = kOutputCenter;
    
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerTriangularMeshShapeTranslation.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should draw a triangle with rotation", ^{
    [shape fillTriangle:arrowLeftHalf withShadowOnEdges:CGTriangleEdgeNone];
    [shape fillTriangle:arrowRightHalf withShadowOnEdges:CGTriangleEdgeNone];
    shape.rotationAngle = M_PI / 4;
    shape.translation = kOutputCenter;
    
    [fbo bindAndDraw:^{
      [shape drawInFramebufferWithSize:kOutputSize];
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerTriangularMeshShapeRotation.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
  
  it(@"should draw to screen framebuffer", ^{
    [shape fillTriangle:arrowLeftHalf withShadowOnEdges:CGTriangleEdgeNone];
    [shape fillTriangle:arrowRightHalf withShadowOnEdges:CGTriangleEdgeNone];
    shape.rotationAngle = M_PI / 4;
    shape.translation = kOutputCenter;
    
    [fbo bindAndDraw:^{
      [LTGLContext currentContext].renderingToScreen = YES;
      [shape drawInFramebufferWithSize:fbo.size];
      [LTGLContext currentContext].renderingToScreen = NO;
    }];
    expected = LTLoadMat([self class], @"ShapeDrawerTriangularMeshShapeRotation.png");
    cv::flip(expected, expected, 0);
    expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
  });
});

SpecEnd
