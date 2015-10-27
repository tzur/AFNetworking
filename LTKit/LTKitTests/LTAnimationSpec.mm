// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTAnimation.h"

static const CGFloat kTargetFps = 60;
static const CGFloat kTimeout = 5.0 / kTargetFps;

SpecBegin(LTAnimation)

__block NSTimeInterval defaultTimeout;

beforeAll(^{
  defaultTimeout = Expecta.asynchronousTestTimeout;
});

beforeEach(^{
  Expecta.asynchronousTestTimeout = kTimeout;
  [LTAnimation reset];
});

afterAll(^{
  Expecta.asynchronousTestTimeout = defaultTimeout;
});

xcontext(@"animations", ^{
  it(@"running a single animation", ^{
    __block NSUInteger counter = 0;
    
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval, CFTimeInterval) {
      ++counter;
      return YES;
    }];
    expect(counter).will.equal(kTimeout * kTargetFps);
  });
  
  it(@"running two concurrent animations", ^{
    __block NSUInteger counterCombined = 0;
    __block NSUInteger counter1 = 0;
    __block NSUInteger counter2 = 0;
    const NSUInteger targetFrames = (NSUInteger)(kTimeout * kTargetFps);
    
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval, CFTimeInterval) {
      ++counter1;
      return (++counterCombined < 2 * targetFrames);
    }];
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval, CFTimeInterval) {
      ++counter2;
      return (++counterCombined < 2 * targetFrames);
    }];
    
    expect(counter1).will.equal(targetFrames);
    expect(counter2).will.equal(targetFrames);
    expect(counterCombined).will.equal(2 * targetFrames);
  });
  
  it(@"stopping a running animation", ^{
    __block BOOL didExecute = NO;
    LTAnimation *animation = [LTAnimation animationWithBlock:^BOOL(CFTimeInterval, CFTimeInterval) {
      didExecute = YES;
      return YES;
    }];
    
    [animation stopAnimation];
    expect([LTAnimation isAnyAnimationRunning]).will.beFalsy();
    usleep((useconds_t)(kTimeout * USEC_PER_SEC));
    expect(didExecute).to.beFalsy();
  });
  
  it(@"stopping a running animation from another animation", ^{
    __block NSUInteger counter = 0;
    __block LTAnimation *animation = [LTAnimation animationWithBlock:
                                      ^BOOL(CFTimeInterval, CFTimeInterval) {
      ++counter;
      return YES;
    }];
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval, CFTimeInterval) {
      [animation stopAnimation];
      return NO;
    }];

    expect([LTAnimation isAnyAnimationRunning]).will.beFalsy();
    usleep((useconds_t)(kTimeout * USEC_PER_SEC));
    expect(counter).to.beLessThanOrEqualTo(1);
  });
});

xcontext(@"properties", ^{
  it(@"isAnimating property", ^{
    LTAnimation *animation = [LTAnimation animationWithBlock:
                              ^BOOL(CFTimeInterval, CFTimeInterval totalAnimationTime) {
      return totalAnimationTime < 0.5 * kTimeout;
    }];
    expect(animation.isAnimating).to.beTruthy();
    expect(animation.isAnimating).will.beFalsy();
  });
});

SpecEnd
