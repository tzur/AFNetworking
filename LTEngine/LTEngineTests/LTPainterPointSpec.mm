// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterPoint.h"

@interface LTPainterPoint ()
@property (nonatomic) CGFloat contentPositionX;
@property (nonatomic) CGFloat contentPositionY;
@end

SpecBegin(LTPainterPoint)

__block LTPainterPoint *point;

context(@"initialization", ^{
  it(@"should initialize with no arguments", ^{
    point = [[LTPainterPoint alloc] init];
    expect(point).toNot.beNil();
  });

  it(@"should initialize with current timestamp", ^{
    CFTimeInterval before = CACurrentMediaTime();
    point = [[LTPainterPoint alloc] initWithCurrentTimestamp];
    CFTimeInterval after = CACurrentMediaTime();
    expect(point).toNot.beNil();
    expect(point.timestamp).to.beInTheRangeOf(before, after);
  });

  it(@"should initialize with interpolated properties", ^{
    NSDictionary *properties = @{
      @instanceKeypath(LTPainterPoint, contentPositionX): @7,
      @instanceKeypath(LTPainterPoint, contentPositionY): @9,
      @instanceKeypath(LTPainterPoint, zoomScale): @1.5
    };
    point = [[LTPainterPoint alloc] initWithInterpolatedProperties:properties];
    expect(point.contentPosition).to.equal(CGPointMake(7, 9));
    expect(point.zoomScale).to.equal(1.5);
  });

  it(@"should raise when attempting to initialize with non-existent interpolated properties", ^{
    NSDictionary *properties = @{
      @instanceKeypath(LTPainterPoint, contentPositionX): @7,
      @instanceKeypath(LTPainterPoint, contentPositionY): @9,
      @"notExistentProperty": @1.5
    };
    expect(^{
      point = [[LTPainterPoint alloc] initWithInterpolatedProperties:properties];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"properties", ^{
  beforeEach(^{
    point = [[LTPainterPoint alloc] init];
  });

  it(@"should have default properties", ^{
    expect(point.timestamp).to.equal(0);
    expect(point.screenPosition).to.equal(CGPointZero);
    expect(point.contentPosition).to.equal(CGPointZero);
    expect(point.zoomScale).to.equal(1);
    expect(point.touchRadius).to.equal(1);
    expect(point.touchRadiusTolerance).to.equal(1);
    expect(point.distanceFromStart).to.equal(0);
    expect(point.diameter).to.equal(0);
  });

  it(@"should set and clamp timestamp", ^{
    CGFloat newValue = 1;
    point.timestamp = newValue;
    expect(point.timestamp).to.equal(newValue);
    
    point.timestamp = -DBL_EPSILON;
    expect(point.timestamp).to.equal(0);
  });
  
  it(@"should set screenPosition", ^{
    CGPoint newValue = CGPointMake(1, 1);
    point.screenPosition = newValue;
    expect(point.screenPosition).to.equal(newValue);
  });
  
  it(@"should set contentPosition", ^{
    CGPoint newValue = CGPointMake(1, 1);
    point.contentPosition = newValue;
    expect(point.contentPosition).to.equal(newValue);
  });
  
  it(@"should set zoomScale", ^{
    CGFloat newValue = 2;
    point.zoomScale = newValue;
    expect(point.zoomScale).to.equal(newValue);
    
    point.zoomScale = -FLT_EPSILON;
    expect(point.zoomScale).to.equal(0);
  });
  
  it(@"should set touchRadius", ^{
    CGFloat newValue = 2;
    point.touchRadius = newValue;
    expect(point.touchRadius).to.equal(newValue);
    
    point.touchRadius = -FLT_EPSILON;
    expect(point.touchRadius).to.equal(0);
  });
  
  it(@"should set touchRadiusTolerance", ^{
    CGFloat newValue = 2;
    point.touchRadiusTolerance = newValue;
    expect(point.touchRadiusTolerance).to.equal(newValue);
    
    point.touchRadiusTolerance = -FLT_EPSILON;
    expect(point.touchRadiusTolerance).to.equal(0);
  });
  
  it(@"should set distanceFromStart", ^{
    CGFloat newValue = 1;
    point.distanceFromStart = newValue;
    expect(point.distanceFromStart).to.equal(newValue);
    
    point.distanceFromStart = -FLT_EPSILON;
    expect(point.distanceFromStart).to.equal(0);
  });
  
  it(@"should set diameter", ^{
    CGFloat newValue = 1;
    point.diameter = newValue;
    expect(point.diameter).to.equal(newValue);
    
    point.diameter = -FLT_EPSILON;
    expect(point.diameter).to.equal(0);
  });
});

context(@"copying", ^{
  __block LTPainterPoint *point;
  
  beforeEach(^{
    point = [[LTPainterPoint alloc] init];
    point.timestamp = 1;
    point.screenPosition = CGPointMake(1, 1);
    point.contentPosition = CGPointMake(2, 2);
    point.zoomScale = 3;
    point.distanceFromStart = 4;
    point.diameter = 5;
    point.touchRadius = 6;
    point.touchRadiusTolerance = 7;
  });
  
  it(@"should copy", ^{
    LTPainterPoint *copy = [point copy];
    expect(copy).notTo.beIdenticalTo(point);
    expect(copy.timestamp).to.equal(point.timestamp);
    expect(copy.screenPosition).to.equal(point.screenPosition);
    expect(copy.contentPosition).to.equal(point.contentPosition);
    expect(copy.zoomScale).to.equal(point.zoomScale);
    expect(copy.distanceFromStart).to.equal(point.distanceFromStart);
    expect(copy.diameter).to.equal(point.diameter);
    expect(copy.touchRadius).to.equal(point.touchRadius);
    expect(copy.touchRadiusTolerance).to.equal(point.touchRadiusTolerance);
  });
  
  it(@"should copy with zone", ^{
    LTPainterPoint *copy = [point copyWithZone:nil];
    expect(copy).notTo.beIdenticalTo(point);
    expect(copy.timestamp).to.equal(point.timestamp);
    expect(copy.screenPosition).to.equal(point.screenPosition);
    expect(copy.contentPosition).to.equal(point.contentPosition);
    expect(copy.zoomScale).to.equal(point.zoomScale);
    expect(copy.distanceFromStart).to.equal(point.distanceFromStart);
    expect(copy.diameter).to.equal(point.diameter);
    expect(copy.touchRadius).to.equal(point.touchRadius);
    expect(copy.touchRadiusTolerance).to.equal(point.touchRadiusTolerance);
  });
});

SpecEnd
