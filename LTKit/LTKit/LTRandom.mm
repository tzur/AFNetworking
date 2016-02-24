// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRandom.h"

#import <random>
#import <sstream>

NS_ASSUME_NONNULL_BEGIN

@interface LTRandomState ()

/// Initializes with a randomly generated state.
- (instancetype)init;

/// Initializes with a state generated using the given \c seed.
- (instancetype)initWithSeed:(NSUInteger)seed;

/// Initializes with the given \c state.
- (instancetype)initWithState:(NSString *)state NS_DESIGNATED_INITIALIZER;

/// State represented by this object.
@property (readonly, nonatomic) NSString *engineState;

@end

@implementation LTRandomState

- (instancetype)init {
  return [self initWithSeed:arc4random()];
}

- (instancetype)initWithSeed:(NSUInteger)seed {
  std::default_random_engine::result_type validSeed =
      seed % std::numeric_limits<std::default_random_engine::result_type>::max();
  auto engine = std::default_random_engine(validSeed);

  std::stringstream stream;
  stream << engine;
  NSString *state = [NSString stringWithUTF8String:stream.str().data()];
  return [self initWithState:state];
}

- (instancetype)initWithState:(NSString *)state {
  LTParameterAssert(state);

  if (self = [super init]) {
    _engineState = state;
  }
  return self;
}

- (BOOL)isEqual:(LTRandomState *)object {
  if (object == self) {
    return YES;
  }

  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.engineState isEqual:object.engineState];
}

- (NSUInteger)hash {
  return self.engineState.hash;
}

@end

@interface LTRandom () {
  /// Random engine used by the instance.
  std::default_random_engine _engine;
  
  /// Uniform distribution of double values in range [0,1].
  std::uniform_real_distribution<double> _uniformDouble;
}

/// Seed used to initialize the random engine.
@property (strong, nonatomic) LTRandomState *initialState;

@end

@implementation LTRandom

- (instancetype)init {
  return [self initWithState:[[LTRandomState alloc] init]];
}

- (instancetype)initWithSeed:(NSUInteger)seed {
  return [self initWithState:[[LTRandomState alloc] initWithSeed:seed]];
}

- (instancetype)initWithState:(LTRandomState *)state {
  if (self = [super init]) {
    _initialState = state;
    _uniformDouble = std::uniform_real_distribution<double>(0, 1);
    [self resetToState:state];
  }
  return self;
}

- (void)reset {
  [self resetToState:self.initialState];
}

- (void)resetToState:(LTRandomState *)state {
  LTParameterAssert(state.engineState);
  std::stringstream stream(std::string(state.engineState.UTF8String));
  stream >> _engine;
}

- (LTRandomState *)engineState {
  std::stringstream stream;
  stream << _engine;
  NSString *state = [NSString stringWithUTF8String:stream.str().data()];
  return [[LTRandomState alloc] initWithState:state];
}

- (double)randomDouble {
  return _uniformDouble(_engine);
}

- (double)randomDoubleBetweenMin:(double)min max:(double)max {
  LTParameterAssert(min <= max);
  std::uniform_real_distribution<double> uniform(min, max);
  return uniform(_engine);
}

- (int)randomIntegerBetweenMin:(int)min max:(int)max {
  LTParameterAssert(min <= max);
  std::uniform_int_distribution<int> uniform(min, max);
  return uniform(_engine);
}

- (uint)randomUnsignedIntegerBelow:(uint)max {
  LTParameterAssert(max > 0);
  std::uniform_int_distribution<uint> uniform(0, max - 1);
  return uniform(_engine);
}

@end

NS_ASSUME_NONNULL_END
