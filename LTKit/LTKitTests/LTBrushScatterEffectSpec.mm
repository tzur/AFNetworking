// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushScatterEffect.h"

#import "LTBrushEffectExamples.h"
#import "LTCGExtensions.h"
#import "LTRandom.h"
#import "LTRotatedRect.h"

LTSpecBegin(LTBrushScatterEffect)

itShouldBehaveLike(kLTBrushEffectSubclassExamples,
                   @{kLTBrushEffectClass: [LTBrushScatterEffect class]});

__block LTBrushScatterEffect *effect;

context(@"initialization", ^{
  it(@"should initialize with default initializer", ^{
    expect(^{
      effect = [[LTBrushScatterEffect alloc] init];
    }).notTo.raiseAny();
  });
});

context(@"properties", ^{  
  beforeEach(^{
    effect = [[LTBrushScatterEffect alloc] init];
  });
  
  it(@"should have default properties", ^{
    expect(effect.scatter).to.equal(0);
    expect(effect.count).to.equal(1);
    expect(effect.countJitter).to.equal(0);
  });
  
  it(@"should set scatter", ^{
    CGFloat newValue = 2;
    expect(effect.scatter).notTo.equal(newValue);
    effect.scatter = newValue;
    expect(effect.scatter).to.equal(newValue);
  });
  
  it(@"should set count", ^{
    NSUInteger newValue = 2;
    expect(effect.count).notTo.equal(newValue);
    effect.count = newValue;
    expect(effect.count).to.equal(newValue);
  });
  
  it(@"should set countJitter", ^{
    CGFloat newValue = 0.5;
    expect(effect.countJitter).notTo.equal(newValue);
    effect.countJitter = newValue;
    expect(effect.countJitter).to.equal(newValue);
  });
});

context(@"effect", ^{
  __block NSArray *sourceRects;
  __block NSArray *scatteredRects;
  
  beforeEach(^{
    effect = [[LTBrushScatterEffect alloc] init];
    sourceRects = @[
        [LTRotatedRect rectWithCenter:CGPointMake(0, 0) size:CGSizeMakeUniform(1) angle:0],
        [LTRotatedRect rectWithCenter:CGPointMake(1, 1) size:CGSizeMakeUniform(2) angle:M_PI_4],
        [LTRotatedRect rectWithCenter:CGPointMake(2, 2) size:CGSizeMakeUniform(3) angle:M_PI_2],
    ];
  });
  
  it(@"should return an empty array if the input is an empty array", ^{
    expect([effect scatteredRectsFromRects:@[]].count).to.equal(0);
  });
  
  it(@"should return the same rects when scatter is 0, count is 1, and countJitter is 0", ^{
    effect.count = 1;
    scatteredRects = [effect scatteredRectsFromRects:sourceRects];
    expect(scatteredRects.count).to.equal(sourceRects.count);
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      expect(scatteredRects[i]).to.equal(sourceRects[i]);
    }
  });
  
  it(@"should return scattered rects according to the scatter property", ^{
    effect.scatter = 1;
    effect.count = 1;
    scatteredRects = [effect scatteredRectsFromRects:sourceRects];
    expect(scatteredRects.count).to.equal(sourceRects.count);
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      LTRotatedRect *sourceRect = sourceRects[i];
      LTRotatedRect *scatteredRect = scatteredRects[i];
      expect(scatteredRect.center).notTo.equal(sourceRect.center);
      expect(scatteredRect.rect.size).to.equal(sourceRect.rect.size);
      expect(scatteredRect.angle).to.equal(sourceRect.angle);
      expect(std::abs(scatteredRect.center.x - sourceRect.center.x))
          .to.beLessThanOrEqualTo(sourceRect.rect.size.width);
      expect(std::abs(scatteredRect.center.y - sourceRect.center.y))
          .to.beLessThanOrEqualTo(sourceRect.rect.size.height);
    }
  });
  
  it(@"should return scattered rects according to the count property", ^{
    effect.count = 10;
    scatteredRects = [effect scatteredRectsFromRects:sourceRects];
    expect(scatteredRects.count).to.equal(effect.count * sourceRects.count);
    for (NSUInteger i = 0; i < sourceRects.count; ++i) {
      for (NSUInteger j = 0; j < effect.count; ++j) {
        expect(scatteredRects[i * effect.count + j]).to.equal(sourceRects[i]);
      }
    }
  });
  
  it(@"should return scattered rects according to the countJitter property", ^{
    effect.count = 10;
    NSMutableArray *manyRects = [NSMutableArray array];
    for (NSUInteger i = 0; i < 1000; ++i) {
      [manyRects addObject:sourceRects[0]];
    }
    NSUInteger targetCount = manyRects.count * effect.count;
    
    effect.countJitter = 0.5;
    scatteredRects = [effect scatteredRectsFromRects:manyRects];
    expect(scatteredRects.count).notTo.equal(targetCount);
    expect(scatteredRects.count).to.beInTheRangeOf(targetCount * (1 - effect.countJitter),
                                                   targetCount * (1 + effect.countJitter));
    
    effect.countJitter = 1;
    scatteredRects = [effect scatteredRectsFromRects:manyRects];
    expect(scatteredRects.count).notTo.equal(targetCount);
    expect(scatteredRects.count).to.beInTheRangeOf(targetCount * (1 - effect.countJitter),
                                                   targetCount * (1 + effect.countJitter));
    
    effect.countJitter = 0;
    scatteredRects = [effect scatteredRectsFromRects:manyRects];
    expect(scatteredRects.count).to.equal(targetCount);
  });
});

LTSpecEnd
