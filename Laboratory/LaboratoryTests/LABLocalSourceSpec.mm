// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABLocalSource.h"

#import <LTKit/LTRandom.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <algorithm>

#import "LABExperimentsTokenProvider.h"
#import "LABFakeStorage.h"
#import "NSError+Laboratory.h"

static NSSet<LABVariant *> *LABGenerateVariants
    (NSDictionary<LABLocalExperiment *, LABLocalVariant *> *localVariants) {
  auto variants = [NSMutableSet set];
  [localVariants enumerateKeysAndObjectsUsingBlock:^(LABLocalExperiment *experiment,
                                                     LABLocalVariant *variant, BOOL *) {
    auto newVariant = [[LABVariant alloc] initWithName:variant.name assignments:variant.assignments
                                            experiment:experiment.name];
    [variants addObject:newVariant];
  }];
  return variants;
}

/// Enables the class be an \c NSDictionary key.
@interface LABLocalExperiment (NSCopying) <NSCopying>
@end

@implementation LABLocalExperiment (NSCopying)

- (instancetype)copyWithZone:(NSZone __unused *)zone {
  return self;
}

@end

/// Fake for the \c randomUnsignedIntegerWithWeights: method.
@interface LABFakeLTRandom : LTRandom

/// Initializes the random generator with a randomly generated state. Only
/// \c randomUnsignedIntegerWithWeights is faked.
- (instancetype)init;

- (instancetype)initWithSeed:(NSUInteger)seed NS_UNAVAILABLE;

- (instancetype)initWithState:(LTRandomState *)state NS_UNAVAILABLE;

/// Causes the \c randomUnsignedIntegerWithWeights: method to return the index of \c weight in the
/// the given \c weights vector. The order of the values in \c weights is ignored. Therefore
/// \c weight must be one of the values in \c weights.
/// For example, if the vector <tt>{1, 3}</tt> is given for \c weights, and \c weight is \c 3,
/// whenever \c randomUnsignedIntegerWithWeights: method is called with the vector <tt>{3, 1}</tt>,
/// the return value is 0. If \c randomUnsignedIntegerWithWeights: is called with the vector
/// <tt>{1, 3}</tt> the return value is 1.
///
/// \c weights must not contain duplicates.
///
/// Calling this method multiple times with the same \c weights (regardless of value order) will
/// override the previous call with the same \c weights. Only the last \c weight index will be
/// returned.
- (void)fakeRandomUnsignedIntegerWithWeights:(const std::vector<double> &)weights
                            andReturnIndexOf:(uint)weight;

/// Maps sets of weight to weight values that their indexes will be returned.
@property (strong, readonly, nonatomic)
    NSMutableDictionary<NSSet<NSNumber *> *, NSNumber *> *fakeWeights;

@end

@implementation LABFakeLTRandom

