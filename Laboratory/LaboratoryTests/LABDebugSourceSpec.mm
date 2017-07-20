// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABDebugSource.h"

#import <LTKit/LTHashExtensions.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>

#import "LABFakeAssignmentsSource.h"
#import "LABFakeStorage.h"
#import "NSError+Laboratory.h"

static LABVariant *LABCreateVariant(NSString *name, NSDictionary<NSString *, id> *assignments,
                                    NSString *experiment) {
  return [[LABVariant alloc] initWithName:name assignments:assignments experiment:experiment];
}

static NSDictionary *LABFakeExperiment(NSString *name, NSSet<NSString *> *variants, BOOL isActive,
                                       LABVariant * _Nullable selectedVariant) {
  return @{
    @"name": name,
    @"variants": variants,
    @"isActive": @(isActive),
    @"selectedVariant": selectedVariant ?: [NSNull null]
  };
}

static NSDictionary<NSString *, NSSet<NSDictionary *> *> *
    LABFakeExperiments(NSDictionary<NSString *, NSSet<id<LABDebugExperiment>> *> *experiments) {
  auto result = [NSMutableDictionary dictionary];

  [experiments enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                                   NSSet<id<LABDebugExperiment>> *obj, BOOL *) {
    result[key] = [[obj.allObjects lt_map:^(id<LABDebugExperiment> object) {
      return LABFakeExperiment(object.name, object.variants, object.isActive,
                               object.activeVariant);
    }] lt_set];
  }];

  return [result copy];
}

/// Vector of source and variant selection array pairs, indicating which variants should be selected
/// for the source. If an experiment in <tt>-[LABFakeAssignmentsSource allExperiments]</tt> has a
/// variant in the selection array it is considered active, otherwise it is considered inactive.
typedef std::vector<std::pair<LABFakeAssignmentsSource *, NSArray<LABVariant *> *>>
    LABFakeSourcesSelections;

static NSDictionary<NSString *, NSSet<NSDictionary *> *>
    *LABFakeSourcesExperiments(LABFakeSourcesSelections fakeSourcesSelections) {
  auto result = [NSMutableDictionary dictionary];

  for (auto sourceSelections : fakeSourcesSelections) {
    LABFakeAssignmentsSource *source = sourceSelections.first;
    NSArray<LABVariant *> *selections = sourceSelections.second;
    auto selectionsSet = [selections lt_set];
    auto experiments = [NSMutableSet set];
    [source.allExperiments enumerateKeysAndObjectsUsingBlock:^(NSString *experiment,
                                                               NSArray<LABVariant *> *variants,
                                                               BOOL *) {
      NSSet<NSString *> *variantNames = [[variants lt_map:^(LABVariant *variant) {
        return variant.name;
      }] lt_set];

      LABVariant *selectedVariant = [variants lt_find:^BOOL(LABVariant *object) {
        return [selectionsSet containsObject:object];
      }];

      [experiments addObject:LABFakeExperiment(experiment, variantNames, selectedVariant != nil,
                                               selectedVariant)];
    }];
    result[source.name] = experiments;
  }

  return [result copy];
}

SpecBegin(LABDebugSource)

__block LABFakeAssignmentsSource *fakeSource1, *fakeSource2;
__block LABFakeStorage *storage;
__block LABDebugSource *source;
__block std::unordered_map<std::tuple<NSUInteger, NSUInteger, NSUInteger>, LABVariant *> variants;

