// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawer.h"

#import "LTCGExtensions.h"
#import "LTCommonDrawableShape.h"
#import "LTFbo.h"
#import "LTOpenCVExtensions.h"
#import "LTRotatedRect.h"
#import "LTShapeDrawerEllipticShape.h"
#import "LTShapeDrawerPathShape.h"
#import "LTShapeDrawerTriangularMeshShape.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

@interface LTShapeDrawer ()
@property (strong, nonatomic) NSMutableArray *mutableShapes;
@end

SpecBegin(LTShapeDrawer)

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
  
  // Make sure that everything is properly drawn when face culling is enabled.
  context.faceCullingEnabled = YES;
});

afterEach(^{
  [LTCommonDrawableShape clearPrograms];
  [LTGLContext setCurrentContext:nil];
});

__block LTShapeDrawer *drawer;

afterEach(^{
  drawer = nil;
});

context(@"initialization", ^{
  it(@"should initialize with default initializer", ^{
    expect(^{
      drawer = [[LTShapeDrawer alloc] init];
    }).notTo.raiseAny();
  });
});

context(@"properties", ^{
  beforeEach(^{
    drawer = [[LTShapeDrawer alloc] init];
  });
  
  it(@"should have default parameters", ^{
    expect(drawer.drawingParameters).to.equal([[LTShapeDrawerParams alloc] init]);
    expect(drawer.opacity).to.equal(1);
  });
  
  it(@"should update opacity", ^{
    CGFloat newValue = 0.5;
    expect(drawer.opacity).notTo.equal(newValue);
    drawer.opacity = newValue;
    expect(drawer.opacity).to.equal(newValue);
  });
  
  it(@"should return copy of shapes", ^{
    id shape = [drawer addPathWithTranslation:CGPointZero rotation:0];
    expect(drawer.shapes.count).to.equal(1);
    expect(drawer.shapes.firstObject).to.beIdenticalTo(shape);
    expect(drawer.shapes).notTo.beIdenticalTo(drawer.mutableShapes);
    expect(drawer.shapes).notTo.beInstanceOf([NSMutableArray class]);
  });
});