- (instancetype)init {
  if (self = [super init]) {
    _fakeWeights = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)fakeRandomUnsignedIntegerWithWeights:(const std::vector<double> &)weights
                            andReturnIndexOf:(uint)weight {
  LTParameterAssert(std::find(weights.cbegin(), weights.cend(), weight) != weights.end(),
                              @"Given weight is not in weights set");
  std::set<double> weightsSet(weights.cbegin(), weights.cend());
  LTParameterAssert(weights.size() == weightsSet.size(), "Weights contains a duplicate value");

  self.fakeWeights[[self setWithVector:weights]] = [NSNumber numberWithDouble:weight];
}

- (NSSet<NSNumber *> *)setWithVector:(const std::vector<double> &)set {
  NSMutableSet<NSNumber *> *managedSet = [NSMutableSet setWithCapacity:set.size()];
  for (auto const &weight: set) {
    [managedSet addObject:@(weight)];
  }
  return managedSet;
}

- (uint)randomUnsignedIntegerWithWeights:(const std::vector<double> &)weights {
  double weightToFind = self.fakeWeights[[self setWithVector:weights]].doubleValue;
  auto weightIter = std::find(weights.cbegin(), weights.cend(), weightToFind);
  return (uint)std::distance(weights.cbegin(), weightIter);
}

@end

SpecBegin(LABLocalSource)

__block NSDictionary<NSString *, id> *exp1assignment1;
__block NSDictionary<NSString *, id> *exp1assignment2;
__block LABLocalVariant *exp1variant1;
__block LABLocalVariant *exp1variant2;
__block NSArray<NSString *> *exp1Keys;

__block NSDictionary<NSString *, id> *exp2assignment1;
__block NSDictionary<NSString *, id> *exp2assignment2;
__block LABLocalVariant *exp2variant1;
__block LABLocalVariant *exp2variant2;
__block NSArray<NSString *> *exp2Keys;

__block NSDictionary<NSString *, id> *exp3assignment1;
__block NSDictionary<NSString *, id> *exp3assignment2;
__block LABLocalVariant *exp3variant1;
__block LABLocalVariant *exp3variant2;
__block NSArray<NSString *> *exp3Keys;

beforeEach(^{
  exp1assignment1 = @{@"bar": @"baz", @"zoo": @"kim"};
  exp1assignment2 = @{@"bar": @"boor", @"zoo": @"topia"};

  exp1variant1 = [[LABLocalVariant alloc] initWithName:@"exp1var1" probabilityWeight:2
                                           assignments:exp1assignment1];
  exp1variant2 = [[LABLocalVariant alloc] initWithName:@"exp1var2" probabilityWeight:1
                                           assignments:exp1assignment2];
  exp1Keys = @[@"bar", @"zoo"];

  exp2assignment1 = @{@"flip": @"flop", @"ping": @"pong"};
  exp2assignment2 = @{@"flip": @"bong", @"ping": @"zong"};

  exp2variant1 = [[LABLocalVariant alloc] initWithName:@"exp2var1" probabilityWeight:3
                                           assignments:exp2assignment1];
  exp2variant2 = [[LABLocalVariant alloc] initWithName:@"exp2var2" probabilityWeight:1
                                           assignments:exp2assignment2];
  exp2Keys = @[@"flip", @"ping"];

  exp3assignment1 = @{@"ding": @"dong", @"bling": @"blong"};
  exp3assignment2 = @{@"ding": @"dang", @"bling": @"blang"};

  exp3variant1 = [[LABLocalVariant alloc] initWithName:@"exp3var1" probabilityWeight:3
                                           assignments:exp3assignment1];
  exp3variant2 = [[LABLocalVariant alloc] initWithName:@"exp3var2" probabilityWeight:4
                                           assignments:exp3assignment2];
  exp3Keys = @[@"ding", @"bling"];
});

context(@"LABLocalExperiment", ^{
  it(@"should assert if there are zero variants", ^{
    expect(^{
      auto __unused experiment = [[LABLocalExperiment alloc]
                                  initWithName:@"exp_bar" keys:exp1Keys variants:@[]
                                  activeTokenRange:{0.2, 0.3}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should assert if activeTokenRange is not between 0 and 1", ^{
    expect(^{
      auto __unused experiment = [[LABLocalExperiment alloc]
                                  initWithName:@"exp_bar" keys:exp1Keys variants:@[exp1variant1]
                                  activeTokenRange:{0.2, 1.3}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should assert if activeTokenRange is not a valid range", ^{
    expect(^{
      auto __unused experiment = [[LABLocalExperiment alloc]
                                  initWithName:@"exp_bar" keys:exp1Keys variants:@[exp1variant1]
                                  activeTokenRange:{0.4, 0.2}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should assert if two variants have the same name", ^{
    auto variantWithSameName = [[LABLocalVariant alloc] initWithName:@"exp2var1" probabilityWeight:2
                                                         assignments:exp1assignment2];
    expect(^{
      auto __unused experiment =
          [[LABLocalExperiment alloc] initWithName:@"exp_bar" keys:exp1Keys
                                          variants:@[exp2variant1, variantWithSameName]
                                  activeTokenRange:{0.1, 0.2}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should assert if one variant's assignments doesn't have all keys", ^{
    auto variantMissingKey = [[LABLocalVariant alloc] initWithName:@"loop" probabilityWeight:3
                                                        assignments:@{@"bar": @"foo"}];
    expect(^{
      auto __unused experiment =
          [[LABLocalExperiment alloc] initWithName:@"exp_bar" keys:exp1Keys
                                          variants:@[exp1variant1, variantMissingKey]
                                  activeTokenRange:{0.1, 0.2}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should assert if there are no variants with positive probabilityWeight", ^{
    auto zeroProbabilityVariant1 = [[LABLocalVariant alloc] initWithName:@"var1" probabilityWeight:0
                                                             assignments:exp1assignment1];
    auto zeroProbabilityVariant2 = [[LABLocalVariant alloc] initWithName:@"var2" probabilityWeight:0
                                                             assignments:exp1assignment2];
    expect(^{
      auto __unused experiment = [[LABLocalExperiment alloc]
                                  initWithName:@"exp_bar" keys:exp1Keys
                                  variants:@[zeroProbabilityVariant1, zeroProbabilityVariant2]
                                  activeTokenRange:{0.1, 0.2}];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"LABLocalSource", ^{
  __block LABFakeLTRandom *random;
  __block id<LABStorage> storage;
  __block LABLocalExperiment *experiment1;
  __block LABLocalExperiment *experiment2;
  __block LABLocalExperiment *experiment3;
  __block NSArray<LABLocalVariant *> *experiment1Variants;
  __block NSArray<LABLocalVariant *> *experiment2Variants;
  __block NSArray<LABLocalVariant *> *experiment3Variants;
  __block LABLocalSource *source;
  __block LABExperimentsTokenProvider *tokenProvider;

  beforeEach(^{
    random = [[LABFakeLTRandom alloc] init];
    storage = [[LABFakeStorage alloc] init];
    experiment1Variants = @[exp1variant1, exp1variant2];
    experiment1 = [[LABLocalExperiment alloc] initWithName:@"experiment1" keys:exp1Keys
                                                  variants:experiment1Variants
                                          activeTokenRange:{0.2, 0.6}];
    experiment2Variants = @[exp2variant1, exp2variant2];
    experiment2 = [[LABLocalExperiment alloc] initWithName:@"experiment2" keys:exp2Keys
                                                  variants:experiment2Variants
                                          activeTokenRange:{0.4, 0.8}];
    experiment3Variants = @[exp3variant1, exp3variant2];
    experiment3 = [[LABLocalExperiment alloc] initWithName:@"experiment3" keys:exp3Keys
                                                  variants:experiment3Variants
                                          activeTokenRange:{0.3, 0.9}];

    tokenProvider = OCMClassMock(LABExperimentsTokenProvider.class);
    OCMStub([tokenProvider experimentsToken]).andReturn(0.5);
    [random fakeRandomUnsignedIntegerWithWeights:{2, 1} andReturnIndexOf:1];
    [random fakeRandomUnsignedIntegerWithWeights:{3, 1} andReturnIndexOf:3];
    [random fakeRandomUnsignedIntegerWithWeights:{3, 4} andReturnIndexOf:3];

    source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2]
                                experimentsTokenProvider:tokenProvider storage:storage
                                                  random:random];
  });

  it(@"should randomly choose variants", ^{
    auto expectedVariants = LABGenerateVariants(@{
        experiment1: exp1variant2,
        experiment2: exp2variant1
    });

    expect(source.activeVariants).to.equal(expectedVariants);
  });

  it(@"should fetch all experiments and variants", ^{
    auto expectedExperiments = @{
      @"experiment1": [@[@"exp1var1", @"exp1var2"] lt_set],
      @"experiment2": [@[@"exp2var1", @"exp2var2"] lt_set]
    };

    expect([source fetchAllExperimentsAndVariants]).to.sendValues(@[expectedExperiments]);

    storage = [[LABFakeStorage alloc] init];
    tokenProvider = OCMClassMock(LABExperimentsTokenProvider.class);
    OCMStub([tokenProvider experimentsToken]).andReturn(0.7);
    source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2]
        experimentsTokenProvider:tokenProvider storage:storage random:random];

    expect([source fetchAllExperimentsAndVariants]).to.sendValues(@[expectedExperiments]);
  });

  it(@"should only expose variants of experiments with range containing the token", ^{
    storage = [[LABFakeStorage alloc] init];
    tokenProvider = OCMClassMock(LABExperimentsTokenProvider.class);
    OCMStub([tokenProvider experimentsToken]).andReturn(0.7);
    source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2]
        experimentsTokenProvider:tokenProvider storage:storage random:random];

    expect(source.activeVariants).to.equal(LABGenerateVariants(@{experiment2: exp2variant1}));
  });

  context(@"assignment fetch", ^{
    it(@"should fetch assignments", ^{
      auto fetchSignal = [source fetchAssignmentsForExperiment:@"experiment1"
                                                   withVariant:exp1variant2.name];

      expect(fetchSignal).to.sendValues(@[exp1variant2.assignments]);
    });

    it(@"should fetch assignments for inactive variants", ^{
      auto fetchSignal = [source fetchAssignmentsForExperiment:@"experiment1"
                                                   withVariant:exp1variant1.name];

      expect(fetchSignal).to.sendValues(@[exp1variant1.assignments]);
    });

    it(@"should fetch assignments for inactive experiments", ^{
      tokenProvider = OCMClassMock(LABExperimentsTokenProvider.class);
      OCMStub([tokenProvider experimentsToken]).andReturn(0.7);
      source = [[LABLocalSource alloc]
                initWithExperiments:@[experiment1, experiment2]
                experimentsTokenProvider:tokenProvider storage:storage random:random];
      auto fetchSignal = [source fetchAssignmentsForExperiment:@"experiment1"
                                                   withVariant:exp1variant1.name];

      expect(fetchSignal).to.sendValues(@[exp1variant1.assignments]);
    });

    it(@"should err if experiment does not exist", ^{
      auto fetchSignal = [source fetchAssignmentsForExperiment:@"NonExistingExperiment"
                                                   withVariant:exp1variant1.name];
      auto error = [NSError lab_errorWithCode:LABErrorCodeVariantForExperimentNotFound
                         associatedExperiment:@"NonExistingExperiment"
                            associatedVariant:exp1variant1.name];

      expect(fetchSignal).to.sendError(error);
    });

    it(@"should err if variant does not exist", ^{
      auto fetchSignal = [source fetchAssignmentsForExperiment:@"experiment1"
                                                   withVariant:@"NonExistingVariant"];
      auto error = [NSError lab_errorWithCode:LABErrorCodeVariantForExperimentNotFound
                         associatedExperiment:@"experiment1"
                            associatedVariant:@"NonExistingVariant"];
      expect(fetchSignal).to.sendError(error);
    });
  });

  context(@"storage", ^{
    it(@"should store and use stored variants", ^{
      [random fakeRandomUnsignedIntegerWithWeights:{2, 1} andReturnIndexOf:2];
      [random fakeRandomUnsignedIntegerWithWeights:{3, 1} andReturnIndexOf:1];
      source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2]
          experimentsTokenProvider:tokenProvider storage:storage random:random];
      auto expectedVariants = LABGenerateVariants(@{
          experiment1: exp1variant2,
          experiment2: exp2variant1
      });

      expect(source.activeVariants).to.equal(expectedVariants);
    });

    it(@"should reselect variants if storage is deleted", ^{
      [random fakeRandomUnsignedIntegerWithWeights:{2, 1} andReturnIndexOf:2];
      [random fakeRandomUnsignedIntegerWithWeights:{3, 1} andReturnIndexOf:1];
      storage = [[LABFakeStorage alloc] init];
      source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2]
          experimentsTokenProvider:tokenProvider storage:storage random:random];
      auto expectedVariants = LABGenerateVariants(@{
          experiment1: exp1variant1,
          experiment2: exp2variant2
      });

      expect(source.activeVariants).to.equal(expectedVariants);
    });

    it(@"should keep old selected variants and select variants for new experiments", ^{
      [random fakeRandomUnsignedIntegerWithWeights:{2, 1} andReturnIndexOf:2];
      [random fakeRandomUnsignedIntegerWithWeights:{3, 1} andReturnIndexOf:1];
      [random fakeRandomUnsignedIntegerWithWeights:{3, 4} andReturnIndexOf:4];
      source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2, experiment3]
          experimentsTokenProvider:tokenProvider storage:storage random:random];

      auto expectedVariants = LABGenerateVariants(@{
          experiment1: exp1variant2,
          experiment2: exp2variant1,
          experiment3: exp3variant2
      });
      expect(source.activeVariants).to.equal(expectedVariants);
    });

    it(@"should reselect variants for experiment when the stored variant does not exist" , ^{
      exp2assignment1 = @{@"flip": @"flap", @"ping": @"pang"};
      auto exp2variant1new = [[LABLocalVariant alloc] initWithName:@"exp2var1new"
                                                 probabilityWeight:5 assignments:exp2assignment1];
      experiment2Variants = @[exp2variant1new, exp2variant2];
      experiment2 = [[LABLocalExperiment alloc] initWithName:@"experiment2" keys:exp2Keys
                                                    variants:experiment2Variants
                                            activeTokenRange:{0.4, 0.8}];
      [random fakeRandomUnsignedIntegerWithWeights:{5, 1} andReturnIndexOf:1];
      source = [[LABLocalSource alloc]
                initWithExperiments:@[experiment1, experiment2]
                experimentsTokenProvider:tokenProvider storage:storage random:random];

      auto expectedVariants = LABGenerateVariants(@{
          experiment1: exp1variant2,
          experiment2: exp2variant2
      });
      expect(source.activeVariants).to.equal(expectedVariants);
    });

    it(@"should persist active experiments even if the token becomes out of range", ^{
      [random fakeRandomUnsignedIntegerWithWeights:{2, 1} andReturnIndexOf:2];
      [random fakeRandomUnsignedIntegerWithWeights:{3, 1} andReturnIndexOf:1];
      tokenProvider = OCMClassMock(LABExperimentsTokenProvider.class);
      OCMStub([tokenProvider experimentsToken]).andReturn(0.7);
      source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2]
                                  experimentsTokenProvider:tokenProvider
                                                   storage:storage random:random];
      auto expectedVariants = LABGenerateVariants(@{
          experiment1: exp1variant2,
          experiment2: exp2variant1
      });
      expect(source.activeVariants).to.equal(expectedVariants);
    });

    it(@"should persist inactive experiments even if the token becomes in range", ^{
      [random fakeRandomUnsignedIntegerWithWeights:{2, 1} andReturnIndexOf:2];
      [random fakeRandomUnsignedIntegerWithWeights:{3, 1} andReturnIndexOf:1];
      storage = [[LABFakeStorage alloc] init];
      tokenProvider = OCMClassMock(LABExperimentsTokenProvider.class);
      OCMStub([tokenProvider experimentsToken]).andReturn(0.7);
      source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2]
                                  experimentsTokenProvider:tokenProvider
                                                   storage:storage random:random];
      tokenProvider = OCMClassMock(LABExperimentsTokenProvider.class);
      OCMStub([tokenProvider experimentsToken]).andReturn(0.5);
      source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2]
                                  experimentsTokenProvider:tokenProvider
                                                   storage:storage random:random];
      auto expectedVariants = LABGenerateVariants(@{
          experiment2: exp2variant2
      });
      expect(source.activeVariants).to.equal(expectedVariants);
    });

    it(@"should persist selected variant that changed its probability weight to zero", ^{
      [random fakeRandomUnsignedIntegerWithWeights:{2, 0} andReturnIndexOf:2];
      exp1variant2 = [[LABLocalVariant alloc] initWithName:@"exp1var2" probabilityWeight:0
                                               assignments:exp1assignment2];
      experiment1 = [[LABLocalExperiment alloc] initWithName:@"experiment1" keys:exp1Keys
                                                    variants:experiment1Variants
                                            activeTokenRange:{0.2, 0.6}];
      source = [[LABLocalSource alloc] initWithExperiments:@[experiment1]
                                  experimentsTokenProvider:tokenProvider storage:storage
                                                    random:random];
      auto expectedVariants = LABGenerateVariants(@{
        experiment1: exp1variant2,
      });
      expect(source.activeVariants).to.equal(expectedVariants);
    });

    context(@"deleted experiments", ^{
      beforeEach(^{
        [random fakeRandomUnsignedIntegerWithWeights:{2, 1} andReturnIndexOf:2];
        [random fakeRandomUnsignedIntegerWithWeights:{3, 1} andReturnIndexOf:1];
        source = [[LABLocalSource alloc] initWithExperiments:@[experiment1]
            experimentsTokenProvider:tokenProvider storage:storage random:random];
      });

      it(@"should not expose deleted experiments", ^{
        expect(source.activeVariants).to.equal(LABGenerateVariants(@{experiment1: exp1variant2}));
      });

      it(@"should not fetch deleted experiments and variants", ^{
        auto expectedExperiments = @{
          @"experiment1": [@[@"exp1var1", @"exp1var2"] lt_set]
        };

        expect([source fetchAllExperimentsAndVariants]).to.sendValues(@[expectedExperiments]);
      });

      it(@"should reselect experiments if they were previously deleted", ^{
        source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2]
            experimentsTokenProvider:tokenProvider storage:storage random:random];
        auto expectedVariants = LABGenerateVariants(@{
            experiment1: exp1variant2,
            experiment2: exp2variant2
        });

        expect(source.activeVariants).to.equal(expectedVariants);
      });
    });
  });

  context(@"stabilize", ^{
    beforeEach(^{
      [source stabilizeUserExperienceAssignments];
    });

    it(@"should not expose new experiments after stabilize was called", ^{
      source = [[LABLocalSource alloc] initWithExperiments:@[experiment1, experiment2, experiment3]
          experimentsTokenProvider:tokenProvider storage:storage random:random];

      auto expectedVariants = LABGenerateVariants(@{
        experiment1: exp1variant2,
        experiment2: exp2variant1
      });
      expect(source.activeVariants).to.equal(expectedVariants);
    });

    it(@"should not expose deleted experiments after stabilize was called", ^{
      source = [[LABLocalSource alloc] initWithExperiments:@[experiment1]
                                  experimentsTokenProvider:tokenProvider storage:storage random:random];

      auto expectedVariants = LABGenerateVariants(@{
        experiment1: exp1variant2,
      });
      expect(source.activeVariants).to.equal(expectedVariants);
    });
  });
});

SpecEnd