beforeEach(^{
  variants = {
    {{0, 0, 0}, LABCreateVariant(@"bobVar", @{@"foo": @"bar", @"baz": @"thud"}, @"exp1")},
    {{0, 0, 1}, LABCreateVariant(@"blobVar", @{@"foo": @"thud", @"baz": @"bar"}, @"exp1")},
    {{0, 1, 0}, LABCreateVariant(@"fooVar", @{@"bob": @2, @"bab": @"thud"}, @"exp2")},
    {{0, 1, 1}, LABCreateVariant(@"barVar", @{@"bob": @3, @"bab": @"bar"}, @"exp2")},
    {{1, 0, 0}, LABCreateVariant(@"bobVar", @{@"ping": @"pong", @"flip": @"flop"}, @"exp1")},
    {{1, 0, 1}, LABCreateVariant(@"blobVar", @{@"ping": @"pang", @"flip": @"flap"}, @"exp1")},
    {{1, 1, 0}, LABCreateVariant(@"fooVar", @{@"que": @4, @"quee": @"bar"}, @"exp2")},
    {{1, 1, 1}, LABCreateVariant(@"barVar", @{@"que": @9, @"quee": @"baz"}, @"exp2")}
  };
  fakeSource1 = [[LABFakeAssignmentsSource alloc] init];
  fakeSource1.allExperiments = @{
    @"exp1": @[variants[{0, 0, 0}], variants[{0, 0, 1}]],
    @"exp2": @[variants[{0, 1, 0}], variants[{0, 1, 1}]]
  };
  fakeSource1.name = @"fake1";
  fakeSource2 = [[LABFakeAssignmentsSource alloc] init];
  fakeSource2.allExperiments = @{
    @"exp1": @[variants[{1, 0, 0}], variants[{1, 0, 1}]],
    @"exp2": @[variants[{1, 1, 0}], variants[{1, 1, 1}]]
  };
  fakeSource2.name = @"fake2";
  storage = [[LABFakeStorage alloc] init];
  source = [[LABDebugSource alloc] initWithSources:@[fakeSource1, fakeSource2] storage:storage];
});

it(@"should have no experiments model with an empty storage", ^{
  expect(source.allExperiments).to.haveCount(0);
});

it(@"should update all experiment models", ^{
  expect([source update]).will.complete();
  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[]}, {fakeSource2, @[]}
  });

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
});

it(@"should update experiment models when a source has no expeiments", ^{
  fakeSource2.allExperiments = @{};
  expect([source update]).will.complete();
  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[]}, {fakeSource2, @[]}
  });

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
});

it(@"should err update if one of the sources errs during the update", ^{
  auto underlyingError = [NSError lt_errorWithCode:LABErrorCodeFetchFailed];
  auto fetchAllExperimentsAndVariantsSignal = fakeSource1.fetchAllExperimentsAndVariantsSignal;
  fakeSource1.fetchAllExperimentsAndVariantsSignal = [RACSignal error:underlyingError];

  expect([source update]).will.sendError([NSError lt_errorWithCode:LABErrorCodeSourceUpdateFailed
                                                   underlyingError:underlyingError]);

  fakeSource1.fetchAllExperimentsAndVariantsSignal = fetchAllExperimentsAndVariantsSignal;
  underlyingError = [NSError lab_errorWithCode:LABErrorCodeVariantForExperimentNotFound
                          associatedExperiment:@"foo" associatedVariant:@"bar"];
  fakeSource1.fetchAssignmentsSignalBlock = ^(NSString *, NSString *) {
    return [RACSignal error:underlyingError];
  };

  expect([source update]).will.sendError([NSError lt_errorWithCode:LABErrorCodeSourceUpdateFailed
                                                   underlyingError:underlyingError]);
});

it(@"should initialize with empty activeVariants", ^{
  expect(source.activeVariants).to.haveCount(0);
  expect([source update]).will.complete();
  expect(source.activeVariants).to.haveCount(0);
});

it(@"it should persist experiment models between updates if no changes are available", ^{
  expect([source update]).will.complete();
  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[]},
    {fakeSource2, @[]}
  });
  auto source2exp3Variant1 = LABCreateVariant(@"fooVar", @{@"que": @4, @"quee": @"bar"}, @"exp3");
  auto source2exp3Variant2 = LABCreateVariant(@"barVar", @{@"que": @9, @"quee": @"baz"}, @"exp3");
  fakeSource2.allExperiments = @{
    @"exp1": @[variants[{1, 0, 0}], variants[{1, 0, 1}]],
    @"exp3": @[source2exp3Variant1, source2exp3Variant2]
  };
  source = [[LABDebugSource alloc] initWithSources:@[fakeSource1, fakeSource2] storage:storage];

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);

  expect([source update]).will.complete();
  expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[]},
    {fakeSource2, @[]}
  });

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
});

it(@"should not persist experiments models of missing sources", ^{
  expect([source update]).will.complete();
  source = [[LABDebugSource alloc] initWithSources:@[fakeSource1] storage:storage];
  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[]}
  });

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
});

