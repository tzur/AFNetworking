// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTAnimation.h"

@interface LTAnimation ()

+ (void)reset;

@end

SpecBegin(LTAnimation)

beforeEach(^{
  [LTAnimation reset];
});

context(@"animations", ^{
  const NSUInteger kTargetFps = 60;

  it(@"running a single animation", ^{
    __block NSUInteger counter = 0;
    __block CFTimeInterval totalTime;
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                          CFTimeInterval totalAnimationTime) {
      totalTime = totalAnimationTime;
      return (++counter < kTargetFps);
    }];
    expect(counter).will.equal(kTargetFps);
    expect(1.0 - totalTime).will.beCloseToWithin(0, 0.05);
    expect([LTAnimation isAnyAnimationRunning]).will.beFalsy();
  });
  
  it(@"running two concurrent animations", ^{
    __block NSUInteger counterCombined = 0;
    __block NSUInteger counter1 = 0;
    __block NSUInteger counter2 = 0;
    
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                          CFTimeInterval __unused totalAnimationTime) {
      ++counter1;
      return (++counterCombined < 2 * kTargetFps);
    }];
    [LTAnimation animationWithBlock:^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                          CFTimeInterval __unused totalAnimationTime) {
      ++counter2;
      return (++counterCombined < 2 * kTargetFps);
    }];
    
    expect(counter1).will.equal(kTargetFps);
    expect(counter2).will.equal(kTargetFps);
    expect(counterCombined).will.equal(2 * kTargetFps);
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
    usleep(100000);
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
    usleep(100000);
    expect(counter).to.equal(1);
  });
});

context(@"properties", ^{
  it(@"isAnimating property", ^{
    LTAnimation *animation = [LTAnimation animationWithBlock:
                              ^BOOL(CFTimeInterval __unused timeSinceLastFrame,
                                    CFTimeInterval __unused totalAnimationTime) {
      return totalAnimationTime < 0.5 * [Expecta asynchronousTestTimeout];
    }];
    expect(animation.isAnimating).to.beTruthy();
    expect(animation.isAnimating).will.beFalsy();
  });
});

SpecEnd
