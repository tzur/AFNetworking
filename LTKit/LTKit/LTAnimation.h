// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Represents an animation which is performed using a timer (a CADisplayLink, to be more precise)
/// and not by CoreAnimation or UIKit. This is needed for openGL animations, or for animating views
/// or layers without using properties.
@interface LTAnimation : NSObject

/// Prototype of an animation block. This block is responsible for drawing the next frame of the
/// animation. Time since last frame and total animation time are given in seconds.
///
/// @return YES if the animation should continue after this frame.
typedef BOOL (^LTAnimationBlock)(CFTimeInterval timeSinceLastFrame,
                                 CFTimeInterval totalAnimationTime);

/// Starts an animation calling the given animation block on each frame.
+ (instancetype)animationWithBlock:(LTAnimationBlock)block;

/// returns YES if there's an animation that is currently running.
+ (BOOL)isAnyAnimationRunning;

/// Stops the animation.
- (void)stopAnimation;

/// returns YES if the animation is currently running.
@property (readonly, nonatomic) BOOL isAnimating;

@end

#pragma mark -
#pragma mark For Testing
#pragma mark -

@interface LTAnimation (ForTesting)

/// Stops all animations, and resets the animation manager class.
+ (void)reset;

@end
