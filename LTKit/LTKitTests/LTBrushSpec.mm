// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushEffectExamples.h"
#import "LTBrushSpec.h"

#import "LTCGExtensions.h"
#import "LTDevice.h"
#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTLinearInterpolationRoutine.h"
#import "LTPainterPoint.h"
#import "LTPainterStrokeSegment.h"
#import "LTRandom.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

NSString * const kLTBrushExamples = @"LTBrushExamples";
NSString * const kLTBrushClass = @"LTBrushClass";

@interface LTBrush ()
@property (strong, nonatomic) LTTexture *texture;
@end

SharedExamplesBegin(LTBrushExamples)

sharedExamplesFor(kLTBrushExamples, ^(NSDictionary *data) {
  __block Class brushClass;
  
  beforeEach(^{
    brushClass = data[kLTBrushClass];
    LTGLContext *context = [[LTGLContext alloc] init];
    [LTGLContext setCurrentContext:context];
  });
  
  afterEach(^{
    [LTGLContext setCurrentContext:nil];
  });
  
  context(@"initialization", ^{
    it(@"should initailize with default initializer", ^{
      LTBrush *brush = [[brushClass alloc] init];
      expect(brush.random).notTo.beNil();
    });
    
    it(@"should initialize with a given random generator", ^{
      LTRandom *random = [[LTRandom alloc] init];
      LTBrush *brush = [[brushClass alloc] initWithRandom:random];
      expect(brush.random).to.beIdenticalTo(random);
    });
  });
  
  context(@"properties", ^{
    const CGFloat kEpsilon = 1e-6;
    __block LTBrush *brush;
    
    beforeEach(^{
      brush = [[brushClass alloc] init];
    });
    
    afterEach(^{
      brush = nil;
    });
    
    it(@"should set baseDiameter", ^{
      const NSUInteger newValue = 100;
      expect(brush.baseDiameter).notTo.equal(newValue);
      brush.baseDiameter = newValue;
      expect(brush.baseDiameter).to.equal(newValue);
    });
    
    it(@"should set scale", ^{
      const CGFloat newValue = 0.5;
      expect(brush.scale).notTo.equal(newValue);
      brush.scale = newValue;
      expect(brush.scale).to.equal(newValue);
      
      expect(^{
        brush.scale = brush.minScale - kEpsilon;
      }).to.raise(NSInvalidArgumentException);
      expect(^{
        brush.scale = brush.maxScale + kEpsilon;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should set angle, with cyclic wrapping", ^{
      const CGFloat newValue = 0.5;
      expect(brush.angle).notTo.equal(newValue);
      brush.angle = newValue;
      expect(brush.angle).to.equal(newValue);
      
      expect(brush.minAngle).to.equal(0);
      expect(brush.maxAngle).to.equal(2 * M_PI);
      brush.angle = brush.minAngle - kEpsilon;
      expect(brush.angle).to.beCloseToWithin(2 * M_PI - kEpsilon, 1e-4);
      brush.angle = brush.maxAngle + kEpsilon;
      expect(brush.angle).to.beCloseToWithin(kEpsilon, 1e-4);
    });
    
    it(@"should set spacing", ^{
      const CGFloat newValue = 0.5;
      expect(brush.spacing).notTo.equal(newValue);
      brush.spacing = newValue;
      expect(brush.spacing).to.equal(newValue);
      
      expect(^{
        brush.spacing = brush.minSpacing - kEpsilon;
      }).to.raise(NSInvalidArgumentException);
      expect(^{
        brush.spacing = brush.maxSpacing + kEpsilon;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should set opacity", ^{
      const CGFloat newValue = 0.5;
      expect(brush.opacity).notTo.equal(newValue);
      brush.opacity = newValue;
      expect(brush.opacity).to.equal(newValue);
      
      expect(^{
        brush.opacity = brush.minOpacity - kEpsilon;
      }).to.raise(NSInvalidArgumentException);
      expect(^{
        brush.opacity = brush.maxOpacity + kEpsilon;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should set flow", ^{
      const CGFloat newValue = 0.5;
      expect(brush.flow).notTo.equal(newValue);
      brush.flow = newValue;
      expect(brush.flow).to.equal(newValue);
      
      expect(^{
        brush.flow = brush.minFlow - kEpsilon;
      }).to.raise(NSInvalidArgumentException);
      expect(^{
        brush.flow = brush.maxFlow + kEpsilon;
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should set intensity", ^{
      const LTVector4 newValue = LTVector4(0.3, 0.4, 0.5, 0.6);
      expect(brush.intensity).notTo.equal(newValue);
      brush.intensity = newValue;
      expect(brush.intensity).to.equal(newValue);
      
      for (NSUInteger i = 0; i < 4; ++i) {
        LTVector4 newValue = brush.minIntensity;
        newValue.data()[i] -= kEpsilon;
        expect(^{
          brush.intensity = newValue;
        }).to.raise(NSInvalidArgumentException);
        newValue = brush.maxIntensity;
        newValue.data()[i] += kEpsilon;
        expect(^{
          brush.intensity = newValue;
        }).to.raise(NSInvalidArgumentException);
      }
    });

    it(@"should set randomAnglePerStroke", ^{
      brush.randomAnglePerStroke = YES;
      expect(brush.randomAnglePerStroke).to.beTruthy();
      brush.randomAnglePerStroke = NO;
      expect(brush.randomAnglePerStroke).to.beFalsy();
    });
  });
});

SharedExamplesEnd

LTSpecBegin(LTBrush)

itShouldBehaveLike(kLTBrushExamples, @{kLTBrushClass: [LTBrush class]});

itShouldBehaveLike(kLTBrushEffectLTBrushExamples, @{kLTBrushClass: [LTBrush class]});

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

context(@"properties", ^{
  __block LTBrush *brush;
  
  beforeEach(^{
    brush = [[LTBrush alloc] init];
  });
  
  afterEach(^{
    brush = nil;
  });
  
  it(@"should have default properties", ^{
    expect(brush.baseDiameter).to.equal([LTDevice currentDevice].fingerSizeOnDevice *
                                        [LTDevice currentDevice].glkContentScaleFactor);
    expect(brush.scale).to.equal(1);
    expect(brush.angle).to.equal(0);
    expect(brush.spacing).to.equal(0.05);
    expect(brush.opacity).to.equal(1);
    expect(brush.flow).to.equal(1);
    expect(brush.intensity).to.equal(LTVector4(1, 1, 1, 1));
    cv::Mat1b expected(1, 1, 255);
    expect($(brush.texture.image)).to.equalMat($(expected));
    expect(brush.randomAnglePerStroke).to.beFalsy();
  });
});

context(@"drawing", ^{
  __block cv::Mat4b expected;
  __block LTBrush *brush;
  __block LTTexture *output;
  __block LTFbo *fbo;
  __block LTPainterPoint *startPoint;
  __block LTPainterPoint *endPoint;
  __block LTPainterPoint *centerPoint;
  __block LTLinearInterpolationRoutine *spline;
  __block LTPainterStrokeSegment *segment;

  const CGFloat kBaseBrushDiameter = 100;
  const CGFloat kTargetBrushDiameter = 10;
  const CGSize kBaseBrushSize = CGSizeMakeUniform(kBaseBrushDiameter);
  const CGSize kOutputSize = 2 * kBaseBrushSize;
  const CGPoint kOutputCenter = CGPointMake(kOutputSize.width / 2, kOutputSize.height / 2);
  
  beforeEach(^{
    brush = [[LTBrush alloc] init];
    brush.baseDiameter = kBaseBrushDiameter;
    brush.scale = kTargetBrushDiameter / kBaseBrushDiameter;
    brush.spacing = 0.5;
    output = [LTTexture byteRGBATextureWithSize:kOutputSize];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
    
    expected.create(kOutputSize.height, kOutputSize.width);
    expected = cv::Vec4b(0, 0, 0, 255);
    
    startPoint = [[LTPainterPoint alloc] init];
    endPoint = [[LTPainterPoint alloc] init];
    startPoint.zoomScale = 1;
    endPoint.zoomScale = 1;
    startPoint.contentPosition = CGPointMake(0, kOutputCenter.y);
    endPoint.contentPosition = CGPointMake(kOutputSize.width, kOutputCenter.y);
    spline = [[LTLinearInterpolationRoutine alloc] initWithKeyFrames:@[startPoint, endPoint]];
    segment = [[LTPainterStrokeSegment alloc] initWithSegmentIndex:0 zoomScale:1 distanceFromStart:0
                                           andInterpolationRoutine:spline];
    centerPoint = [spline valueAtKey:0.5];
  });
  
  afterEach(^{
    fbo = nil;
    output = nil;
    brush = nil;
  });
  
  it(@"should draw a point", ^{
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(255, 255, 255, 255));
    expect($(output.image)).to.equalMat($(expected));
  });
  
  it(@"should draw a segment with no previous point", ^{
    [brush drawStrokeSegment:segment fromPreviousPoint:nil
               inFramebuffer:fbo saveLastDrawnPointTo:nil];
    CGRect targetRect =
        CGRectCenteredAt(kOutputCenter, CGSizeMake(kOutputSize.width,
                                                   kBaseBrushDiameter * brush.scale));
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(255, 255, 255, 255));
    expect($(output.image)).to.equalMat($(expected));
  });
  
  it(@"should draw a segment with respect to previous point", ^{
    LTPainterPoint *centerPoint = [spline valueAtKey:0.5];
    centerPoint.distanceFromStart = kOutputSize.width / 2;
    [brush drawStrokeSegment:segment fromPreviousPoint:centerPoint
               inFramebuffer:fbo saveLastDrawnPointTo:nil];
    CGRect targetRect = CGRectFromEdges(kOutputCenter.x, kOutputCenter.y - 5,
                                        kOutputSize.width, kOutputCenter.y + 5);
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(255, 255, 255, 255));
    expect($(output.image)).to.equalMat($(expected));
  });
  
  it(@"should draw a segment and store the last drawn point as output argument", ^{
    LTPainterPoint *lastDrawnPoint;
    [brush drawStrokeSegment:segment fromPreviousPoint:nil
               inFramebuffer:fbo saveLastDrawnPointTo:&lastDrawnPoint];
    expect(lastDrawnPoint.contentPosition.y).to.equal(kOutputCenter.y);
    expect(lastDrawnPoint.contentPosition.x).to.beCloseToWithin(kOutputSize.width,
                                                                kTargetBrushDiameter);
  });
  
  it(@"should draw with replaced texture", ^{
    const CGSize kSize = CGSizeMakeUniform(kTargetBrushDiameter);
    const CGSize kHalf = kSize / 2;
    cv::Mat1b newTexture(kSize.height, kSize.width);
    newTexture(cv::Rect(0, 0, kHalf.width, kHalf.height)) = 25;
    newTexture(cv::Rect(kHalf.width, 0, kHalf.width, kHalf.height)) = 50;
    newTexture(cv::Rect(0, kHalf.height, kHalf.width, kHalf.height)) = 100;
    newTexture(cv::Rect(kHalf.width, kHalf.height, kHalf.width, kHalf.height)) = 200;
    brush.texture = [LTTexture textureWithImage:newTexture];
    brush.texture.minFilterInterpolation = LTTextureInterpolationNearest;
    brush.texture.magFilterInterpolation = LTTextureInterpolationNearest;
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
    cv::Mat1b expectedSingle(expected.rows, expected.cols, (uchar)0);
    newTexture.copyTo(expectedSingle(LTCVRectWithCGRect(targetRect)));
    cv::cvtColor(expectedSingle, expected, CV_GRAY2RGBA);
    expect($(output.image)).to.equalMat($(expected));
  });
  
  it(@"drawing should be additive", ^{
    [fbo clearWithColor:LTVector4(0, 0, 0, 0)];
    [brush.texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(3);
    }];
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
    expected.setTo(0);
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(3, 3, 3, 3));
    expect($(output.image)).to.beCloseToMat($(expected));
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(6, 6, 6, 6));
    expect($(output.image)).to.equalMat($(expected));
  });
  
  it(@"should draw with updated scale", ^{
    brush.scale *= 2;
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(255, 255, 255, 255));
    expect($(output.image)).to.equalMat($(expected));
  });
  
  it(@"should draw with updated angle", ^{
    brush.angle = M_PI_4;
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(255, 255, 255, 255));
    expected = LTRotateMat(expected, brush.angle);
    expect($(output.image)).to.equalMat($(expected));
  });
  
  it(@"should draw with updated spacing", ^{
    brush.spacing = 2;
    [brush drawStrokeSegment:segment fromPreviousPoint:nil
               inFramebuffer:fbo saveLastDrawnPointTo:nil];
    
    for (int center = 0; center < expected.cols; center += 2 * kTargetBrushDiameter) {
      
      CGRect targetRect = CGRectCenteredAt(CGPointMake(center, kOutputCenter.y),
                                           CGSizeMakeUniform(kTargetBrushDiameter));
      targetRect = CGRectIntersection(targetRect, CGRectFromSize(kOutputSize));
      expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(255, 255, 255, 255));
    }
    expect($(output.image)).to.equalMat($(expected));
  });
  
  it(@"should draw with updated opacity", ^{
    [brush.texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      mapped->setTo(100);
    }];
    brush.opacity = 0.5;
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(100, 100, 100, 255));
    expect($(output.image)).to.beCloseToMat($(expected));
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(127, 127, 127, 255));
    expect($(output.image)).to.beCloseToMat($(expected));
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should draw with updated flow", ^{
    brush.flow = 0.25;
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(63, 63, 63, 255));
    expect($(output.image)).to.beCloseToMat($(expected));
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(127, 127, 127, 255));
    expect($(output.image)).to.beCloseToMat($(expected));
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(191, 191, 191, 255));
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should draw with updated intensity", ^{
    [fbo clearWithColor:LTVector4(0, 0, 0, 0)];
    const LTVector4 kIntensity = LTVector4(0.1, 0.2, 0.3, 0.4);
    brush.intensity = kIntensity;
    [brush drawPoint:centerPoint inFramebuffer:fbo];
    CGRect targetRect = CGRectCenteredAt(kOutputCenter, kBaseBrushSize * brush.scale);
    expected.setTo(0);
    expected(LTCVRectWithCGRect(targetRect)).setTo(cv::Vec4b(0.1 * 255, 0.2 * 255,
                                                             0.3 * 255, 0.4 * 255));
    expect($(output.image)).to.beCloseToMat($(expected));
  });

  it(@"should use random angles per stroke", ^{
    brush.randomAnglePerStroke = YES;
    CGFloat previousAngle = 0;
    expect(brush.angle).to.equal(previousAngle);
    previousAngle = brush.angle;
    [brush startNewStrokeAtPoint:centerPoint];
    expect(brush.angle).notTo.equal(previousAngle);
    previousAngle = brush.angle;
    [brush startNewStrokeAtPoint:centerPoint];
    expect(brush.angle).notTo.equal(previousAngle);
  });
});

LTSpecEnd
