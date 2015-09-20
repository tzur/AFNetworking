// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTDegenerateInterpolationRoutine.h"

#import "LTInterpolatedObject.h"

@interface LTInterpolationRoutine ()
@property (strong, nonatomic) NSArray *keyFrames;
@end

@implementation LTDegenerateInterpolationRoutine

- (NSDictionary *)calculateCoefficientsForKeyFrames:(NSArray __unused *)keyFrames {
  return nil;
}

- (NSNumber *)valueOfPropertyNamed:(NSString *)name atKey:(CGFloat __unused)key {
  return [[self.keyFrames.firstObject propertiesToInterpolate] containsObject:name] ?
      [self.keyFrames.firstObject valueForKey:name] : @(0);
}

- (CGFloats)valuesOfCGFloatPropertyNamed:(NSString *)name atKeys:(const CGFloats &)keys {
  CGFloat value = [[self.keyFrames.firstObject propertiesToInterpolate] containsObject:name] ?
      [[self.keyFrames.firstObject valueForKey:name] doubleValue] : 0;
  return CGFloats(keys.size(), value);
}

+ (NSUInteger)expectedKeyFrames {
  return 1;
}

+ (NSRange)rangeOfIntervalInWindow {
  return NSMakeRange(0, 1);
}

@end

@implementation LTDegenerateInterpolationRoutineFactory

- (LTInterpolationRoutine *)routineWithKeyFrames:(NSArray *)keyFrames {
  return [[LTDegenerateInterpolationRoutine alloc] initWithKeyFrames:keyFrames];
}

- (NSUInteger)expectedKeyFrames {
  return [LTDegenerateInterpolationRoutine expectedKeyFrames];
}

- (NSRange)rangeOfIntervalInWindow {
  return [LTDegenerateInterpolationRoutine rangeOfIntervalInWindow];
}

@end
