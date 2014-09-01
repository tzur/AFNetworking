// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainter+LTView.h"

#import "LTBrush.h"
#import "LTCGExtensions.h"
#import "LTCatmullRomInterpolationRoutine.h"
#import "LTLinearInterpolationRoutine.h"
#import "LTPainterPoint.h"
#import "LTPainterStroke.h"
#import "LTRotatedRect.h"
#import "LTRoundBrush.h"
#import "LTTexture+Factory.h"
#import "LTTouchCollector.h"

static LTPainterPoint *LTPointAt(CGPoint position) {
  LTPainterPoint *point = [[LTPainterPoint alloc] init];
  point.zoomScale = 1.0;
  point.contentPosition = position;
  return point;
}

static LTPainterPoint *LTPointAt(CGSize position) {
  return LTPointAt(CGPointMake(position.width, position.height));
}

@interface LTPainter () <LTTouchCollectorDelegate>
@end

LTSpecBegin(LTPainter)

const CGSize kCanvasSize = CGSizeMake(64, 64);

__block LTPainter *painter;
__block LTTexture *canvas;

context(@"initialization", ^{
  it(@"should initialize with sandboxed stroke mode", ^{
    canvas = [LTTexture byteRGBATextureWithSize:kCanvasSize];
    painter = [[LTPainter alloc] initWithMode:LTPainterTargetModeSandboxedStroke
                                canvasTexture:canvas];
    expect(painter.mode).to.equal(LTPainterTargetModeSandboxedStroke);
    expect(painter.strokeTexture.size).to.equal(canvas.size);
  });
  
  it(@"should initialize with direct stroke mode", ^{
    canvas = [LTTexture byteRGBATextureWithSize:kCanvasSize];
    painter = [[LTPainter alloc] initWithMode:LTPainterTargetModeDirectStroke canvasTexture:canvas];
    expect(painter.mode).to.equal(LTPainterTargetModeDirectStroke);
    expect(painter.strokeTexture.size).to.equal(CGSizeMakeUniform(1));
  });
  
  it(@"should raise when initializing without a canvas", ^{
    expect(^{
      painter = [[LTPainter alloc] initWithMode:LTPainterTargetModeDirectStroke canvasTexture:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"properties", ^{
  beforeEach(^{
    canvas = [LTTexture byteRGBATextureWithSize:kCanvasSize];
    painter = [[LTPainter alloc] initWithMode:LTPainterTargetModeSandboxedStroke
                                canvasTexture:canvas];
  });
  
  afterEach(^{
    painter = nil;
    canvas = nil;
  });
  
  it(@"should have default properties", ^{
    expect(painter.delegate).to.beNil();
    expect(painter.touchDelegateForLTView).to.conformTo(@protocol(LTViewTouchDelegate));
    expect(painter.brush).to.beKindOf([LTBrush class]);
    expect(painter.splineFactory).to.beKindOf([LTCatmullRomInterpolationRoutineFactory class]);
    expect(painter.airbrush).to.beFalsy();
    expect(painter.strokes).notTo.beNil();
    expect(painter.strokes.count).to.equal(0);
  });
  
  it(@"should set delegate", ^{
    id delegate = [[NSObject alloc] init];
    painter.delegate = delegate;
    expect(painter.delegate).to.beIdenticalTo(delegate);
  });
  
  it(@"should set brush", ^{
    LTRoundBrush *brush = [[LTRoundBrush alloc] init];
    painter.brush = brush;
    expect(painter.brush).to.beIdenticalTo(brush);
  });
  
  it(@"should set splineFactory", ^{
    id<LTInterpolationRoutineFactory> factory =
        [[LTCatmullRomInterpolationRoutineFactory alloc] init];
    painter.splineFactory = factory;
    expect(painter.splineFactory).to.beIdenticalTo(factory);
  });
  
  it(@"should set airbrush mode", ^{
    expect(painter.airbrush).to.beFalsy();
    painter.airbrush = YES;
    expect(painter.airbrush).to.beTruthy();
    painter.airbrush = NO;
    expect(painter.airbrush).to.beFalsy();
  });
});

context(@"painting", ^{
  __block cv::Mat4b expected;
  __block cv::Mat4b background;
  __block cv::Mat4b clear;
  
  const cv::Vec4b kBlack(0, 0, 0, 255);
  const cv::Vec4b kClear(0, 0, 0, 0);
  const cv::Vec4b kWhite(255, 255, 255, 255);
  const CGPoint kCanvasCenter = CGPointMake(kCanvasSize.width / 2, kCanvasSize.height / 2);
  const CGRect kCenterRect = CGRectFromOriginAndSize(kCanvasCenter / 2, kCanvasSize / 2);
  
  beforeEach(^{
    canvas = [LTTexture byteRGBATextureWithSize:kCanvasSize];
    painter = [[LTPainter alloc] initWithMode:LTPainterTargetModeSandboxedStroke
                                canvasTexture:canvas];
    expected.create(canvas.size.height, canvas.size.width);
    background.create(canvas.size.height, canvas.size.width);
    clear.create(canvas.size.height, canvas.size.width);
    background.setTo(kBlack);
    expected.setTo(kBlack);
    clear.setTo(kClear);
  });
  
  afterEach(^{
    painter = nil;
    canvas = nil;
  });
  
  it(@"should clear with the given color", ^{
    [painter clearWithColor:LTVector4(1, 1, 1, 1)];
    expected.setTo(kWhite);
    expect($(canvas.image)).to.equalMat($(expected));
    
    [painter clearWithColor:LTVector4(0, 0, 0, 1)];
    expected.setTo(kBlack);
    expect($(canvas.image)).to.equalMat($(expected));
  });
  
  context(@"paint according to touch collector events", ^{
    __block id touchCollector;
    __block LTBrush *brush;
    
    beforeEach(^{
      touchCollector = [OCMockObject niceMockForClass:[LTTouchCollector class]];
      brush = [[LTBrush alloc] init];
      brush.baseDiameter = kCanvasSize.width / 2;
      painter.brush = brush;
      [painter clearWithColor:LTVector4(0, 0, 0, 1)];
    });
    
    afterEach(^{
      brush = nil;
    });
    
    it(@"should paint on tap", ^{
      [painter ltTouchCollector:touchCollector startedStrokeAt:LTPointAt(kCanvasSize / 2)];
      [painter ltTouchCollectorFinishedStroke:touchCollector cancelled:NO];
      expected(LTCVRectWithCGRect(kCenterRect)).setTo(kWhite);
      expect($(canvas.image)).to.equalMat($(expected));
    });
    
    it(@"should not paint on cancelled tap", ^{
      [painter ltTouchCollector:touchCollector startedStrokeAt:LTPointAt(kCanvasSize / 2)];
      [painter ltTouchCollectorFinishedStroke:touchCollector cancelled:YES];
      expect($(canvas.image)).to.equalMat($(background));
    });
    
    it(@"should paint on gesture", ^{
      brush.spacing = 0.99;
      expect($(painter.strokeTexture.image)).to.equalMat($(clear));
      [painter ltTouchCollector:touchCollector startedStrokeAt:LTPointAt(kCanvasSize / 4)];
      [painter ltTouchCollector:touchCollector
           collectedStrokeTouch:LTPointAt(kCanvasSize * CGSizeMake(0.75, 0.25))];
      expect($(canvas.image)).to.equalMat($(background));
      expected.setTo(kClear);
      expected.rowRange(0, kCanvasSize.height / 2).setTo(kWhite);
      expect($(painter.strokeTexture.image)).to.equalMat($(expected));
      [painter ltTouchCollectorFinishedStroke:touchCollector cancelled:NO];
      expect($(painter.strokeTexture.image)).to.equalMat($(clear));
      expected.setTo(kBlack);
      expected.rowRange(0, kCanvasSize.height / 2).setTo(kWhite);
      expect($(canvas.image)).to.equalMat($(expected));
    });
    
    it(@"should not paint on timer events when airbush property is NO", ^{
      [painter ltTouchCollector:touchCollector startedStrokeAt:LTPointAt(kCanvasSize / 2)];
      [painter ltTouchCollector:touchCollector collectedTimerTouch:LTPointAt(kCanvasSize / 2)];
      [painter ltTouchCollectorFinishedStroke:touchCollector cancelled:YES];
      expect($(canvas.image)).to.equalMat($(background));
    });
    
    it(@"should paint on timer events in airbrush property is YES", ^{
      painter.airbrush = YES;
      [painter ltTouchCollector:touchCollector startedStrokeAt:LTPointAt(kCanvasSize / 2)];
      [painter ltTouchCollector:touchCollector collectedTimerTouch:LTPointAt(kCanvasSize / 2)];
      [painter ltTouchCollectorFinishedStroke:touchCollector cancelled:YES];
      expected(LTCVRectWithCGRect(kCenterRect)).setTo(kWhite);
      expect($(canvas.image)).to.equalMat($(expected));
    });
    
    context(@"delegate", ^{
      __block id delegate;
      
      beforeEach(^{
        delegate = [OCMockObject niceMockForProtocol:@protocol(LTPainterDelegate)];
        painter.delegate = delegate;
      });
      
      it(@"should update delegate on paint", ^{
        [[[delegate stub] andReturnValue:$(CGAffineTransformIdentity)]
            alternativeCoordinateSystemTransform];
        [[[delegate stub] andReturnValue:@((CGFloat)1.0)] alternativeZoomScale];
        [[[delegate expect] andDo:^(NSInvocation *invocation) {
          __unsafe_unretained NSArray *rects;
          [invocation getArgument:&rects atIndex:3];
          expect(rects.count).to.equal(1);
          expect(rects[0]).to.equal([LTRotatedRect rect:CGRectCenteredAt(CGPointMake(0.5, 0.5),
                                                                         CGSizeMake(0.5, 0.5))]);
        }] ltPainter:painter didPaintInRotatedRects:OCMOCK_ANY];

        [painter ltTouchCollector:touchCollector startedStrokeAt:LTPointAt(kCanvasSize / 2)];
        [painter ltTouchCollector:touchCollector collectedStrokeTouch:LTPointAt(kCanvasSize / 2)];

        [delegate verify];
      });
      
      it(@"should update delegate on stroke begin and end", ^{
        [[[delegate stub] andReturnValue:$(CGAffineTransformIdentity)]
            alternativeCoordinateSystemTransform];
        [[[delegate stub] andReturnValue:@((CGFloat)1.0)] alternativeZoomScale];
        [[delegate expect] ltPainterDidBeginStroke:painter];
        [[[delegate expect] andDo:^(NSInvocation *invocation) {
          __unsafe_unretained LTPainterStroke *stroke;
          [invocation getArgument:&stroke atIndex:3];
          expect(stroke.startingPoint.contentPosition).to.equal(kCanvasCenter);
          expect(stroke.segments.count).to.equal(1);
          expect(stroke).to.beIdenticalTo(painter.strokes.lastObject);
        }] ltPainter:painter didFinishStroke:OCMOCK_ANY];

        [painter ltTouchCollector:touchCollector startedStrokeAt:LTPointAt(kCanvasSize / 2)];
        [painter ltTouchCollector:touchCollector collectedStrokeTouch:LTPointAt(kCanvasSize / 2)];
        [painter ltTouchCollectorFinishedStroke:touchCollector cancelled:NO];

        [delegate verify];
      });
      
      it(@"should use the alternativeCoordinateSystemTransform", ^{
        CGAffineTransform transform =
            CGAffineTransformScale(CGAffineTransformMakeTranslation(0, kCanvasSize.height), 1, -1);

        [[[delegate stub] andReturnValue:$(transform)] alternativeCoordinateSystemTransform];
        [[[delegate stub] andReturnValue:@((CGFloat)1.0)] alternativeZoomScale];

        [painter ltTouchCollector:touchCollector startedStrokeAt:LTPointAt(kCanvasSize / 4)];
        [painter ltTouchCollectorFinishedStroke:touchCollector cancelled:NO];

        expected(cv::Rect(0, kCanvasSize.height / 2,
                          kCanvasSize.width / 2, kCanvasSize.height / 2)).setTo(kWhite);
        expect($(canvas.image)).to.equalMat($(expected));

        [delegate verify];
      });
      
      it(@"should use the alternativeZoomScale", ^{
        [[[delegate stub] andReturnValue:$(CGAffineTransformIdentity)]
            alternativeCoordinateSystemTransform];
        [[[delegate stub] andReturnValue:@((CGFloat)2.0)] alternativeZoomScale];

        [painter ltTouchCollector:touchCollector startedStrokeAt:LTPointAt(kCanvasSize / 2)];
        [painter ltTouchCollectorFinishedStroke:touchCollector cancelled:NO];

        expected(LTCVRectWithCGRect(CGRectCenteredAt(kCanvasCenter,
                                                     kCanvasSize / 4))).setTo(kWhite);
        expect($(canvas.image)).to.equalMat($(expected));

        [delegate verify];
      });
    });
  });
  
  it(@"should paint a given stroke", ^{
    id touchCollector = [OCMockObject niceMockForClass:[LTTouchCollector class]];
    LTBrush *brush = [[LTBrush alloc] init];
    brush.flow = 0.5;
    brush.spacing = 0.99;
    brush.baseDiameter = kCanvasSize.width / 2;
    painter.brush = brush;
    painter.splineFactory = [[LTLinearInterpolationRoutineFactory alloc] init];
    [painter clearWithColor:LTVector4(0, 0, 0, 1)];
    
    painter.airbrush = YES;
    [painter ltTouchCollector:touchCollector startedStrokeAt:LTPointAt(kCanvasSize / 4)];
    [painter ltTouchCollector:touchCollector
         collectedStrokeTouch:LTPointAt(kCanvasSize * CGSizeMake(0.75, 0.25))];
    [painter ltTouchCollector:touchCollector
          collectedTimerTouch:LTPointAt(kCanvasSize * CGSizeMake(0.75, 0.25))];
    [painter ltTouchCollector:touchCollector
         collectedStrokeTouch:LTPointAt(kCanvasSize * CGSizeMake(0.75, 0.75))];
    [painter ltTouchCollectorFinishedStroke:touchCollector cancelled:NO];
    
    expected.rowRange(0, kCanvasSize.height / 2).setTo(cv::Vec4b(128, 128, 128, 255));
    expected.colRange(kCanvasSize.width / 2,
                      kCanvasSize.width).setTo(cv::Vec4b(128, 128, 128, 255));
    expected(cv::Rect(kCanvasSize.width / 2, 0,
                      kCanvasSize.width / 2, kCanvasSize.height / 2)).setTo(kWhite);
    expect($(canvas.image)).to.beCloseToMat($(expected));
    
    LTPainterStroke *stroke = painter.strokes.lastObject;
    painter = [[LTPainter alloc] initWithMode:LTPainterTargetModeSandboxedStroke
                                canvasTexture:canvas];
    painter.airbrush = YES;
    painter.brush = brush;
    painter.splineFactory = [[LTLinearInterpolationRoutineFactory alloc] init];
    [painter clearWithColor:LTVector4(0, 0, 0, 1)];
    expect($(canvas.image)).to.equalMat($(background));
    [painter paintStroke:stroke];
    expect($(canvas.image)).to.beCloseToMat($(expected));
  });
});

LTSpecEnd
