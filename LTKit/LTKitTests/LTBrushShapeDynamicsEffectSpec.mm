// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushShapeDynamicsEffect.h"

#import "LTBrushEffectExamples.h"
#import "LTCGExtensions.h"
#import "LTRandom.h"
#import "LTRotatedRect.h"

LTSpecBegin(LTBrushShapeDynamicsEffect)

itShouldBehaveLike(kLTBrushEffectSubclassExamples,
                   @{kLTBrushEffectClass: [LTBrushShapeDynamicsEffect class]});

__block LTBrushShapeDynamicsEffect *effect;

context(@"initialization", ^{
  it(@"should initialize with default initializer", ^{
    expect(^{
      effect = [[LTBrushShapeDynamicsEffect alloc] init];
    }).notTo.raiseAny();
  });
});

context(@"properties", ^{
  const CGFloat kEpsilon = 1e-6;
  
  beforeEach(^{
    effect = [[LTBrushShapeDynamicsEffect alloc] init];
  });
  
  it(@"should have default properties", ^{
    expect(effect.sizeJitter).to.equal(1);
    expect(effect.minimumDiameter).to.equal(0.5);
    expect(effect.angleJitter).to.equal(1);
    expect(effect.roundnessJitter).to.equal(0);
    expect(effect.minimumRoundness).to.equal(0.25);
  });
  
  it(@"should set sizeJitter", ^{
    CGFloat newValue = 0.5;
    expect(effect.sizeJitter).notTo.equal(newValue);
    effect.sizeJitter = newValue;
    expect(effect.sizeJitter).to.equal(newValue);
    
    expect(^{
      effect.sizeJitter = effect.minSizeJitter - kEpsilon;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      effect.sizeJitter = effect.maxSizeJitter + kEpsilon;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should set minimumDiameter", ^{
    CGFloat newValue = 0.75;
    expect(effect.minimumDiameter).notTo.equal(newValue);
    effect.minimumDiameter = newValue;
    expect(effect.minimumDiameter).to.equal(newValue);
    
    expect(^{
      effect.minimumDiameter = effect.minMinimumDiameter - kEpsilon;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      effect.minimumDiameter = effect.maxMinimumDiameter + kEpsilon;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should set angleJitter", ^{
    CGFloat newValue = 0.5;
    expect(effect.angleJitter).notTo.equal(newValue);
    effect.angleJitter = newValue;
    expect(effect.angleJitter).to.equal(newValue);
    
    expect(^{
      effect.angleJitter = effect.minAngleJitter - kEpsilon;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      effect.angleJitter = effect.maxAngleJitter + kEpsilon;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should set roundnessJitter", ^{
    CGFloat newValue = 0.5;
    expect(effect.roundnessJitter).notTo.equal(newValue);
    effect.roundnessJitter = newValue;
    expect(effect.roundnessJitter).to.equal(newValue);
    
    expect(^{
      effect.roundnessJitter = effect.minRoundnessJitter - kEpsilon;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      effect.roundnessJitter = effect.maxRoundnessJitter + kEpsilon;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should set minimumRoundness", ^{
    CGFloat newValue = 0.5;
    expect(effect.minimumRoundness).notTo.equal(newValue);
    effect.minimumRoundness = newValue;
    expect(effect.minimumRoundness).to.equal(newValue);
    
    expect(^{
      effect.minimumRoundness = effect.minMinimumRoundness - kEpsilon;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      effect.minimumRoundness = effect.maxMinimumRoundness + kEpsilon;
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"effect", ^{
  __block NSMutableArray *sourceRects;
  __block NSArray *dynamicRects;
  
  beforeEach(^{
    LTRandom *random = [JSObjection defaultInjector][[LTRandom class]];
    effect = [[LTBrushShapeDynamicsEffect alloc] initWithRandom:random];
    srand48(0);
    sourceRects = [NSMutableArray array];
    for (NSUInteger i = 0; i < 1000; ++i) {
      [sourceRects addObject:[LTRotatedRect
                              rectWithCenter:CGPointMake([random randomDoubleBetweenMin:0 max:10],
                                                         [random randomDoubleBetweenMin:0 max:10])
                              size:CGSizeMakeUniform([random randomDoubleBetweenMin:0 max:10])
                              angle:[random randomDoubleBetweenMin:0 max:2 * M_PI]]];
    }
  });
  
  it(@"should return an empty array if the input is an empty array", ^{
    expect([effect dynamicRectsFromRects:@[]].count).to.equal(0);
  });
  
  it(@"should return the same rects when sizeJitter, angleJitter, roundnessJitter are all 0", ^{
    effect.sizeJitter = 0;
    effect.angleJitter = 0;
    effect.roundnessJitter = 0;
    dynamicRects = [effect dynamicRectsFromRects:sourceRects];
    expect(dynamicRects.count).to.equal(sourceRects.count);
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      expect(dynamicRects[i]).to.equal(sourceRects[i]);
    }
  });
  
  it(@"should return dynamic rects according to the sizeJitter property", ^{
    effect.sizeJitter = 1;
    effect.angleJitter = 0;
    effect.roundnessJitter = 0;
    dynamicRects = [effect dynamicRectsFromRects:sourceRects];
    expect(dynamicRects.count).to.equal(sourceRects.count);
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      LTRotatedRect *sourceRect = sourceRects[i];
      LTRotatedRect *dynamicRect = dynamicRects[i];
      expect(CGPointDistance(dynamicRect.center, sourceRect.center)).to.beLessThan(1e-4);
      expect(dynamicRect.angle).to.equal(sourceRect.angle);
      expect(dynamicRect.rect.size).notTo.equal(sourceRect.rect.size);
      expect(dynamicRect.rect.size.width / dynamicRect.rect.size.height)
          .to.equal(sourceRect.rect.size.width / sourceRect.rect.size.height);
      expect(dynamicRect.rect.size.width).to.beLessThanOrEqualTo(sourceRect.rect.size.width);
      expect(dynamicRect.rect.size.height).to.beLessThanOrEqualTo(sourceRect.rect.size.height);
    }
  });
  
  it(@"should return dynamic rects according to the minimumDiameter property", ^{
    effect.sizeJitter = 1;
    effect.angleJitter = 0;
    effect.roundnessJitter = 0;
    
    effect.minimumDiameter = 1;
    dynamicRects = [effect dynamicRectsFromRects:sourceRects];
    expect(dynamicRects.count).to.equal(sourceRects.count);
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      expect(dynamicRects[i]).to.equal(sourceRects[i]);
    }
    
    effect.minimumDiameter = 0.9;
    dynamicRects = [effect dynamicRectsFromRects:sourceRects];
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      LTRotatedRect *sourceRect = sourceRects[i];
      LTRotatedRect *dynamicRect = dynamicRects[i];
      CGSize sourceSize = sourceRect.rect.size;
      CGSize dynamicSize = dynamicRect.rect.size;
      CGSize minimumSize = sourceSize * effect.minimumDiameter;
      
      expect(CGPointDistance(dynamicRect.center, sourceRect.center)).to.beLessThan(1e-4);
      expect(dynamicRect.angle).to.equal(sourceRect.angle);
      expect(dynamicSize).notTo.equal(sourceSize);
      expect(dynamicSize.width).to.beGreaterThanOrEqualTo(minimumSize.width);
      expect(dynamicSize.height).to.beGreaterThanOrEqualTo(minimumSize.height);
    }
  });

  it(@"should return dynamic rects according to the angleJitter property", ^{
    effect.sizeJitter = 0;
    effect.angleJitter = 0.1;
    effect.roundnessJitter = 0;
    dynamicRects = [effect dynamicRectsFromRects:sourceRects];
    expect(dynamicRects.count).to.equal(sourceRects.count);
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      LTRotatedRect *sourceRect = sourceRects[i];
      LTRotatedRect *dynamicRect = dynamicRects[i];
      CGFloat angleDiff = std::abs(dynamicRect.angle - sourceRect.angle);
      angleDiff = MIN(angleDiff, std::abs(2 * M_PI - angleDiff));
      expect(dynamicRect.center).to.equal(sourceRect.center);
      expect(dynamicRect.angle).notTo.equal(sourceRect.angle);
      expect(dynamicRect.rect.size).to.equal(sourceRect.rect.size);
      expect(angleDiff).to.beLessThanOrEqualTo(M_PI * effect.angleJitter);
    }
  });
  
  it(@"should return dynamic rects according to the roundnessJitter property", ^{
    effect.sizeJitter = 0;
    effect.angleJitter = 0;
    effect.roundnessJitter = 1;
    dynamicRects = [effect dynamicRectsFromRects:sourceRects];
    expect(dynamicRects.count).to.equal(sourceRects.count);
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      LTRotatedRect *sourceRect = sourceRects[i];
      LTRotatedRect *dynamicRect = dynamicRects[i];
      expect(CGPointDistance(dynamicRect.center, sourceRect.center)).to.beLessThan(1e-4);
      expect(dynamicRect.angle).to.equal(sourceRect.angle);
      expect(dynamicRect.rect.size.width).to.equal(sourceRect.rect.size.width);
      expect(dynamicRect.rect.size.height).to.beLessThan(sourceRect.rect.size.height);
    }
  });
  
  it(@"should return dynamic rects according to the minimumRoundness property", ^{
    effect.sizeJitter = 0;
    effect.angleJitter = 0;
    effect.roundnessJitter = 1;
    
    effect.minimumRoundness = 1;
    dynamicRects = [effect dynamicRectsFromRects:sourceRects];
    expect(dynamicRects.count).to.equal(sourceRects.count);
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      expect(dynamicRects[i]).to.equal(sourceRects[i]);
    }
    
    effect.minimumRoundness = 0.9;
    dynamicRects = [effect dynamicRectsFromRects:sourceRects];
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      LTRotatedRect *sourceRect = sourceRects[i];
      LTRotatedRect *dynamicRect = dynamicRects[i];
      CGFloat minimumHeight = sourceRect.rect.size.height * effect.minimumRoundness;
      expect(CGPointDistance(dynamicRect.center, sourceRect.center)).to.beLessThan(1e-4);
      expect(dynamicRect.angle).to.equal(sourceRect.angle);
      expect(dynamicRect.rect.size.width).to.equal(sourceRect.rect.size.width);
      expect(dynamicRect.rect.size.height).to.beLessThan(sourceRect.rect.size.height);
      expect(dynamicRect.rect.size.height).to.beGreaterThan(minimumHeight);
    }
  });
});

LTSpecEnd
