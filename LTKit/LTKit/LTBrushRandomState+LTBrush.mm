// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBrushRandomState+LTBrush.h"

#import "LTBrush.h"
#import "LTKeyPathCoding.h"
#import "LTRandom.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTBrushRandomState (LTBrush)

+ (instancetype)randomStateWithSeed:(NSUInteger)seed forBrush:(LTBrush *)brush {
  LTBrushRandomState *brushRandomState = brush.randomState;
  LTRandomState *randomState = [[LTRandom alloc] initWithSeed:seed].engineState;
  NSMutableDictionary *states = [brushRandomState.states mutableCopy];
  for (NSString *key in states) {
    [states setValue:randomState forKey:key];
  }
  NSDictionary *result = @{@instanceKeypath(LTBrushRandomState, states): [states copy]};
  return [LTBrushRandomState modelWithDictionary:result error:nil];
}

@end

NS_ASSUME_NONNULL_END
