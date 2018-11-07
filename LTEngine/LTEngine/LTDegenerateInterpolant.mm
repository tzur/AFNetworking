// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTDegenerateInterpolant.h"

#import "LTInterpolatableObject.h"

@interface LTPolynomialInterpolant ()
@property (strong, nonatomic) NSArray *keyFrames;
@end

@implementation LTDegenerateInterpolant

- (NSDictionary *)calculateCoefficientsForKeyFrames:(NSArray __unused *)keyFrames {
  return nil;
}

- (CGFloat)valueOfPropertyNamed:(NSString *)name atKey:(CGFloat __unused)key {
  return [[self.keyFrames.firstObject propertiesToInterpolate] containsObject:name] ?
      [[self.keyFrames.firstObject valueForKey:name] CGFloatValue] : 0;
}

- (std::vector<CGFloat>)valuesOfPropertyNamed:(NSString *)name
                                       atKeys:(const std::vector<CGFloat> &)keys {
  CGFloat value = [[self.keyFrames.firstObject propertiesToInterpolate] containsObject:name] ?
      [[self.keyFrames.firstObject valueForKey:name] doubleValue] : 0;
  return std::vector<CGFloat>(keys.size(), value);
}

+ (NSUInteger)expectedKeyFrames {
  return 1;
}

+ (NSRange)rangeOfIntervalInWindow {
  return NSMakeRange(0, 1);
}

@end

@implementation LTDegenerateInterpolantFactory

- (LTPolynomialInterpolant *)interpolantWithKeyFrames:(NSArray *)keyFrames {
  return [[LTDegenerateInterpolant alloc] initWithKeyFrames:keyFrames];
}

- (NSUInteger)expectedKeyFrames {
  return [LTDegenerateInterpolant expectedKeyFrames];
}

- (NSRange)rangeOfIntervalInWindow {
  return [LTDegenerateInterpolant rangeOfIntervalInWindow];
}

@end
