// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRandom.h"

/// Returns the mean value of all elements in the given container.
template <typename Container>
static double LTMean(const Container &container) {
  return container.size() > 0 ?
  std::accumulate(container.begin(), container.end(), 0.0) / (double)container.size() : 0.0;
}

/// Returns the variance of all elements in the given container.
template <typename Container>
static double LTVariance(const Container &container) {
  double mean = LTMean(container);
  double squareSum = std::inner_product(container.begin(), container.end(), container.begin(), 0.0);
  return squareSum / container.size() - mean * mean;
}

SpecBegin(LTRandom)

__block LTRandom *random;

static const NSUInteger kTestingSeed = 1234;
static const NSUInteger kNumberOfRolls = 10000;

context(@"initialization", ^{
  it(@"should initialize with a random seed using the default initializer", ^{
    random = [[LTRandom alloc] init];
    LTRandom *otherRandom = [[LTRandom alloc] init];
    expect(random.seed).notTo.equal(otherRandom.seed);
  });
  
  it(@"should initialize with a specific seed", ^{
    random = [[LTRandom alloc] initWithSeed:kTestingSeed];
    expect(random.seed).to.equal(kTestingSeed);
  });
});

context(@"random", ^{
  beforeEach(^{
    random = [[LTRandom alloc] initWithSeed:kTestingSeed];
  });
  
  it(@"should generate uniform random doubles in [0,1]", ^{
    std::vector<double> values;
    for (NSUInteger i = 0; i < kNumberOfRolls; ++i) {
      values.push_back([random randomDouble]);
    }
    expect(*std::min_element(values.begin(), values.end())).to.beInTheRangeOf(0, 1);
    expect(*std::max_element(values.begin(), values.end())).to.beInTheRangeOf(0, 1);
    expect(LTMean(values)).to.beCloseToWithin(0.5, 1e-2);
    expect(LTVariance(values)).to.beCloseToWithin(1.0 / 12.0, 1e-2);
  });
  
  it(@"should generate uniform random doubles in a given range", ^{
    std::vector<double> values;
    for (NSUInteger i = 0; i < kNumberOfRolls; ++i) {
      values.push_back([random randomDoubleBetweenMin:-1 max:1]);
    }
    expect(*std::min_element(values.begin(), values.end())).to.beInTheRangeOf(-1, 1);
    expect(*std::max_element(values.begin(), values.end())).to.beInTheRangeOf(-1, 1);
    expect(LTMean(values)).to.beCloseToWithin(0, 1e-2);
    expect(LTVariance(values)).to.beCloseToWithin(4.0 / 12.0, 1e-2);
  });
  
  it(@"should generate uniform random integers in a given range", ^{
    const NSInteger a = -10;
    const NSInteger b = 10;
    std::vector<NSInteger> values;
    for (NSUInteger i = 0; i < kNumberOfRolls; ++i) {
      values.push_back([random randomIntegerBetweenMin:a max:b]);
    }
    expect(*std::min_element(values.begin(), values.end())).to.beInTheRangeOf(a, b);
    expect(*std::max_element(values.begin(), values.end())).to.beInTheRangeOf(a, b);
    expect(LTMean(values)).to.beCloseToWithin(0.5 * (a + b), 1e-1);
    expect(LTVariance(values)).to.beCloseToWithin(((b - a + 1) * (b - a + 1) - 1) / 12.0, 1);
  });
  
  it(@"should generate uniform random unsigned integers in a given range", ^{
    const NSUInteger max = 21;
    std::vector<NSUInteger> values;
    for (NSUInteger i = 0; i < kNumberOfRolls; ++i) {
      values.push_back([random randomUnsignedIntegerBelow:max]);
    }
    expect(*std::min_element(values.begin(), values.end())).to.beInTheRangeOf(0, max - 1);
    expect(*std::max_element(values.begin(), values.end())).to.beInTheRangeOf(0, max - 1);
    expect(LTMean(values)).to.beCloseToWithin(0.5 * (max - 1), 1e-1);
    expect(LTVariance(values)).to.beCloseToWithin((max * max - 1) / 12.0, 1);
  });
  
  it(@"should generate identical random sequence after call to reset", ^{
    std::vector<double> first, second;
    for (NSUInteger i = 0; i < kNumberOfRolls; ++i) {
      first.push_back([random randomDouble]);
    }
    [random reset];
    for (NSUInteger i = 0; i < kNumberOfRolls; ++i) {
      second.push_back([random randomDouble]);
    }
#pragma push_macro("equal")
#undef equal
    expect(std::equal(first.begin(), first.end(), second.begin())).to.beTruthy();
#pragma pop_macro("equal")
  });

  it(@"should generate identical random sequence after calling reset to state", ^{
    LTRandom *random1 = [[LTRandom alloc] init];
    for (NSInteger i = 0; i < 5; ++i) {
      [random1 randomDouble];
    }

    LTRandom *random2 = [[LTRandom alloc] init];
    for (NSInteger i = 0; i < 11; ++i) {
      [random2 randomDouble];
    }

    [random2 resetToState:random1.engineState];
    std::vector<double> first, second;
    for (NSUInteger i = 0; i < kNumberOfRolls; ++i) {
      first.push_back([random1 randomDouble]);
      second.push_back([random2 randomDouble]);
    }

#pragma push_macro("equal")
#undef equal
    expect(std::equal(first.begin(), first.end(), second.begin())).to.beTruthy();
#pragma pop_macro("equal")
  });

  it(@"should generate two equal engine states", ^{
    LTRandom *random1 = [[LTRandom alloc] init];
    for (NSInteger i = 0; i < 5; ++i) {
      [random1 randomDouble];
    }

    LTRandom *random2 = [[LTRandom alloc] init];
    [random2 resetToState:random1.engineState];

    expect(random1.engineState).to.equal(random2.engineState);
  });
  
  it(@"should generate identical random sequence when using same seed", ^{
    random = [[LTRandom alloc] init];
    LTRandom *otherRandom = [[LTRandom alloc] initWithSeed:random.seed];
    
    NSMutableArray *first = [NSMutableArray array];
    NSMutableArray *second = [NSMutableArray array];
    for (NSUInteger i = 0; i < kNumberOfRolls; ++i) {
      [first addObject:@([random randomDouble])];
      [second addObject:@([otherRandom randomDouble])];
      [first addObject:@([random randomUnsignedIntegerBelow:100])];
      [second addObject:@([otherRandom randomUnsignedIntegerBelow:100])];
    }
    
    for (NSUInteger i = 0; i < kNumberOfRolls; ++i) {
      expect(first[i]).to.equal(second[i]);
    }
  });
});

SpecEnd
