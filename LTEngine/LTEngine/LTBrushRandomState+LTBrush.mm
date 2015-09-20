// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBrushRandomState+LTBrush.h"

#import "LTBrush.h"
#import "LTKeyPathCoding.h"
#import "LTRandom.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTBrushRandomState (LTBrush)

#pragma mark -
#pragma mark Factory methods
#pragma mark -

+ (instancetype)randomStateWithSeed:(NSUInteger)seed forBrush:(LTBrush *)brush {
  LTBrushRandomState *brushRandomState = brush.randomState;
  LTRandomState *randomState = [[LTRandom alloc] initWithSeed:seed].engineState;
  NSMutableDictionary *states = [brushRandomState.states mutableCopy];
  [self setValuesOfDictionary:states toValue:randomState];
  return [[LTBrushRandomState alloc] initWithStates:states];
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

+ (void)setValuesOfDictionary:(NSMutableDictionary *)dictionary toValue:(id)value {
  NSArray *keys = dictionary.allKeys;
  for (id key in keys) {
    [dictionary setObject:value forKey:key];
  }
}

@end

NS_ASSUME_NONNULL_END
