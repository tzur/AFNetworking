// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRandom.h"

#import <random>

@interface LTRandom () {
  /// Random engine used by the instance.
  std::default_random_engine _engine;
  
  /// Uniform distribution of double values in range [0,1].
  std::uniform_real_distribution<double> _uniformDouble;
}

/// Seed used to initialize the random engine.
@property (nonatomic) NSUInteger seed;

@end

@implementation LTRandom

- (instancetype)init {
  return [self initWithSeed:arc4random()];
}

- (instancetype)initWithSeed:(NSUInteger)seed {
  if (self = [super init]) {
    self.seed = seed;
    [self reset];
    _uniformDouble = std::uniform_real_distribution<double>(0, 1);
  }
  return self;
}

- (void)reset {
  std::default_random_engine::result_type seed =
      self.seed % std::numeric_limits<std::default_random_engine::result_type>::max();
  _engine = std::default_random_engine(seed);
}

- (double)randomDouble {
  return _uniformDouble(_engine);
}

- (double)randomDoubleBetweenMin:(double)min max:(double)max {
  LTParameterAssert(min <= max);
  std::uniform_real_distribution<double> uniform(min, max);
  return uniform(_engine);
}

- (NSInteger)randomIntegerBetweenMin:(NSInteger)min max:(NSInteger)max {
  LTParameterAssert(min <= max);
  std::uniform_int_distribution<NSInteger> uniform(min, max);
  return uniform(_engine);
}

- (NSUInteger)randomUnsignedIntegerBelow:(NSUInteger)max {
  LTParameterAssert(max > 0);
  std::uniform_int_distribution<NSInteger> uniform(0, max-1);
  return uniform(_engine);
}

@end
