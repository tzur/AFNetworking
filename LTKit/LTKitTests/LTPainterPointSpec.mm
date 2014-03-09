// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterPoint.h"

#import "LTCGExtensions.h"

SpecBegin(LTPainterPoint)

context(@"initialization", ^{
  it(@"should initialize with no arguments", ^{
    expect(^{
      LTPainterPoint __unused *point = [[LTPainterPoint alloc] init];
    }).notTo.raiseAny();
  });
  
  it(@"should initailize with current timestamp", ^{
    expect(^{
      CFTimeInterval before = CACurrentMediaTime();
      LTPainterPoint __unused *point = [[LTPainterPoint alloc] initWithCurrentTimestamp];
      CFTimeInterval after = CACurrentMediaTime();
      expect(point.timestamp).to.beInTheRangeOf(before, after);
    }).notTo.raiseAny();
  });
});

context(@"properties", ^{
  __block LTPainterPoint *point;
  
  beforeEach(^{
    point = [[LTPainterPoint alloc] init];
  });

  it(@"should have default properties", ^{
    expect(point.timestamp).to.equal(0);
    expect(point.screenPosition).to.equal(CGPointZero);
    expect(point.contentPosition).to.equal(CGPointZero);
    expect(point.zoomScale).to.equal(0);
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
    CGFloat newValue = 1;
    point.zoomScale = newValue;
    expect(point.zoomScale).to.equal(newValue);
    
    point.zoomScale = -FLT_EPSILON;
    expect(point.zoomScale).to.equal(0);
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
  });
});

SpecEnd