it(@"should activate variants", ^{
  expect([source update]).will.complete();
  auto variantToActivate = variants[{0, 0, 1}];
  auto activationSignal =
      [source activateVariant:variantToActivate.name ofExperiment:variantToActivate.experiment
                     ofSource:fakeSource1.name];

  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[variantToActivate]},
    {fakeSource2, @[]}
  });
  auto expectedActivationRequests = @{
    fakeSource1.name: @{variantToActivate.experiment: variantToActivate.name}
  };

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to.equal([@[variantToActivate] lt_set]);
  expect(activationSignal).to.sendValues(@[@YES]);
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);

  auto variantToActivate2 = variants[{1, 0, 0}];
  activationSignal =
      [source activateVariant:variantToActivate2.name ofExperiment:variantToActivate2.experiment
                     ofSource:fakeSource2.name];

  expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[variantToActivate]},
    {fakeSource2, @[variantToActivate2]}
  });
  expectedActivationRequests = @{
    fakeSource1.name: @{variantToActivate.experiment: variantToActivate.name},
    fakeSource2.name: @{variantToActivate2.experiment: variantToActivate2.name}
  };

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to.equal([@[variantToActivate, variantToActivate2] lt_set]);
  expect(activationSignal).to.sendValues(@[@YES]);
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);
});

it(@"should deactivate an experiment if the variant is nil", ^{
  expect([source update]).will.complete();
  auto activationSignal1 =
      [source activateVariant:variants[{0, 0, 1}].name ofExperiment:variants[{0, 0, 1}].experiment
                     ofSource:fakeSource1.name];
  [source activateVariant:variants[{1, 0, 0}].name ofExperiment:variants[{1, 0, 0}].experiment
                 ofSource:fakeSource2.name];
  [source deactivateExperiment:variants[{0, 0, 1}].experiment ofSource:fakeSource1.name];

  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[]},
    {fakeSource2, @[variants[{1, 0, 0}]]}
  });
  auto expectedActivationRequests = @{
    fakeSource2.name: @{variants[{1, 0, 0}].experiment: variants[{1, 0, 0}].name}
  };

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to.equal([@[variants[{1, 0, 0}]] lt_set]);
  expect(activationSignal1).to.sendValues(@[@YES]);
  expect(activationSignal1).to.complete();
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);
});

it(@"should complete when a different variant is activated for an experiment", ^{
  expect([source update]).will.complete();
  auto activationSignal1 =
      [source activateVariant:variants[{0, 0, 1}].name ofExperiment:variants[{0, 0, 1}].experiment
                     ofSource:fakeSource1.name];
  auto activationSignal2 =
      [source activateVariant:variants[{0, 0, 0}].name ofExperiment:variants[{0, 0, 0}].experiment
                     ofSource:fakeSource1.name];

  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[variants[{0, 0, 0}]]},
    {fakeSource2, @[]}
  });

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to.equal([@[variants[{0, 0, 0}]] lt_set]);
  expect(activationSignal1).to.sendValues(@[@YES]);
  expect(activationSignal1).to.complete();
  expect(activationSignal2).to.sendValues(@[@YES]);
  expect(activationSignal2).notTo.complete();
});

it(@"should sendNO variant and experiment to activate are of a non existing source", ^{
  expect([source update]).will.complete();
  expect([source activateVariant:variants[{0, 0, 1}].name
                    ofExperiment:variants[{0, 0, 1}].experiment
                        ofSource:@"foo"]).to.sendValues(@[@NO]);

  expect(source.activeVariants).to.haveCount(0);
});

it(@"should err if experiment to activate does not exist for a source in allExperiments", ^{
  expect([source update]).will.complete();
  expect([source activateVariant:variants[{0, 0, 1}].name ofExperiment:@"foo"
                        ofSource:fakeSource1.name]).to.sendValues(@[@NO]);

  auto expectedActivationRequests = @{
    fakeSource1.name: @{@"foo": variants[{0, 0, 1}].name}
  };
  expect(source.activeVariants).to.haveCount(0);
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);
});

it(@"should err if variant to activate does not exist in an experiment", ^{
  expect([source update]).will.complete();
  expect([source activateVariant:@"foo" ofExperiment:variants[{0, 0, 1}].experiment
                        ofSource:fakeSource1.name]).to.sendValues(@[@NO]);

  auto expectedActivationRequests = @{
    fakeSource1.name: @{variants[{0, 0, 1}].experiment: @"foo"}
  };
  expect(source.activeVariants).to.haveCount(0);
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);
});

