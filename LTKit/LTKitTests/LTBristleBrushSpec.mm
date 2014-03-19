// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBristleBrush.h"

#import "LTBrushEffectExamples.h"
#import "LTBrushSpec.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTPainterPoint.h"
#import "LTTexture+Factory.h"

@interface LTBrush ()
@property (readonly, nonatomic) LTTexture *texture;
@end

SpecBegin(LTBristleBrush)

itShouldBehaveLike(kLTBrushExamples, @{kLTBrushClass: [LTBristleBrush class]});

itShouldBehaveLike(kLTBrushEffectExamples, @{kLTBrushClass: [LTBristleBrush class]});

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

__block LTBristleBrush *brush;

beforeEach(^{
  brush = [[LTBristleBrush alloc] init];
});

afterEach(^{
  brush = nil;
});

context(@"properties", ^{
  const CGFloat kEpsilon = 1e-6;

  it(@"should have default properties", ^{
    expect(brush.shape).to.equal(LTBristleBrushShapeRound);
    expect(brush.bristles).to.equal(10);
    expect(brush.thickness).to.equal(0.1);
    expect(brush.spacing).to.equal(0.01);
  });
  
  it(@"should set bristles", ^{
    NSUInteger newValue = 10;
    brush.bristles = newValue;
    expect(brush.bristles).to.equal(newValue);
    
    expect(^{
      brush.bristles = brush.minBristles - 1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      brush.bristles = brush.maxBristles + 1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should set thickness", ^{
    const CGFloat newValue = 0.5;
    expect(brush.thickness).notTo.equal(newValue);
    brush.thickness = newValue;
    expect(brush.thickness).to.equal(newValue);
    
    expect(^{
      brush.thickness = brush.minThickness - kEpsilon;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      brush.thickness = brush.maxThickness + kEpsilon;
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"drawing", ^{
  __block cv::Mat4b expected;
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block LTPainterPoint *point;
  
  const GLKVector4 kBackground = GLKVector4Make(0, 0, 0, 1);
  const CGFloat kBaseBrushDiameter = 64;
  const CGFloat kTargetBrushDiameter = 64;
  const CGSize kBaseBrushSize = CGSizeMakeUniform(kBaseBrushDiameter);
  const CGSize kOutputSize = kBaseBrushSize;
  const CGPoint kOutputCenter = CGPointMake(kOutputSize.width / 2, kOutputSize.height / 2);
  
  beforeEach(^{
    brush.baseDiameter = kBaseBrushDiameter;
    brush.scale = kTargetBrushDiameter / kBaseBrushDiameter;
    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:kBackground];
    
    expected.create(kOutputSize.height, kOutputSize.width);
    expected = LTGLKVector4ToVec4b(kBackground);
    
    point = [[LTPainterPoint alloc] init];
    point.zoomScale = 1;
    point.contentPosition = kOutputCenter;
  });
  
  afterEach(^{
    fbo = nil;
    output = nil;
    brush = nil;
  });
  
  it(@"should update the brush texture according to the bristles property", ^{
    brush.thickness = 2.0;
    
    brush.bristles = 2;
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expected = LTLoadMat([self class], @"BristleBrushBristles.2.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), 6);
    
    brush.bristles = 4;
    [fbo clearWithColor:kBackground];
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expected = LTLoadMat([self class], @"BristleBrushBristles.4.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), 6);
    
    brush.bristles = 20;
    [fbo clearWithColor:kBackground];
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expected = LTLoadMat([self class], @"BristleBrushBristles.20.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), 6);
  });
  
  it(@"should update the brush texture according to the thickness property", ^{
    brush.bristles = 2;
    
    brush.thickness = 1.5;
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expected = LTLoadMat([self class], @"BristleBrushThickness.1.5.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), 6);
    
    brush.thickness = 0.75;
    [fbo clearWithColor:kBackground];
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expected = LTLoadMat([self class], @"BristleBrushThickness.0.75.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), 6);
    
    brush.thickness = 0.1;
    [fbo clearWithColor:kBackground];
    [brush startNewStrokeAtPoint:point];
    [brush drawPoint:point inFramebuffer:fbo];
    expected = LTLoadMat([self class], @"BristleBrushThickness.0.1.png");
    expect($(output.image)).to.beCloseToMatWithin($(expected), 6);
  });
});

SpecEnd
