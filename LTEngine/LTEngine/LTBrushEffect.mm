// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrushEffect.h"

#import "LTRandom.h"

@interface LTBrushEffect ()

/// The random generator used by the effect.
@property (strong, nonatomic) LTRandom *random;

@end

@implementation LTBrushEffect

- (instancetype)init {
  return [self initWithRandom:[JSObjection defaultInjector][[LTRandom class]]];
}

- (instancetype)initWithRandom:(LTRandom *)random {
  LTParameterAssert(random);
  if (self = [super init]) {
    self.random = random;
  }
  return self;
}

@end
