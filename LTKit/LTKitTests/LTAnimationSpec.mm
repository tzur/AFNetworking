// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTAnimation.h"

@interface LTAnimation ()

+ (void)reset;

@end

static const CGFloat kTargetFps = 60;
static const CGFloat kTimeout = 5.0 / kTargetFps;
static const double kUSecInSec = 1000000;

SpecBegin(LTAnimation)

beforeEach(^{
  Expecta.asynchronousTestTimeout = kTimeout;
  [LTAnimation reset];
});

xcontext(@"animations", ^{
  it(@"running a single animation", ^{
    __block NSUInteger counter = 0;
    
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                          CFTimeInterval __unused totalAnimationTime) {
      ++counter;
      return YES;
    }];
    expect(counter).will.equal(kTimeout * kTargetFps);
  });
  
  it(@"running two concurrent animations", ^{
    __block NSUInteger counterCombined = 0;
    __block NSUInteger counter1 = 0;
    __block NSUInteger counter2 = 0;
    const NSUInteger targetFrames = kTimeout * kTargetFps;
    
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                          CFTimeInterval __unused totalAnimationTime) {
      ++counter1;
      return (++counterCombined < 2 * targetFrames);
    }];
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                          CFTimeInterval __unused totalAnimationTime) {
      ++counter2;
      return (++counterCombined < 2 * targetFrames);
    }];
    
    expect(counter1).will.equal(targetFrames);
    expect(counter2).will.equal(targetFrames);
    expect(counterCombined).will.equal(2 * targetFrames);
  });
  
  it(@"stopping a running animation", ^{
    __block BOOL didExecute = NO;
    LTAnimation *animation = [LTAnimation animationWithBlock:
                              ^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                    CFTimeInterval __unused totalAnimationTime) {
      didExecute = YES;
      return YES;
    }];
    
    [animation stopAnimation];
    expect([LTAnimation isAnyAnimationRunning]).will.beFalsy();
    usleep(kTimeout * kUSecInSec);
    expect(didExecute).to.beFalsy();
  });
  
  it(@"stopping a running animation from another animation", ^{
    __block NSUInteger counter = 0;
    __block LTAnimation *animation = [LTAnimation animationWithBlock:
                                      ^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                            CFTimeInterval __unused totalAnimationTime) {
      ++counter;
      return YES;
    }];
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                          CFTimeInterval __unused totalAnimationTime) {
      [animation stopAnimation];
      return NO;
    }];

    expect([LTAnimation isAnyAnimationRunning]).will.beFalsy();
    usleep(kTimeout * kUSecInSec);
    expect(counter).to.equal(1);
  });
});

xcontext(@"properties", ^{
  it(@"isAnimating property", ^{
    LTAnimation *animation = [LTAnimation animationWithBlock:
                              ^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                    CFTimeInterval __unused totalAnimationTime) {
      return totalAnimationTime < 0.5 * kTimeout;
    }];
    expect(animation.isAnimating).to.beTruthy();
    expect(animation.isAnimating).will.beFalsy();
  });
});

SpecEnd
