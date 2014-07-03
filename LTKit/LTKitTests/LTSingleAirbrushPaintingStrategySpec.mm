// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSingleAirbrushPaintingStrategy.h"

#import "LTBrush.h"
#import "LTCGExtensions.h"
#import "LTPainter.h"
#import "LTPainterPoint.h"
#import "LTPainterStroke.h"
#import "LTRandom.h"
#import "LTTexture.h"

@interface LTSingleAirbrushPaintingStrategy ()
@property (strong, nonatomic) NSArray *points;
@end

@interface TestPointsTransformer : NSObject <LTSingleAirbrushPaintingStrategyPointsTransformer>
@end

@implementation TestPointsTransformer

- (LTSingleAirbrushPoints)transformedPoints:(const LTSingleAirbrushPoints &)points {
  LTSingleAirbrushPoints transformedPoints = points;
  std::reverse(transformedPoints.begin(), transformedPoints.end());
  return transformedPoints;
}

@end

SpecBegin(LTSingleAirbrushPaintingStrategy)

static const NSUInteger kTestingSeed = 1234;

__block LTSingleAirbrushPaintingStrategy *strategy;
__block id brush;

beforeEach(^{
  brush = [OCMockObject niceMockForClass:[LTBrush class]];
  [[[brush stub] andReturn:[[LTRandom alloc] initWithSeed:kTestingSeed]] random];
});

afterEach(^{
  strategy = nil;
  brush = nil;
});

