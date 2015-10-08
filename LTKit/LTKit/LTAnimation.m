// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTAnimation.h"

NS_ASSUME_NONNULL_BEGIN

/// Singleton instance used to trigger all active animations using a single CADisplayLink. This is
/// done since creating a new display link while another is already active might hog it a bit,
/// causing undesired lags.
@interface LTAnimationManager : NSObject

/// Returns the singleton instance.
+ (instancetype)sharedInstance;

/// Resets the animation manager, for testing purposes.
+ (void)reset;

/// Adds the given animation to the list of running animations.
- (void)addAnimation:(LTAnimation *)animation;

/// Display link used to trigger all the animations.
@property (strong, nonatomic) CADisplayLink *displayLink;

/// Holds all currently running animations.
@property (strong, nonatomic) NSMutableArray *animations;

@end

@interface LTAnimation ()

/// Last timestamp of rendered frame.
@property (nonatomic) CFTimeInterval lastFrameTime;

/// Total animation time so far, in seconds.
@property (nonatomic) CGFloat animationTime;

/// Animation block to call each frame.
@property (copy, nonatomic, nullable) LTAnimationBlock block;

/// Indicates if the animation is currently running.
@property (nonatomic) BOOL isAnimating;

@end

#pragma mark -
#pragma mark LTAnimation
#pragma mark -

@implementation LTAnimation

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithAnimationBlock:(LTAnimationBlock)block {
  if (self = [super init]) {
    self.block = block;
    self.isAnimating = YES;
    [[LTAnimationManager sharedInstance] addAnimation:self];
  }
  return self;
}

#pragma mark -
#pragma mark Class Methods
#pragma mark -

+ (instancetype)animationWithBlock:(LTAnimationBlock)block {
  return [[LTAnimation alloc] initWithAnimationBlock:block];
}

+ (BOOL)isAnyAnimationRunning {
  return ![LTAnimationManager sharedInstance].displayLink.paused;
}

+ (void)reset {
  [LTAnimationManager reset];
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (void)stopAnimation {
  self.isAnimating = NO;
  self.block = nil;
}

@end

#pragma mark -
#pragma mark LTAnimationManager
#pragma mark -

@implementation LTAnimationManager

static LTAnimationManager *instance = nil;

#pragma mark -
#pragma mark Class methods
#pragma mark -

+ (instancetype)sharedInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LTAnimationManager alloc] init];
  });
  
  return instance;
}

+ (void)reset {
  // Invalidate is called to make sure this happens before allocating a new manager (and a new
  // display link), as the ARC might call the previous manager's dealloc later on (even if we set it
  // to nil).
  [instance.displayLink invalidate];
  instance = [[LTAnimationManager alloc] init];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    // Allocate the animations array, and the display link used to trigger the animations.
    self.animations = [NSMutableArray array];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(animate:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink.paused = YES;
  }
  return self;
}

- (void)dealloc {
  [self.displayLink invalidate];
}

#pragma mark -
#pragma mark Animation handlers
#pragma mark -

- (void)animate:(CADisplayLink *)link {
  // Iterate over the current animations.
  NSMutableArray *completed = [NSMutableArray array];

  for (LTAnimation *animation in self.animations) {
    // Calculate and update the total animation time, and the time since the last frame.
    CFTimeInterval timeSinceLastFrame = 0;
    if (animation.lastFrameTime) {
      timeSinceLastFrame = [link timestamp] - animation.lastFrameTime;
      animation.animationTime += timeSinceLastFrame;
    }
    animation.lastFrameTime = [self.displayLink timestamp];
    
    // Run the animation block. If the animation isn't animating, or has no block, or if NO is
    // returned when running the block, the animation is completed, and should be removed from the
    // list. Note that this actually runs the animation block.
    if (!animation.block || !animation.isAnimating ||
        !animation.block(timeSinceLastFrame, animation.animationTime)) {
      [animation stopAnimation];
      [completed addObject:animation];
    }
  }
  
  // Remove all the completed animations, if there are no animations left, pause the display link.
  [self.animations removeObjectsInArray:completed];
  if (!self.animations.count) {
    link.paused = YES;
  }
}

- (void)addAnimation:(LTAnimation *)animation {
  // Animation can't appear more than once in the array.
  if (![self.animations containsObject:animation]) {
    [self.animations addObject:animation];
    self.displayLink.paused = NO;
  } else {
    LogWarning(@"Trying to add an existing LTAnimation to queue");
  }
}

@end

NS_ASSUME_NONNULL_END
