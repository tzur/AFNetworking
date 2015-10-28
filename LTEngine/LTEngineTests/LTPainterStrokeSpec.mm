// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterStroke.h"

#import "LTCatmullRomInterpolant.h"
#import "LTDegenerateInterpolationRoutine.h"
#import "LTLinearInterpolationRoutine.h"
#import "LTPainterPoint.h"
#import "LTPainterStrokeSegment.h"

@interface LTPainterStrokeSegment ()
@property (strong, nonatomic) LTPolynomialInterpolant *interpolant;
@property (strong, nonatomic) LTPainterPoint *startPoint;
@property (strong, nonatomic) LTPainterPoint *endPoint;
@end

SpecBegin(LTPainterStroke)

context(@"initialization", ^{
  __block id<LTPolynomialInterpolantFactory> factory;
  
  beforeEach(^{
    factory = [[LTDegenerateInterpolationRoutineFactory alloc] init];
  });
  
  it(@"should initialize with valid arguments", ^{
    LTPainterPoint *startingPoint = [[LTPainterPoint alloc] init];
    LTPainterStroke *stroke =
        [[LTPainterStroke alloc] initWithInterpolationRoutineFactory:factory
                                                       startingPoint:startingPoint];
    expect(stroke.startingPoint).to.beIdenticalTo(startingPoint);
    expect(stroke.segments.count).to.equal(0);
  });
  
  it(@"should raise an exception with nil factory", ^{
    expect(^{
      LTPainterPoint *startingPoint = [[LTPainterPoint alloc] init];
      LTPainterStroke __unused *stroke =
          [[LTPainterStroke alloc] initWithInterpolationRoutineFactory:nil
                                                         startingPoint:startingPoint];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise an exception with nil starting point", ^{
    expect(^{
      LTPainterStroke __unused *stroke =
          [[LTPainterStroke alloc] initWithInterpolationRoutineFactory:factory
                                                         startingPoint:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"adding points and segments", ^{
  __block LTPainterStroke *stroke;
  __block LTPainterPoint *startingPoint;
  __block LTPainterPoint *newPoint;
  __block id<LTPolynomialInterpolantFactory> factory;

  beforeEach(^{
    startingPoint = [[LTPainterPoint alloc] init];
    newPoint = [[LTPainterPoint alloc] init];
    newPoint.contentPosition = CGPointMake(1, 1);
  });
  
  it(@"should add point", ^{
    stroke = [[LTPainterStroke alloc]
              initWithInterpolationRoutineFactory:[[LTLinearInterpolationRoutineFactory alloc] init]
              startingPoint:startingPoint];
    [stroke addPointAt:newPoint];
    expect(stroke.segments.count).to.equal(1);
    expect(stroke.segments.firstObject).to.beIdenticalTo(newPoint);
  });
  
  context(@"degenerate interpolation factory", ^{
    beforeEach(^{
      factory = [[LTDegenerateInterpolationRoutineFactory alloc] init];
      stroke = [[LTPainterStroke alloc] initWithInterpolationRoutineFactory:factory
                                                              startingPoint:startingPoint];
    });
    
    it(@"should add a segment immediately", ^{
      expect([stroke addSegmentTo:newPoint]).notTo.beNil();
    });
    
    it(@"should return the correct segment", ^{
      LTPainterStrokeSegment *segment = [stroke addSegmentTo:newPoint];
      expect(segment.startPoint.contentPosition).to.equal(newPoint.contentPosition);
      expect(segment.endPoint.contentPosition).to.equal(newPoint.contentPosition);
      expect(segment.distanceFromStart).to.equal(CGPointDistance(newPoint.contentPosition,
                                                                 startingPoint.contentPosition));
    });
  });
  
  context(@"linear interpolation factory", ^{
    beforeEach(^{
      factory = [[LTLinearInterpolationRoutineFactory alloc] init];
      stroke = [[LTPainterStroke alloc] initWithInterpolationRoutineFactory:factory
                                                              startingPoint:startingPoint];
    });
    
    it(@"should add a segment immediately", ^{
      expect([stroke addSegmentTo:newPoint]).notTo.beNil();
    });
    
    it(@"should return the correct segment", ^{
      LTPainterStrokeSegment *segment = [stroke addSegmentTo:newPoint];
      expect(segment.startPoint.contentPosition).to.equal(startingPoint.contentPosition);
      expect(segment.endPoint.contentPosition).to.equal(newPoint.contentPosition);
      
      CGFloat distance = CGPointDistance(startingPoint.contentPosition, newPoint.contentPosition);
      expect(segment.distanceFromStart).to.equal(0);
      expect(segment.length).to.beCloseToWithin(distance, 1e-2);
      
      segment = [stroke addSegmentTo:newPoint];
      expect(segment.distanceFromStart).to.beCloseToWithin(distance, 1e-2);
      expect(segment.length).to.equal(0);
    });
  });
  
  context(@"catmull-rom interpolation factory", ^{
    __block NSMutableArray *newPoints;
    
    beforeEach(^{
      factory = [[LTCatmullRomInterpolantFactory alloc] init];
      stroke = [[LTPainterStroke alloc] initWithInterpolationRoutineFactory:factory
                                                              startingPoint:startingPoint];
      newPoints = [NSMutableArray array];
      for (NSUInteger i = 0; i < 4; ++i) {
        [newPoints addObject:[[LTPainterPoint alloc] init]];
        [newPoints[i] setContentPosition:CGPointMake(i + 1, i + 1)];
        [newPoints[i] setZoomScale:1];
      }
    });
    
    it(@"should return linear segment when there are not enough points", ^{
      expect([[stroke addSegmentTo:newPoints[0]] interpolant])
          .to.beKindOf([LTLinearInterpolationRoutine class]);
      expect([stroke addSegmentTo:newPoints[1]]).to.beNil();
      expect([[stroke addSegmentTo:newPoints[2]] interpolant])
          .to.beKindOf([LTCatmullRomInterpolant class]);
      expect([[stroke addSegmentTo:newPoints[2]] interpolant])
          .to.beKindOf([LTCatmullRomInterpolant class]);
      expect(stroke.segments.count).to.equal(3);
    });
    
    it(@"should return the correct segment (delay of 1 point)", ^{
      [stroke addSegmentTo:newPoints[0]];
      [stroke addSegmentTo:newPoints[1]];
      [stroke addSegmentTo:newPoints[2]];
      [stroke addSegmentTo:newPoints[3]];
      
      [stroke.segments enumerateObjectsUsingBlock:^(LTPainterStrokeSegment *segment,
                                                    NSUInteger idx, BOOL *) {
        if (idx) {
          LTPainterStrokeSegment *previous = stroke.segments[idx-1];
          expect(segment.startPoint.contentPosition).to.equal(previous.endPoint.contentPosition);
        } else {
          expect(segment.startPoint.contentPosition).to.equal(CGPointZero);
          expect(segment.endPoint.contentPosition).to.equal([newPoints[0] contentPosition]);
        }
      }];
    });
  });
  
  it(@"should be able to add mixed points and segments", ^{
    LTPainterPoint *p1 = [[LTPainterPoint alloc] init];
    LTPainterPoint *p2 = [[LTPainterPoint alloc] init];
    LTPainterPoint *p3 = [[LTPainterPoint alloc] init];
    p1.contentPosition = CGPointMake(1, 1);
    p2.contentPosition = CGPointMake(2, 2);
    p3.contentPosition = CGPointMake(3, 3);
    
    stroke = [[LTPainterStroke alloc]
              initWithInterpolationRoutineFactory:[[LTLinearInterpolationRoutineFactory alloc] init]
              startingPoint:startingPoint];

    [stroke addSegmentTo:p1];
    [stroke addPointAt:p2];
    [stroke addSegmentTo:p3];
    
    expect(stroke.segments.count).to.equal(3);
    expect(stroke.segments[0]).to.beKindOf([LTPainterStrokeSegment class]);
    expect(stroke.segments[1]).to.beKindOf([LTPainterPoint class]);
    expect(stroke.segments[2]).to.beKindOf([LTPainterStrokeSegment class]);
    
    expect([(LTPainterStrokeSegment *)stroke.segments[0]
                startPoint].contentPosition).to.equal(startingPoint.contentPosition);
    expect([(LTPainterStrokeSegment *)stroke.segments[0]
                endPoint].contentPosition).to.equal(p1.contentPosition);
    expect([stroke.segments[1] contentPosition]).to.equal(p2.contentPosition);
    expect([(LTPainterStrokeSegment *)stroke.segments[2]
                startPoint].contentPosition).to.equal(p2.contentPosition);
    expect([(LTPainterStrokeSegment *)stroke.segments[2]
                endPoint].contentPosition).to.equal(p3.contentPosition);
  });
});

SpecEnd