context(@"initialization", ^{
  it(@"should initialize with brush", ^{
    expect(^{
      strategy = [[LTSingleAirbrushPaintingStrategy alloc] initWithBrush:brush];
    }).notTo.raiseAny();
    expect(strategy.brush).to.beIdenticalTo(brush);
  });
  
  it(@"should raise when initializing without brush", ^{
    expect(^{
      strategy = [[LTSingleAirbrushPaintingStrategy alloc] initWithBrush:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"instance", ^{
  beforeEach(^{
    strategy = [[LTSingleAirbrushPaintingStrategy alloc] initWithBrush:brush];
  });
  
  context(@"properties", ^{
    it(@"shold have default properties", ^{
      expect(strategy.points).to.beNil();
      expect(strategy.pointsTransformer).to.beNil();
      expect(strategy.fillFactor).to.equal(1);
      expect(strategy.fillRandomness).to.equal(1);
      expect(strategy.random).to.beIdenticalTo([brush random]);
    });
    
    it(@"should set points", ^{
      NSArray *array = @[];
      NSMutableArray *mutableArray =
          [NSMutableArray arrayWithObject:[[LTPainterPoint alloc] initWithCurrentTimestamp]];
      expect(strategy.points).to.beNil();
      strategy.points = array;
      expect(strategy.points).to.beIdenticalTo(array);
      strategy.points = mutableArray;
      expect(strategy.points).to.beIdenticalTo(mutableArray);
    });

    it(@"should set pointsTransformer", ^{
      expect(strategy.pointsTransformer).to.beNil();
      id transformer =[OCMockObject niceMockForProtocol:
                       @protocol(LTSingleAirbrushPaintingStrategyPointsTransformer)];
      strategy.pointsTransformer = transformer;
      expect(strategy.pointsTransformer).to.beIdenticalTo(transformer);
    });
    
    it(@"should set fillFactor", ^{
      CGFloat newValue = 0.5;
      expect(strategy.fillFactor).notTo.equal(newValue);
      strategy.fillFactor = newValue;
      expect(strategy.fillFactor).to.equal(newValue);
    });
    
    it(@"should set fillRandomness", ^{
      CGFloat newValue = 0.5;
      expect(strategy.fillRandomness).notTo.equal(newValue);
      strategy.fillRandomness = newValue;
      expect(strategy.fillRandomness).to.equal(newValue);
    });
  });
  
  context(@"generate points", ^{
    __block id painter;
    
    beforeEach(^{
      // Mock the brush.
      [[[brush stub] andReturnValue:[NSNumber numberWithUnsignedInteger:10]] baseDiameter];
      [(LTBrush *)[[brush stub] andReturnValue:@((CGFloat)1)] scale];
      
      // Mock the painter.
      id texture = [OCMockObject mockForClass:[LTTexture class]];
      [[[texture stub] andReturnValue:$(CGSizeMakeUniform(100))] size];
      painter = [OCMockObject mockForClass:[LTPainter class]];
      [[[painter stub] andReturn:texture] canvasTexture];
    });
    
    it(@"should generate points according to painter canvas texture", ^{
      [strategy paintingWillBeginWithPainter:painter];
      expect(strategy.points.count).to.equal(11 * 11);
    });
    
    it(@"should generate points according to fillFactor", ^{
      strategy.fillFactor = 2;
      [strategy paintingWillBeginWithPainter:painter];
      expect(strategy.points.count).to.equal(21 * 21);

      strategy.fillFactor = 0.5;
      [strategy paintingWillBeginWithPainter:painter];
      expect(strategy.points.count).to.equal(6 * 6);
    });
    
    it(@"should generate points according to fillRandomness", ^{
      strategy.fillRandomness = 0;
      [strategy paintingWillBeginWithPainter:painter];
      expect([strategy.points[0] contentPosition]).to.beCloseToPoint(CGPointMake(5, 5));
      expect([strategy.points[1] contentPosition]).to.beCloseToPoint(CGPointMake(15, 5));
      
      strategy.fillRandomness = 1;
      [strategy paintingWillBeginWithPainter:painter];
      expect([strategy.points[0] contentPosition]).notTo.beCloseToPoint(CGPointMake(5, 5));
      expect([strategy.points[0] contentPosition].x).to.beInTheRangeOf(0, 10);
      expect([strategy.points[0] contentPosition].y).to.beInTheRangeOf(0, 10);
      expect([strategy.points[1] contentPosition]).notTo.beCloseToPoint(CGPointMake(15, 5));
      expect([strategy.points[1] contentPosition].x).to.beInTheRangeOf(10, 20);
      expect([strategy.points[1] contentPosition].y).to.beInTheRangeOf(0, 10);
    });
    
    it(@"should generate points according to pointsTransformer", ^{
      TestPointsTransformer *transformer = [[TestPointsTransformer alloc] init];
      strategy.pointsTransformer = transformer;
      strategy.fillRandomness = 0;
      [strategy paintingWillBeginWithPainter:painter];
      expect([strategy.points.firstObject contentPosition]).to.beCloseToPoint(CGPointMake(105, 105));
      expect([strategy.points.lastObject contentPosition]).to.beCloseToPoint(CGPointMake(5, 5));
    });
  });
  
  context(@"painting directions", ^{
    beforeEach(^{
      NSMutableArray *points = [NSMutableArray array];
      for (NSUInteger i = 0; i < 10; ++i) {
        LTPainterPoint *point = [[LTPainterPoint alloc] init];
        point.contentPosition = CGPointMake(i, i);
        point.zoomScale = 1.0;
        [points addObject:point];
      }
      strategy.points = points;
    });
    
    it(@"should raise if starting progress is less than 0", ^{
      expect(^{
        [strategy paintingDirectionsForStartingProgress:-DBL_EPSILON endingProgress:1];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise if ending progress is greater than 1", ^{
      expect(^{
        [strategy paintingDirectionsForStartingProgress:0 endingProgress:1 + DBL_EPSILON];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise if starting progress is greater than than ending progress", ^{
      expect(^{
        [strategy paintingDirectionsForStartingProgress:0.5 + DBL_EPSILON endingProgress:0.5];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should return a single directions object for progress in [0,1]", ^{
      NSArray *directions = [strategy paintingDirectionsForStartingProgress:0 endingProgress:1];
      expect(directions.count).to.equal(1);
      expect(directions.firstObject).to.beKindOf([LTPaintingDirections class]);

      LTPaintingDirections *pd = directions.firstObject;
      expect(pd.brush).to.beIdenticalTo(brush);
      expect(pd.stroke.segments.count).to.equal(strategy.points.count);
      for (NSUInteger i = 0; i < strategy.points.count; ++i) {
        expect(pd.stroke.segments[i]).to.equal(strategy.points[i]);
      }
    });
    
    it(@"should return non-overlapping directions", ^{
      LTPaintingDirections *first =
          [strategy paintingDirectionsForStartingProgress:0 endingProgress:0.5].firstObject;
      LTPaintingDirections *second =
          [strategy paintingDirectionsForStartingProgress:0.5 endingProgress:1].firstObject;

      expect(first.stroke.segments.count).to.equal(strategy.points.count / 2);
      expect(second.stroke.segments.count).to.equal(strategy.points.count / 2);
      expect([first.stroke.segments.lastObject contentPosition]).to.equal(CGPointMake(4, 4));
      expect([second.stroke.segments.firstObject contentPosition]).to.equal(CGPointMake(5, 5));
    });
    
    it(@"should return empty directions", ^{
      LTPaintingDirections *first =
          [strategy paintingDirectionsForStartingProgress:0 endingProgress:0.05].firstObject;
      LTPaintingDirections *second =
          [strategy paintingDirectionsForStartingProgress:0.05 endingProgress:0.1].firstObject;
      LTPaintingDirections *third =
          [strategy paintingDirectionsForStartingProgress:0.05 endingProgress:0.12].firstObject;
      
      expect(first.stroke.segments.count).to.equal(1);
      expect(second.stroke.segments.count).to.equal(0);
      expect(third.stroke.segments.count).to.equal(1);
      expect([first.stroke.segments.firstObject contentPosition]).to.equal(CGPointMake(0, 0));
      expect([third.stroke.segments.firstObject contentPosition]).to.equal(CGPointMake(1, 1));
    });
  });
});

SpecEnd