it(@"should not preserve activate state if variant to activate does not exist in an experiment", ^{
  expect([source update]).will.complete();
  auto activationSignal1 =
      [source activateVariant:variants[{0, 0, 1}].name ofExperiment:variants[{0, 0, 1}].experiment
                     ofSource:fakeSource1.name];
  auto activationSignal2 =
      [source activateVariant:@"foo" ofExperiment:variants[{0, 0, 1}].experiment
                     ofSource:fakeSource1.name];
  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[]},
    {fakeSource2, @[]}
  });
  auto expectedActivationRequests = @{
    fakeSource1.name: @{variants[{0, 0, 1}].experiment: @"foo"}
  };

  expect(activationSignal1).to.sendValues(@[@YES]);
  expect(activationSignal1).to.complete();
  expect(activationSignal2).to.sendValues(@[@NO]);
  expect(activationSignal2).notTo.complete();
  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to.equal([NSSet set]);
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);
});

it(@"should complete activation signal if source deallocates", ^{
  __block RACSignal *activationSignal;
  @autoreleasepool {
    auto source = [[LABDebugSource alloc] initWithSources:@[fakeSource1, fakeSource2] storage:storage];
    expect([source update]).will.complete();
    activationSignal = [source activateVariant:variants[{0, 0, 1}].name
                                  ofExperiment:variants[{0, 0, 1}].experiment
                                      ofSource:fakeSource1.name];
  }

  expect(activationSignal).will.complete();
});

it(@"should persist active variants between source updates", ^{
  auto activationSignal = [source activateVariant:variants[{0, 0, 1}].name
                                     ofExperiment:variants[{0, 0, 1}].experiment
                                         ofSource:fakeSource1.name];
  auto expectedActivationRequests = @{
    fakeSource1.name: @{variants[{0, 0, 1}].experiment: variants[{0, 0, 1}].name}
  };
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);
  expect(activationSignal).to.sendValues(@[@NO]);
  expect([source update]).will.complete();
  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[variants[{0, 0, 1}]]},
    {fakeSource2, @[]}
  });

  expect(activationSignal).to.sendValues(@[@NO, @YES]);
  expect(activationSignal).notTo.complete();
  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to.equal([@[variants[{0, 0, 1}]] lt_set]);
});

it(@"should persist active variants", ^{
  expect([source update]).will.complete();
  [source activateVariant:variants[{0, 0, 1}].name ofExperiment:variants[{0, 0, 1}].experiment
                 ofSource:fakeSource1.name];
  [source activateVariant:variants[{1, 0, 0}].name ofExperiment:variants[{1, 0, 0}].experiment
                 ofSource:fakeSource2.name];
  source = [[LABDebugSource alloc] initWithSources:@[fakeSource1, fakeSource2] storage:storage];

  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[variants[{0, 0, 1}]]},
    {fakeSource2, @[variants[{1, 0, 0}]]}
  });
  auto expectedActivationRequests = @{
    fakeSource1.name: @{variants[{0, 0, 1}].experiment: variants[{0, 0, 1}].name},
    fakeSource2.name: @{variants[{1, 0, 0}].experiment: variants[{1, 0, 0}].name}
  };

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to.equal([@[variants[{0, 0, 1}], variants[{1, 0, 0}]] lt_set]);
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);
});

it(@"should not expose active variants for missing sources", ^{
  expect([source update]).will.complete();
  [source activateVariant:variants[{0, 0, 1}].name ofExperiment:variants[{0, 0, 1}].experiment
                 ofSource:fakeSource1.name];
  [source activateVariant:variants[{1, 0, 0}].name ofExperiment:variants[{1, 0, 0}].experiment
                 ofSource:fakeSource2.name];
  source = [[LABDebugSource alloc] initWithSources:@[fakeSource2] storage:storage];

  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource2, @[variants[{1, 0, 0}]]}
  });

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to.equal([@[variants[{1, 0, 0}]] lt_set]);
});

