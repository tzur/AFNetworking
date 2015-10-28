// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterStrokeSegment.h"

#import "LTCatmullRomInterpolant.h"
#import "LTDegenerateInterpolationRoutine.h"
#import "LTLinearInterpolationRoutine.h"
#import "LTPainterPoint.h"

SpecBegin(LTPainterStrokeSegment)

__block LTPainterStrokeSegment *segment;
__block LTPolynomialInterpolant *interpolant;

context(@"initialization", ^{
  beforeEach(^{
    LTPainterPoint *point = [[LTPainterPoint alloc] init];
    interpolant = [[LTDegenerateInterpolationRoutine alloc] initWithKeyFrames:@[point]];
  });
  
  it(@"should initailize with valid arguments", ^{
    segment = [[LTPainterStrokeSegment alloc] initWithSegmentIndex:1
                                                 distanceFromStart:1
                                                    andInterpolant:interpolant];
    expect(segment.index).to.equal(1);
    expect(segment.distanceFromStart).to.equal(1);
  });
  
  it(@"should raise an exception when initializing with invalid arguments", ^{
    expect(^{
      segment = [[LTPainterStrokeSegment alloc] initWithSegmentIndex:1
                                                   distanceFromStart:-FLT_EPSILON
                                                      andInterpolant:interpolant];
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      segment = [[LTPainterStrokeSegment alloc] initWithSegmentIndex:1
                                                   distanceFromStart:1
                                                      andInterpolant:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"points with interval", ^{
  context(@"arguments validation", ^{
    beforeEach(^{
      interpolant = [[LTDegenerateInterpolationRoutine alloc]
                     initWithKeyFrames:@[[[LTPainterPoint alloc] init]]];
      segment = [[LTPainterStrokeSegment alloc] initWithSegmentIndex:1
                                                   distanceFromStart:1
                                                      andInterpolant:interpolant];
    });
    it(@"should raise an exception for non-positive interval", ^{
      expect(^{
        [segment pointsWithInterval:FLT_EPSILON startingAtOffset:0];
      }).notTo.raiseAny();
      expect(^{
        [segment pointsWithInterval:0 startingAtOffset:0];
      }).to.raise(NSInvalidArgumentException);
      expect(^{
        [segment pointsWithInterval:-1 startingAtOffset:0];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise an exception for negative offset", ^{
      expect(^{
        [segment pointsWithInterval:FLT_EPSILON startingAtOffset:0];
      }).notTo.raiseAny();
      expect(^{
        [segment pointsWithInterval:FLT_EPSILON startingAtOffset:FLT_EPSILON];
      }).notTo.raiseAny();
      expect(^{
        [segment pointsWithInterval:-FLT_EPSILON startingAtOffset:0];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"degenerate segment", ^{
    beforeEach(^{
      LTPainterPoint *point = [[LTPainterPoint alloc] init];
      point.contentPosition = CGPointMake(1,1);
      interpolant = [[LTDegenerateInterpolationRoutine alloc] initWithKeyFrames:@[point]];
      segment = [[LTPainterStrokeSegment alloc] initWithSegmentIndex:1
                                                   distanceFromStart:1
                                                      andInterpolant:interpolant];
    });
    
    it(@"should return correct starting point", ^{
      expect(segment.startPoint.contentPosition).to.equal(CGPointMake(1, 1));
    });
    
    it(@"should approximate length", ^{
      expect(segment.length).to.equal(0);
    });
    
    it(@"should return the correct number of points", ^{
      NSArray *points = [segment pointsWithInterval:1 startingAtOffset:0];
      expect(points.count).to.equal(1);
      points = [segment pointsWithInterval:FLT_EPSILON startingAtOffset:0];
      expect(points.count).to.equal(1);
      points = [segment pointsWithInterval:FLT_EPSILON startingAtOffset:FLT_EPSILON];
      expect(points.count).to.equal(0);
    });
    
    it(@"distance between points should be accurate", ^{
      NSArray *points = [segment pointsWithInterval:1 startingAtOffset:0];
      expect([points.firstObject distanceFromStart]).to.equal(segment.distanceFromStart);
    });
  });
  
  context(@"linear segment", ^{
    __block LTPainterPoint *startPoint;
    __block LTPainterPoint *endPoint;
    
    beforeEach(^{
      startPoint = [[LTPainterPoint alloc] init];
      endPoint = [[LTPainterPoint alloc] init];
      startPoint.contentPosition = CGPointMake(1,1);
      endPoint.contentPosition = CGPointMake(100,100);
      interpolant = [[LTLinearInterpolationRoutine alloc] initWithKeyFrames:@[startPoint, endPoint]];
      segment = [[LTPainterStrokeSegment alloc] initWithSegmentIndex:1
                                                   distanceFromStart:1
                                                      andInterpolant:interpolant];
    });
    
    it(@"should return correct starting point", ^{
      expect(segment.startPoint.contentPosition).to.equal(startPoint.contentPosition);
    });

    it(@"should approximate length", ^{
      expect(segment.length).to.beCloseToWithin(CGPointDistance(startPoint.contentPosition,
                                                                endPoint.contentPosition), 1);
    });
    
    it(@"should return the correct number of points", ^{
      NSArray *points = [segment pointsWithInterval:M_SQRT2 - 1e-2 startingAtOffset:0];
      expect(points.count).to.equal(100);
      points = [segment pointsWithInterval:M_SQRT2 + 1e-2 startingAtOffset:0];
      expect(points.count).to.equal(99);
      points = [segment pointsWithInterval:M_SQRT2 - 1e-2 startingAtOffset:1];
      expect(points.count).to.equal(99);
    });
    
    it(@"distance between points should be accurate", ^{
      NSArray *points = [segment pointsWithInterval:M_SQRT2 startingAtOffset:0];
      for (NSUInteger i = 1; i < points.count; ++i) {
        expect(CGPointDistance([points[i - 1] contentPosition],
                               [points[i] contentPosition])).to.beCloseToWithin(M_SQRT2, 1e-3);
      }
      points = [segment pointsWithInterval:M_SQRT2 startingAtOffset:1];
      for (NSUInteger i = 1; i < points.count; ++i) {
        expect(CGPointDistance([points[i - 1] contentPosition],
                               [points[i] contentPosition])).to.beCloseToWithin(M_SQRT2, 1e-3);
      }
    });
  });
  
  // The expected values for these tests were calculated in matlab for the current points.
  // Script is available at: lightricks-research/common/interpolation/CatmullRomLength.m.
  context(@"catmull-rom segment", ^{
    beforeEach(^{
      LTPainterPoint *p0 = [[LTPainterPoint alloc] init];
      LTPainterPoint *p1 = [[LTPainterPoint alloc] init];
      LTPainterPoint *p2 = [[LTPainterPoint alloc] init];
      LTPainterPoint *p3 = [[LTPainterPoint alloc] init];
      p0.contentPosition = CGPointMake(10, 14);
      p1.contentPosition = CGPointMake(31, 58);
      p2.contentPosition = CGPointMake(66, 60);
      p3.contentPosition = CGPointMake(77, 15);
      interpolant = [[LTCatmullRomInterpolant alloc] initWithKeyFrames:@[p0, p1, p2, p3]];
      segment = [[LTPainterStrokeSegment alloc] initWithSegmentIndex:1
                                                   distanceFromStart:1
                                                      andInterpolant:interpolant];
    });
    
    it(@"should return correct starting point", ^{
      expect(segment.startPoint.contentPosition).to.equal(CGPointMake(31, 58));
    });

    it(@"should approximate length", ^{
      expect(segment.length).to.beCloseToWithin(37.5179, 1);
    });
    
    it(@"should return the correct number of points", ^{
      NSArray *points = [segment pointsWithInterval:5 startingAtOffset:0];
      expect(points.count).to.equal(8);
      points = [segment pointsWithInterval:5 startingAtOffset:3];
      expect(points.count).to.equal(7);
    });
    
    it(@"distance between points should be accurate", ^{
      NSArray *p = [segment pointsWithInterval:5 startingAtOffset:0];
      expect([p[0] contentPosition]).to.beCloseToPointWithin(CGPointMake(31.0000, 58.0000), 1e-1);
      expect([p[1] contentPosition]).to.beCloseToPointWithin(CGPointMake(35.1732, 60.7438), 1e-1);
      expect([p[2] contentPosition]).to.beCloseToPointWithin(CGPointMake(39.7678, 62.7073), 1e-1);
      expect([p[3] contentPosition]).to.beCloseToPointWithin(CGPointMake(44.6011, 63.9801), 1e-1);
      expect([p[4] contentPosition]).to.beCloseToPointWithin(CGPointMake(49.5620, 64.5887), 1e-1);
      expect([p[5] contentPosition]).to.beCloseToPointWithin(CGPointMake(54.5585, 64.4900), 1e-1);
      expect([p[6] contentPosition]).to.beCloseToPointWithin(CGPointMake(59.4653, 63.5518), 1e-1);
      expect([p[7] contentPosition]).to.beCloseToPointWithin(CGPointMake(64.0209, 61.5235), 1e-1);
      
      p = [segment pointsWithInterval:5 startingAtOffset:3];
      expect([p[0] contentPosition]).to.beCloseToPointWithin(CGPointMake(33.4380, 59.7463), 1e-1);
      expect([p[1] contentPosition]).to.beCloseToPointWithin(CGPointMake(37.8907, 62.0074), 1e-1);
      expect([p[2] contentPosition]).to.beCloseToPointWithin(CGPointMake(42.6460, 63.5504), 1e-1);
      expect([p[3] contentPosition]).to.beCloseToPointWithin(CGPointMake(47.5681, 64.4260), 1e-1);
      expect([p[4] contentPosition]).to.beCloseToPointWithin(CGPointMake(52.5635, 64.6204), 1e-1);
      expect([p[5] contentPosition]).to.beCloseToPointWithin(CGPointMake(57.5252, 64.0410), 1e-1);
      expect([p[6] contentPosition]).to.beCloseToPointWithin(CGPointMake(62.2673, 62.4871), 1e-1);
    });
  });
});

SpecEnd
