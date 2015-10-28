// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPaintingStrategy.h"

#import "LTBrush.h"
#import "LTPainterPoint.h"
#import "LTPainterStroke.h"
#import "LTLinearInterpolationRoutine.h"

@interface LTPainterStroke ()
@property (strong, nonatomic) id<LTPolynomialInterpolantFactory> factory;
@end

SpecBegin(LTPaintingStrategy)

context(@"painting directions", ^{
  __block LTPaintingDirections *directions;
  __block id brush;
  __block id point;
  __block id stroke;
  
  beforeEach(^{
    brush = [OCMockObject niceMockForClass:[LTBrush class]];;
    point = [OCMockObject niceMockForClass:[LTPainterPoint class]];
    stroke = [OCMockObject niceMockForClass:[LTPainterStroke class]];
  });
  
  context(@"initialization", ^{
    context(@"brush and stroke", ^{
      it(@"should create with brush and stroke", ^{
        directions = [LTPaintingDirections directionsWithBrush:brush stroke:stroke];
        expect(directions.brush).to.beIdenticalTo(brush);
        expect(directions.stroke).to.beIdenticalTo(stroke);
      });
      
      it(@"should raise when creating with no brush", ^{
        expect(^{
          directions = [LTPaintingDirections directionsWithBrush:nil stroke:stroke];
        }).to.raise(NSInvalidArgumentException);
      });
      
      it(@"should raise when creating with no stroke", ^{
        expect(^{
          directions = [LTPaintingDirections directionsWithBrush:brush stroke:nil];
        }).to.raise(NSInvalidArgumentException);
      });
    });
    
    context(@"brush and starting point", ^{
      it(@"should create with brush and starting point", ^{
        directions = [LTPaintingDirections directionsWithBrush:brush linearStrokeStartingAt:point];
        expect(directions.brush).to.beIdenticalTo(brush);
        expect(directions.stroke.startingPoint).to.equal(point);
        expect(directions.stroke.factory).to.beKindOf([LTLinearInterpolationRoutineFactory class]);
      });
      
      it(@"should raise when creating with no brush", ^{
        expect(^{
          directions = [LTPaintingDirections directionsWithBrush:nil linearStrokeStartingAt:point];
        }).to.raise(NSInvalidArgumentException);
      });
      
      it(@"should raise when creating with no point", ^{
        expect(^{
          directions = [LTPaintingDirections directionsWithBrush:brush linearStrokeStartingAt:nil];
        }).to.raise(NSInvalidArgumentException);
      });
    });
  });
});

SpecEnd