context(@"shapes", ^{
  beforeEach(^{
    drawer = [[LTShapeDrawer alloc] init];
  });

  const CGPoint kTranslation = CGPointMake(1, 2);
  const CGFloat kRotationAngle = M_PI_4;
  
  context(@"path shapes", ^{
    it(@"should add path", ^{
      id shape = [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      expect(shape).to.beKindOf([LTShapeDrawerPathShape class]);
      expect([shape translation]).to.equal(kTranslation);
      expect([shape rotationAngle]).to.equal(kRotationAngle);
      expect(drawer.shapes.count).to.equal(1);
      expect(drawer.shapes.firstObject).to.beIdenticalTo(shape);
    });
    
    it(@"should move to point in the last added path", ^{
      id firstMock = [OCMockObject mockForClass:[LTShapeDrawerPathShape class]];
      id secondMock = [OCMockObject mockForClass:[LTShapeDrawerPathShape class]];
      [drawer.mutableShapes addObject:firstMock];
      [drawer.mutableShapes addObject:secondMock];
      [[secondMock expect] moveToPoint:CGPointMake(1, 1)];
      [drawer moveToPoint:CGPointMake(1, 1)];
      OCMVerifyAll(secondMock);
    });
    
    it(@"should add line to point in the last added path", ^{
      id firstMock = [OCMockObject mockForClass:[LTShapeDrawerPathShape class]];
      id secondMock = [OCMockObject mockForClass:[LTShapeDrawerPathShape class]];
      [drawer.mutableShapes addObject:firstMock];
      [drawer.mutableShapes addObject:secondMock];
      [[secondMock expect] addLineToPoint:CGPointMake(1, 1)];
      [drawer addLineToPoint:CGPointMake(1, 1)];
      OCMVerifyAll(secondMock);
    });
  });
  
  context(@"triangular mesh shapes", ^{
    it(@"should add triangular mesh", ^{
      id shape = [drawer addTriangularMeshWithTranslation:kTranslation rotation:kRotationAngle];
      expect(shape).to.beKindOf([LTShapeDrawerTriangularMeshShape class]);
      expect([shape translation]).to.equal(kTranslation);
      expect([shape rotationAngle]).to.equal(kRotationAngle);
      expect(drawer.shapes.count).to.equal(1);
      expect(drawer.shapes.firstObject).to.beIdenticalTo(shape);
    });
    
    it(@"should fill triangle in the last added mesh", ^{
      id firstMock = [OCMockObject mockForClass:[LTShapeDrawerTriangularMeshShape class]];
      id secondMock = [OCMockObject mockForClass:[LTShapeDrawerTriangularMeshShape class]];
      [drawer.mutableShapes addObject:firstMock];
      [drawer.mutableShapes addObject:secondMock];
      CGTriangle triangle = CGTriangleMake(CGPointZero, CGPointZero, CGPointZero);
      [[secondMock expect] fillTriangle:triangle withShadowOnEdges:CGTriangleEdgeAll];
      [drawer fillTriangle:triangle withShadowOnEdges:CGTriangleEdgeAll];
      OCMVerifyAll(secondMock);
    });
  });
  
  context(@"elliptic shapes", ^{
    const CGSize kSize = CGSizeMake(1, 2);
    const CGFloat kRadius = 1;
    
    it(@"should add ellipse", ^{
      LTRotatedRect *rect =
          [LTRotatedRect rectWithCenter:kTranslation size:kSize angle:kRotationAngle];
      id shape = [drawer addEllipseInRotatedRect:rect];
      expect(shape).to.beKindOf([LTShapeDrawerEllipticShape class]);
      expect([shape translation]).to.equal(kTranslation);
      expect([shape rotationAngle]).to.equal(kRotationAngle);
      expect([(LTShapeDrawerEllipticShape *)shape size]).to.equal(kSize);
      expect([(LTShapeDrawerEllipticShape *)shape filled]).to.beFalsy();
      expect(drawer.shapes.count).to.equal(1);
      expect(drawer.shapes.firstObject).to.beIdenticalTo(shape);
    });
    
    it(@"should fill ellipse", ^{
      LTRotatedRect *rect =
          [LTRotatedRect rectWithCenter:kTranslation size:kSize angle:kRotationAngle];
      id shape = [drawer fillEllipseInRotatedRect:rect];
      expect(shape).to.beKindOf([LTShapeDrawerEllipticShape class]);
      expect([shape translation]).to.equal(kTranslation);
      expect([shape rotationAngle]).to.equal(kRotationAngle);
      expect([(LTShapeDrawerEllipticShape *)shape size]).to.equal(kSize);
      expect([(LTShapeDrawerEllipticShape *)shape filled]).to.beTruthy();
      expect(drawer.shapes.count).to.equal(1);
      expect(drawer.shapes.firstObject).to.beIdenticalTo(shape);
    });
    
    it(@"should add circle", ^{
      id shape = [drawer addCircleWithCenter:kTranslation radius:kRadius];
      expect(shape).to.beKindOf([LTShapeDrawerEllipticShape class]);
      expect([shape translation]).to.equal(kTranslation);
      expect([shape rotationAngle]).to.equal(0);
      expect([(LTShapeDrawerEllipticShape *)shape size]).to.equal(CGSizeMakeUniform(2 * kRadius));
      expect([(LTShapeDrawerEllipticShape *)shape filled]).to.beFalsy();
      expect(drawer.shapes.count).to.equal(1);
      expect(drawer.shapes.firstObject).to.beIdenticalTo(shape);
    });
    
    it(@"should fill circle", ^{
      id shape = [drawer fillCircleWithCenter:kTranslation radius:kRadius];
      expect(shape).to.beKindOf([LTShapeDrawerEllipticShape class]);
      expect([shape translation]).to.equal(kTranslation);
      expect([shape rotationAngle]).to.equal(0);
      expect([(LTShapeDrawerEllipticShape *)shape size]).to.equal(CGSizeMakeUniform(2 * kRadius));
      expect([(LTShapeDrawerEllipticShape *)shape filled]).to.beTruthy();
      expect(drawer.shapes.count).to.equal(1);
      expect(drawer.shapes.firstObject).to.beIdenticalTo(shape);
    });
  });
  
  context(@"updating shapes", ^{
    it(@"should remove all shapes", ^{
      [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      expect(drawer.shapes.count).to.equal(2);
      [drawer removeAllShapes];
      expect(drawer.shapes.count).to.equal(0);
    });
    
    it(@"should remove specific shape", ^{
      id firstShape = [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      id secondShape = [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      expect(drawer.shapes.count).to.equal(2);
      [drawer removeShape:firstShape];
      expect(drawer.shapes.count).to.equal(1);
      expect(drawer.shapes.firstObject).to.equal(secondShape);
      [drawer removeShape:secondShape];
      expect(drawer.shapes.count).to.equal(0);
    });

    it(@"should do nothing when trying to remove a shape not in the drawer queue", ^{
      id firstShape = [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      id secondShape = [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      expect(drawer.shapes.count).to.equal(2);
      [drawer removeShape:firstShape];
      expect(drawer.shapes.count).to.equal(1);
      expect(drawer.shapes.firstObject).to.equal(secondShape);
      [drawer removeShape:firstShape];
      expect(drawer.shapes.count).to.equal(1);
    });
    
    it(@"should add a shape", ^{
      id mock = [OCMockObject niceMockForProtocol:@protocol(LTDrawableShape)];
      [drawer addShape:mock];
      expect(drawer.shapes.count).to.equal(1);
      expect(drawer.shapes.firstObject).to.equal(mock);
    });
    
    it(@"should raise if trying to add non LTDrawableShape", ^{
      expect(^{
        [drawer addShape:[[NSObject alloc] init]];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should update translation of shape", ^{
      id firstShape = [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      id secondShape = [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      [drawer updateShape:firstShape setTranslation:CGPointZero];
      expect([firstShape translation]).to.equal(CGPointZero);
      expect([secondShape translation]).notTo.equal(CGPointZero);
      [drawer updateShape:secondShape setTranslation:CGPointZero];
      expect([secondShape translation]).to.equal(CGPointZero);
    });
    
    it(@"should update rotation of shape", ^{
      id firstShape = [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      id secondShape = [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      [drawer updateShape:firstShape setRotation:0];
      expect([firstShape rotationAngle]).to.equal(0);
      expect([secondShape rotationAngle]).notTo.equal(0);
      [drawer updateShape:secondShape setRotation:0];
      expect([secondShape rotationAngle]).to.equal(0);
    });
    
    it(@"should not update shape not in the queue", ^{
      id firstShape = [drawer addPathWithTranslation:kTranslation rotation:kRotationAngle];
      [drawer removeShape:firstShape];
      [drawer updateShape:firstShape setTranslation:CGPointZero];
      [drawer updateShape:firstShape setRotation:0];
      expect([firstShape translation]).to.equal(kTranslation);
      expect([firstShape rotationAngle]).to.equal(kRotationAngle);
    });
  });
});

context(@"drawing", ^{
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block cv::Mat4b expected;
  
  static const CGSize kOutputSize = CGSizeMake(128, 256);
  static const CGPoint kOutputCenter = CGPointZero + kOutputSize / 2;;
  static const LTVector4 kBackground = LTVector4(0.5, 0.5, 0.5, 1);

  beforeEach(^{
    // Prepare drawer.
    drawer = [[LTShapeDrawer alloc] init];
    
    // Prepare output framebuffer.
    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:kBackground];
  });
  
  afterEach(^{
    fbo = nil;
    output = nil;
  });
  
  context(@"call draw methods of shapes", ^{
    __block id firstMock;
    __block id secondMock;
    
    beforeEach(^{
      firstMock = [OCMockObject niceMockForProtocol:@protocol(LTDrawableShape)];
      secondMock = [OCMockObject niceMockForProtocol:@protocol(LTDrawableShape)];
      [drawer addShape:firstMock];
      [drawer addShape:secondMock];
      drawer.opacity = 0.5;
    });

    it(@"should draw to framebuffer", ^{
      [(id<LTDrawableShape>)[firstMock expect] setOpacity:drawer.opacity];
      [(id<LTDrawableShape>)[secondMock expect] setOpacity:drawer.opacity];
      [(id<LTDrawableShape>)[firstMock expect] drawInFramebufferWithSize:fbo.size];
      [(id<LTDrawableShape>)[secondMock expect] drawInFramebufferWithSize:fbo.size];
      [drawer drawInFramebuffer:fbo];
      OCMVerifyAll(firstMock);
      OCMVerifyAll(secondMock);
    });
    
    it(@"should draw to bound framebuffer", ^{
      [(id<LTDrawableShape>)[firstMock expect] setOpacity:drawer.opacity];
      [(id<LTDrawableShape>)[secondMock expect] setOpacity:drawer.opacity];
      [(id<LTDrawableShape>)[firstMock expect] drawInFramebufferWithSize:fbo.size];
      [(id<LTDrawableShape>)[secondMock expect] drawInFramebufferWithSize:fbo.size];
      [fbo bindAndDraw:^{
        [drawer drawInFramebufferWithSize:fbo.size];
      }];
      OCMVerifyAll(firstMock);
      OCMVerifyAll(secondMock);
    });
  });
  
  context(@"actual drawing", ^{
    static const NSUInteger kAcceptedDistance = 10;

    it(@"should draw an arrow and rotate it", ^{
      CGTriangle leftTriangle =
      CGTriangleMake(CGPointZero, CGPointZero + 2 * CGSizeMake(-10, 10),
                     CGPointZero + 2*CGSizeMake(0, -20));
      
      CGTriangle rightTriangle =
      CGTriangleMake(CGPointZero, CGPointZero + 2 * CGSizeMake(10, 10),
                     CGPointZero + 2*CGSizeMake(0, -20));
      
      drawer.drawingParameters.shadowWidth = 3;
      drawer.drawingParameters.lineWidth = 2;
      
      id path = [drawer addPathWithTranslation:kOutputCenter rotation:0];
      [drawer addLineToPoint:CGPointZero + CGSizeMake(0, 50)];
      id mesh = [drawer addTriangularMeshWithTranslation:kOutputCenter rotation:0];
      [drawer fillTriangle:leftTriangle withShadowOnEdges:CGTriangleEdgeAB | CGTriangleEdgeBC];
      [drawer fillTriangle:rightTriangle withShadowOnEdges:CGTriangleEdgeAB | CGTriangleEdgeBC];
      [drawer drawInFramebuffer:fbo];
      
      expected = LTLoadMat([self class], @"ShapeDrawerActualDrawingOriginal.png");
      expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
      
      [fbo clearWithColor:kBackground];
      [drawer updateShape:mesh setRotation:M_PI];
      [drawer updateShape:path setTranslation:kOutputCenter - CGSizeMake(0, 50)];
      [drawer drawInFramebuffer:fbo];
      
      expected = LTLoadMat([self class], @"ShapeDrawerActualDrawingUpdated.png");
      expect($(output.image)).to.beCloseToMatWithin($(expected), kAcceptedDistance);
    });
  });
});

SpecEnd