it(@"should expose active variants between source updates", ^{
  expect([source update]).will.complete();
  auto activationSignal = [source activateVariant:variants[{0, 0, 1}].name
                                     ofExperiment:variants[{0, 0, 1}].experiment
                                         ofSource:fakeSource1.name];
  [source activateVariant:variants[{1, 0, 0}].name ofExperiment:variants[{1, 0, 0}].experiment
                 ofSource:fakeSource2.name];
  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[variants[{0, 0, 1}]]},
    {fakeSource2, @[variants[{1, 0, 0}]]}
  });

  auto source1exp3Variant1 = LABCreateVariant(@"fooVar", @{@"que": @4, @"quee": @"bar"}, @"exp3");
  auto source1exp3Variant2 = LABCreateVariant(@"barVar", @{@"que": @9, @"quee": @"baz"}, @"exp3");
  fakeSource1.allExperiments = @{
    @"exp2": @[variants[{0, 1, 1}], variants[{0, 1, 1}]],
    @"exp3": @[source1exp3Variant1, source1exp3Variant2]
  };

  expect(activationSignal).to.sendValues(@[@YES]);
  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to.equal([@[variants[{0, 0, 1}], variants[{1, 0, 0}]] lt_set]);

  expect([source update]).will.complete();
  expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[]},
    {fakeSource2, @[variants[{1, 0, 0}]]}
  });

  expect(activationSignal).to.sendValues(@[@YES, @NO]);
  expect(activationSignal).notTo.complete();
  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to.equal([@[variants[{1, 0, 0}]] lt_set]);
});

it(@"should update active assignments if they changed between updates", ^{
  expect([source update]).will.complete();
  [source activateVariant:variants[{0, 0, 1}].name ofExperiment:variants[{0, 0, 1}].experiment
                 ofSource:fakeSource1.name];
  [source activateVariant:variants[{1, 0, 0}].name ofExperiment:variants[{1, 0, 0}].experiment
                 ofSource:fakeSource2.name];

  auto source1exp1NewVariant2 =
      LABCreateVariant(@"blobVar", @{@"foo": @"thud", @"baz": @"bar", @"doo": @55}, @"exp1");
  fakeSource1.allExperiments = @{
    @"exp1": @[variants[{0, 0, 0}], source1exp1NewVariant2],
    @"exp2": @[variants[{0, 1, 0}], variants[{0, 1, 1}]]
  };
  auto source2exp1NewVariant1 =
      LABCreateVariant(@"bobVar", @{@"ping": @"pong", @"flip": @"floopy"}, @"exp1");
  fakeSource2.allExperiments = @{
    @"exp1": @[source2exp1NewVariant1, variants[{1, 0, 1}]],
    @"exp2": @[variants[{1, 1, 0}], variants[{1, 1, 1}]]
  };
  expect([source update]).will.complete();

  auto expectedExperiments = LABFakeSourcesExperiments({
    {fakeSource1, @[source1exp1NewVariant2]},
    {fakeSource2, @[source2exp1NewVariant1]}
  });

  expect(LABFakeExperiments(source.allExperiments)).to.equal(expectedExperiments);
  expect(source.activeVariants).to
      .equal([@[source1exp1NewVariant2, source2exp1NewVariant1] lt_set]);
});

it(@"should reset variant activation requests", ^{
  [source activateVariant:variants[{0, 0, 1}].name ofExperiment:variants[{0, 0, 1}].experiment
                   ofSource:fakeSource1.name];
  [source activateVariant:variants[{1, 0, 1}].name ofExperiment:variants[{1, 0, 1}].experiment
                   ofSource:fakeSource2.name];

  auto expectedActivationRequests = @{
    fakeSource1.name: @{variants[{0, 0, 1}].experiment: variants[{0, 0, 1}].name},
    fakeSource2.name: @{variants[{1, 0, 1}].experiment: variants[{1, 0, 1}].name}
  };

  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);

  [source resetVariantActivations];
  expect(source.variantActivationRequests).to.haveCount(0);
});

it(@"should deallocate properly", ^{
  __block __weak LABDebugSource *weakSource;
  @autoreleasepool {
    auto strongSource =
        [[LABDebugSource alloc] initWithSources:@[fakeSource1, fakeSource2] storage:storage];
    expect([strongSource update]).will.complete();
    weakSource = strongSource;
    expect(weakSource).notTo.beNil();
  }

  expect(weakSource).to.beNil();
});

SpecEnd
