// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABTaplyticsSource.h"

#import <LTKit/NSArray+NSSet.h>
#import <LTKitTestUtils/LTFakeKeyValuePersistentStorage.h>

#import "LABExperimentsTokenProvider.h"
#import "LABTaplytics.h"
#import "NSError+Laboratory.h"

static auto const kAPIKey = @"foo_key";

/// Fake Taplytics object to test changing properties.
@interface LABFakeTaplytics : NSObject <LABTaplytics>
@property (readonly, nonatomic, nullable) NSString *startApiKey;
@property (readwrite, nonatomic, nullable) id<LABTaplyticsProperties> properties;
@property (readonly, nonatomic, nullable) NSDictionary *userAttributes;
@property (nonatomic) UIBackgroundFetchResult refreshPropertiesInBackgroundResponse;
@property (nonatomic) BOOL performLoadPropertiesFromServerResponse;
@property (nonatomic, nullable) id<LABTaplyticsProperties> propertiesForExperiment;
@property (nonatomic, nullable) id<LABTaplyticsProperties> allExperimentsToVariations;
@property (nonatomic, nullable) NSError *fetchPropertiesForExperimentError;
@property (nonatomic, nullable) NSError *fetchPropertiesError;
@end

@implementation LABFakeTaplytics

@synthesize properties = _properties;

- (void)startTaplyticsWithAPIKey:(NSString *)apiKey
                     options:(nullable NSDictionary __unused *)options {
  _startApiKey = apiKey;
}

- (void)logEventWithName:(NSString __unused *)name value:(nullable NSNumber  __unused *)value
              properties:(nullable NSDictionary __unused *)properties {
}

- (void)setUserAttributes:(nullable NSDictionary *)userAttributes {
  _userAttributes = userAttributes;
}

- (void)propertiesLoadedWithCompletion:(LABTaplyticsPropertiesLoadedBlock __unused)completionBlock {
}

- (void)refreshPropertiesInBackground:(LABTaplyticsBackgroundFetchBlock)completionBlock {
  completionBlock(self.refreshPropertiesInBackgroundResponse);
}

- (void)performLoadPropertiesFromServer:(LABTaplyticsLoadPropertiesFromServerBlock)completionBlock {
  completionBlock(self.performLoadPropertiesFromServerResponse);
}

- (void)fetchPropertiesForExperiment:(NSString __unused *)experiment
                       withVariation:(NSString __unused *)variation
                          completion:(LABTaplyticsFetchPropertiesBlock)completionBlock {
  completionBlock(self.propertiesForExperiment, self.fetchPropertiesForExperimentError);
}

- (void)fetchPropertiesWithCompletion:(LABTaplyticsFetchPropertiesBlock)completionBlock {
  completionBlock(self.allExperimentsToVariations, self.fetchPropertiesError);
}

@end

@interface LABFakeTaplyticsProperties : NSObject <LABTaplyticsProperties, NSCopying>
@property (readwrite, nonatomic)
    NSDictionary<NSString *, NSString *> *activeExperimentsToVariations;
@property (readwrite, nonatomic) NSDictionary<NSString *, id> *activeDynamicVariables;
@property (readwrite, nonatomic)
    NSDictionary<NSString *, NSSet<NSString *> *> *allExperimentsToVariations;
@end

@implementation LABFakeTaplyticsProperties

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  auto copy = [[LABFakeTaplyticsProperties alloc] init];
  copy.activeExperimentsToVariations = self.activeExperimentsToVariations;
  copy.activeDynamicVariables = self.activeDynamicVariables;
  copy.allExperimentsToVariations = self.allExperimentsToVariations;
  return copy;
}

@end

static NSDictionary *kExistingExperimentsToVariations = @{
  @"Exp1": [@[@"Exp1Var1", @"Exp1Var2"] lt_set],
  @"ExistingUsersExp2": [@[@"Exp2Var1", @"Exp2Var2"] lt_set],
};

static NSDictionary *k4ExperimentsToVariations = @{
  @"Exp1": [@[@"Exp1Var1", @"Exp1Var2"] lt_set],
  @"Exp2": [@[@"Exp2Var1", @"Exp2Var2"] lt_set],
  @"Exp3": [@[@"Exp3Var1", @"Exp3Var2"] lt_set],
  @"__Remote_Exp4": [@[@"Exp4Var1", @"Exp4Var2"] lt_set]
};

static NSDictionary *k3ExperimentsToVariations = @{
  @"Exp1": [@[@"Exp1Var1", @"Exp1Var2"] lt_set],
  @"Exp2": [@[@"Exp2Var1", @"Exp2Var2"] lt_set],
  @"Exp3": [@[@"Exp3Var1", @"Exp3Var2"] lt_set]
};

static NSDictionary *k2ExperimentsToVariations = @{
  @"Exp1": [@[@"Exp1Var1", @"Exp1Var2"] lt_set],
  @"Exp2": [@[@"Exp2Var1", @"Exp2Var2"] lt_set]
};

static NSDictionary *k1ExperimentsToVariations = @{
  @"Exp1": [@[@"Exp1Var1", @"Exp1Var2"] lt_set]
};

SpecBegin(LABTaplyticsSource)

__block LABExperimentsTokenProvider *tokenProvider;
__block LTFakeKeyValuePersistentStorage *storage;

beforeEach(^{
  tokenProvider = OCMClassMock(LABExperimentsTokenProvider.class);
  OCMStub([tokenProvider experimentsToken]).andReturn(0.3);
  storage = [[LTFakeKeyValuePersistentStorage alloc] init];
});

context(@"initialization", ^{
  __block LABFakeTaplytics *taplytics;

  beforeEach(^{
    taplytics = [[LABFakeTaplytics alloc] init];
  });

  it(@"should send custom data", ^{
    auto __unused source = [[LABTaplyticsSource alloc]
                            initWithAPIKey:kAPIKey experimentsTokenProvider:tokenProvider
                            customData:@{@"customKey": @"customValue"} taplytics:taplytics
                            storage:storage];
    expect(taplytics.startApiKey).equal(kAPIKey);
    expect(taplytics.userAttributes[@"customData"][@"customKey"]).equal(@"customValue");
  });

  it(@"should send experiments token as custom data", ^{
    auto __unused source = [[LABTaplyticsSource alloc]
                            initWithAPIKey:kAPIKey experimentsTokenProvider:tokenProvider
                            customData:@{@"customKey": @"customValue"} taplytics:taplytics
                            storage:storage];
    expect(((NSDictionary *)taplytics.userAttributes[@"customData"][@"ExperimentsToken"]))
        .to.equal(@0.3);
  });
});

context(@"initialized source", ^{
  __block LABTaplytics *taplytics;
  __block LABTaplyticsSource *source;

  beforeEach(^{
    taplytics = OCMClassMock(LABTaplytics.class);
    source = [[LABTaplyticsSource alloc] initWithAPIKey:kAPIKey
                               experimentsTokenProvider:tokenProvider customData:@{}
                                              taplytics:taplytics storage:storage];
  });

  it(@"should update and complete when the callback is called with success", ^{
    OCMStub([taplytics performLoadPropertiesFromServer:([OCMArg invokeBlockWithArgs:@YES, nil])]);
    expect([source update]).will.complete();
    OCMVerify([taplytics performLoadPropertiesFromServer:OCMOCK_ANY]);
  });

  it(@"should update and err when the callback is called with error", ^{
    OCMStub([taplytics performLoadPropertiesFromServer:([OCMArg invokeBlockWithArgs:@NO, nil])]);
    expect([source update]).will
        .sendError([NSError lt_errorWithCode:LABErrorCodeSourceUpdateFailed]);
    OCMVerify([taplytics performLoadPropertiesFromServer:OCMOCK_ANY]);
  });

  it(@"should update even without subscriber to the signal", ^{
    OCMExpect([taplytics performLoadPropertiesFromServer:OCMOCK_ANY]);
    [source update];
    OCMVerifyAllWithDelay((id)taplytics, 1);
  });

  it(@"should update in the background and send new data if callback reports new data", ^{
    OCMStub([taplytics refreshPropertiesInBackground:
            ([OCMArg invokeBlockWithArgs:@(UIBackgroundFetchResultNewData), nil])]);
    expect([source updateInBackground]).will.sendValues(@[@(UIBackgroundFetchResultNewData)]);
    OCMVerify([taplytics refreshPropertiesInBackground:OCMOCK_ANY]);
  });

  it(@"should update in the background and send failure if callback reports failure", ^{
    OCMStub([taplytics refreshPropertiesInBackground:
             ([OCMArg invokeBlockWithArgs:@(UIBackgroundFetchResultFailed), nil])]);
    expect([source updateInBackground]).will.sendValues(@[@(UIBackgroundFetchResultFailed)]);
    OCMVerify([taplytics refreshPropertiesInBackground:OCMOCK_ANY]);
  });

  it(@"should update in the background even without subscriber to the signal", ^{
    OCMExpect([taplytics refreshPropertiesInBackground:OCMOCK_ANY]);
    [source updateInBackground];
    OCMVerifyAllWithDelay((id)taplytics, 1);
  });
});

context(@"properties change", ^{
  __block LABTaplyticsSource *source;
  __block LABFakeTaplytics *taplytics;

  beforeEach(^{
    taplytics = [[LABFakeTaplytics alloc] init];
    source = [[LABTaplyticsSource alloc] initWithAPIKey:kAPIKey
                               experimentsTokenProvider:tokenProvider customData:@{}
                                              taplytics:taplytics storage:storage];
  });

  it(@"should update the exposed variants as the data from taplytics change", ^{
    expect(source.activeVariants).to.beNil();

    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"__Keys_Exp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"Exp1Key1": @"foo",
      @"Exp1Key2": @"bar",
      @"Exp2Key1": @"baz",
      @"Exp2Key2": @"flu"
    };
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var2",
      @"Exp2": @"Exp2Var1",
      @"Exp3": @"Exp3Var2"
    };
    taplytics.properties = taplyticsProperties;

    auto exp1var2 = [[LABVariant alloc] initWithName:@"Exp1Var2"
                                         assignments:@{@"Exp1Key1": @"foo", @"Exp1Key2": @"bar"}
                                          experiment:@"Exp1"];
    auto exp2var1 = [[LABVariant alloc] initWithName:@"Exp2Var1"
                                         assignments:@{@"Exp2Key1": @"baz", @"Exp2Key2": @"flu"}
                                          experiment:@"Exp2"];
    auto expectedVariants = [@[exp1var2, exp2var1] lt_set];
    expect(source.activeVariants).to.equal(expectedVariants);

    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"Exp1Key1": @"zip",
      @"Exp1Key2": @"blup",
    };
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var1",
    };
    taplytics.properties = taplyticsProperties;

    auto exp1var1 = [[LABVariant alloc] initWithName:@"Exp1Var1"
                                         assignments:@{@"Exp1Key1": @"zip", @"Exp1Key2": @"blup"}
                                          experiment:@"Exp1"];
    expect(source.activeVariants).to.equal([NSSet setWithObject:exp1var1]);
  });

  it(@"should not expose misconfigured experiments", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\", \"boo\"]",
      @"__Keys_Exp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"Exp1Key1": @"foo",
      @"Exp1Key2": @"bar",
      @"Exp2Key1": @"baz",
      @"Exp2Key2": @"flu"
    };
    taplyticsProperties.allExperimentsToVariations = k4ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var2",
      @"Exp2": @"Exp2Var1",
      @"Exp3": @"Exp3Var2",
      @"__Remote_Exp4": @"Exp4Var2"
    };
    taplytics.properties = taplyticsProperties;

    auto exp2var1 = [[LABVariant alloc] initWithName:@"Exp2Var1"
                                         assignments:@{@"Exp2Key1": @"baz", @"Exp2Key2": @"flu"}
                                          experiment:@"Exp2"];
    auto expectedVariants = [NSSet setWithObject:exp2var1];
    expect(source.activeVariants).to.equal(expectedVariants);
  });

  it(@"should not expose remote configuration experiments", ^{
    expect(source.activeVariants).to.beNil();

    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"__Keys_Exp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"Exp1Key1": @"foo",
      @"Exp1Key2": @"bar",
      @"Exp2Key1": @"baz",
      @"Exp2Key2": @"flu",
      @"Exp4Key1": @"faz",
      @"Exp4Key2": @"que"
    };
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var2",
      @"Exp2": @"Exp2Var1",
      @"Exp3": @"Exp3Var2"
    };
    taplytics.properties = taplyticsProperties;

    auto exp1var2 = [[LABVariant alloc] initWithName:@"Exp1Var2"
                                         assignments:@{@"Exp1Key1": @"foo", @"Exp1Key2": @"bar"}
                                          experiment:@"Exp1"];
    auto exp2var1 = [[LABVariant alloc] initWithName:@"Exp2Var1"
                                         assignments:@{@"Exp2Key1": @"baz", @"Exp2Key2": @"flu"}
                                          experiment:@"Exp2"];
    auto expectedVariants = [@[exp1var2, exp2var1] lt_set];
    expect(source.activeVariants).to.equal(expectedVariants);
  });

  it(@"should fetch all experiments", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeDynamicVariables = @{};
    taplyticsProperties.activeExperimentsToVariations = @{};
    taplytics.allExperimentsToVariations = taplyticsProperties;

    expect([source fetchAllExperimentsAndVariants]).to.sendValues(@[k3ExperimentsToVariations]);

    taplyticsProperties.allExperimentsToVariations = k2ExperimentsToVariations;
    expect([source fetchAllExperimentsAndVariants]).to.sendValues(@[k2ExperimentsToVariations]);
  });

  it(@"should not fetch remote configuration experiments", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeDynamicVariables = @{};
    taplyticsProperties.activeExperimentsToVariations = @{};
    taplytics.allExperimentsToVariations = taplyticsProperties;

    expect([source fetchAllExperimentsAndVariants]).to.sendValues(@[k3ExperimentsToVariations]);

    taplyticsProperties.allExperimentsToVariations = k4ExperimentsToVariations;
    expect([source fetchAllExperimentsAndVariants]).to.sendValues(@[k3ExperimentsToVariations]);
  });

  it(@"should err all experiments fetch operation if callback returned error", ^{
    taplytics.fetchPropertiesError = [NSError lt_errorWithCode:LABErrorCodeFetchFailed];
    expect([source fetchAllExperimentsAndVariants])
      .to.sendError([NSError lt_errorWithCode:LABErrorCodeFetchFailed]);
  });

  it(@"should fetch assignments for variant", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"Exp1Key1": @"zip",
      @"Exp1Key2": @"blup",
    };
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var1",
    };
    taplytics.propertiesForExperiment = taplyticsProperties;

    auto expectedAssignemnts = @{@"Exp1Key1": @"zip", @"Exp1Key2": @"blup"};
    expect([source fetchAssignmentsForExperiment:@"Exp1" withVariant:@"Exp1Var1"])
        .to.sendValues(@[expectedAssignemnts]);
  });

  it(@"should err assignments fetch operation if an experiment was misconfigured", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp2": @"[\"Exp2Key1\", \"Exp2Key3\"]",
      @"Exp2Key1": @"baz",
      @"Exp2Key2": @"flu",
    };
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp2": @"Exp2Var1",
    };
    taplytics.propertiesForExperiment = taplyticsProperties;

    auto expectedError = [NSError lab_errorWithCode:LABErrorCodeMisconfiguredExperiment
                               associatedExperiment:@"Exp1"];
    expect([source fetchAssignmentsForExperiment:@"Exp1" withVariant:@"Exp1Var1"])
        .to.sendError(expectedError);
  });

  it(@"should err assignments fetch operation if callback returned error", ^{
    taplytics.fetchPropertiesForExperimentError =
        [NSError lt_errorWithCode:1337];
    expect([source fetchAssignmentsForExperiment:@"Exp1" withVariant:@"Exp1Var1"])
        .to.sendError([NSError lt_errorWithCode:1337]);
  });

  it(@"should not expose changes in experiments after stabilization was requested", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"Exp1Key1": @"foo",
      @"Exp1Key2": @"bar",
    };
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var2",
    };
    taplytics.properties = taplyticsProperties;

    [source stabilizeUserExperienceAssignments];

    taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"__Keys_Exp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"Exp1Key1": @"flip",
      @"Exp1Key2": @"flop",
      @"Exp2Key1": @"ding",
      @"Exp2Key2": @"dong"
    };
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var1",
      @"Exp2": @"Exp2Var2",
    };
    taplytics.properties = taplyticsProperties;

    auto exp1var2 = [[LABVariant alloc] initWithName:@"Exp1Var2"
                                         assignments:@{@"Exp1Key1": @"foo", @"Exp1Key2": @"bar"}
                                          experiment:@"Exp1"];
    expect(source.activeVariants).to.equal([@[exp1var2] lt_set]);
  });

  it(@"should expose new experiments for existing users after stabilization was requested", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"Exp1Key1": @"foo",
      @"Exp1Key2": @"bar",
    };
    taplyticsProperties.allExperimentsToVariations = k1ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var2",
    };
    taplytics.properties = taplyticsProperties;

    [source stabilizeUserExperienceAssignments];

    taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"__Keys_ExistingUsersExp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"Exp1Key1": @"flip",
      @"Exp1Key2": @"flop",
      @"Exp2Key1": @"ding",
      @"Exp2Key2": @"dong"
    };
    taplyticsProperties.allExperimentsToVariations = kExistingExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var1",
      @"ExistingUsersExp2": @"Exp2Var2",
    };
    taplytics.properties = taplyticsProperties;

    auto exp1var2 = [[LABVariant alloc] initWithName:@"Exp1Var2"
                                         assignments:@{@"Exp1Key1": @"foo", @"Exp1Key2": @"bar"}
                                          experiment:@"Exp1"];
    auto exp2var2 = [[LABVariant alloc] initWithName:@"Exp2Var2"
                                         assignments:@{@"Exp2Key1": @"ding", @"Exp2Key2": @"dong"}
                                          experiment:@"ExistingUsersExp2"];
    expect(source.activeVariants).to.equal([@[exp1var2, exp2var2] lt_set]);
  });

  it(@"should not change experiments for existing users after stabilization was requested", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"Exp1Key1": @"foo",
      @"Exp1Key2": @"bar",
    };
    taplyticsProperties.allExperimentsToVariations = k1ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var2",
    };
    taplytics.properties = taplyticsProperties;

    [source stabilizeUserExperienceAssignments];

    taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"__Keys_ExistingUsersExp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"Exp1Key1": @"flip",
      @"Exp1Key2": @"flop",
      @"Exp2Key1": @"ding",
      @"Exp2Key2": @"dong"
    };
    taplyticsProperties.allExperimentsToVariations = kExistingExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var1",
      @"ExistingUsersExp2": @"Exp2Var2",
    };
    taplytics.properties = taplyticsProperties;

    auto exp1var2 = [[LABVariant alloc] initWithName:@"Exp1Var2"
                                         assignments:@{@"Exp1Key1": @"foo", @"Exp1Key2": @"bar"}
                                          experiment:@"Exp1"];
    auto exp2var2 = [[LABVariant alloc] initWithName:@"Exp2Var2"
                                         assignments:@{@"Exp2Key1": @"ding", @"Exp2Key2": @"dong"}
                                          experiment:@"ExistingUsersExp2"];
    expect(source.activeVariants).to.equal([@[exp1var2, exp2var2] lt_set]);

    taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"__Keys_ExistingUsersExp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"Exp1Key1": @"flip",
      @"Exp1Key2": @"flop",
      @"Exp2Key1": @"pong",
      @"Exp2Key2": @"bong"
    };
    taplyticsProperties.allExperimentsToVariations = kExistingExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var1",
      @"ExistingUsersExp2": @"Exp2Var1",
    };
    taplytics.properties = taplyticsProperties;

    expect(source.activeVariants).to.equal([@[exp1var2, exp2var2] lt_set]);
  });

  it(@"should not expose archived experiments even after stabilization was requested", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"__Keys_Exp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"Exp1Key1": @"foo",
      @"Exp1Key2": @"bar",
      @"Exp2Key1": @"baz",
      @"Exp2Key2": @"flu"
    };
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var2",
      @"Exp2": @"Exp2Var1",
    };
    taplytics.properties = taplyticsProperties;

    [source stabilizeUserExperienceAssignments];

    taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"Exp1Key1": @"foo",
      @"Exp1Key2": @"bar",
    };
    taplyticsProperties.allExperimentsToVariations = k1ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var1",
    };
    taplytics.properties = taplyticsProperties;

    auto exp1var2 = [[LABVariant alloc] initWithName:@"Exp1Var2"
                                         assignments:@{@"Exp1Key1": @"foo", @"Exp1Key2": @"bar"}
                                          experiment:@"Exp1"];
    expect(source.activeVariants).to.equal([@[exp1var2] lt_set]);
  });

  it(@"should update overriden keys after stabilization was requested", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"__Keys_Exp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"Exp1Key1": @"foo",
      @"Exp1Key2": @"bar",
      @"Exp2Key1": @"baz",
      @"Exp2Key2": @"flu"
    };
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var2",
      @"Exp2": @"Exp2Var1",
    };
    taplytics.properties = taplyticsProperties;

    [source stabilizeUserExperienceAssignments];

    taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_Exp1": @"[\"Exp1Key1\", \"Exp1Key2\"]",
      @"__Keys_Exp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"__Override_Exp1": @"[\"Exp1Key1\"]",
      @"Exp1Key1": @"flip",
      @"Exp1Key2": @"flop",
      @"Exp2Key1": @"ding",
      @"Exp2Key2": @"dong"
    };
    taplyticsProperties.allExperimentsToVariations = k3ExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"Exp1": @"Exp1Var1",
      @"Exp2": @"Exp2Var2",
    };
    taplytics.properties = taplyticsProperties;

    auto exp1var2 = [[LABVariant alloc] initWithName:@"Exp1Var2"
                                         assignments:@{@"Exp1Key1": @"flip", @"Exp1Key2": @"bar"}
                                          experiment:@"Exp1"];
    auto exp2var1 = [[LABVariant alloc] initWithName:@"Exp2Var1"
                                         assignments:@{@"Exp2Key1": @"baz", @"Exp2Key2": @"flu"}
                                          experiment:@"Exp2"];
    expect(source.activeVariants).to.equal([@[exp1var2, exp2var1] lt_set]);
  });

  it(@"should update overriden keys for existing users experiments after stabilization", ^{
    auto taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_ExistingUsersExp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"Exp2Key1": @"ding",
      @"Exp2Key2": @"dong"
    };
    taplyticsProperties.allExperimentsToVariations = kExistingExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"ExistingUsersExp2": @"Exp2Var2",
    };
    taplytics.properties = taplyticsProperties;

    [source stabilizeUserExperienceAssignments];

    taplyticsProperties = [[LABFakeTaplyticsProperties alloc] init];
    taplyticsProperties.activeDynamicVariables = @{
      @"__Keys_ExistingUsersExp2": @"[\"Exp2Key1\", \"Exp2Key2\"]",
      @"__Override_ExistingUsersExp2": @"[\"Exp2Key1\"]",
      @"Exp2Key1": @"pong",
      @"Exp2Key2": @"bong"
    };
    taplyticsProperties.allExperimentsToVariations = kExistingExperimentsToVariations;
    taplyticsProperties.activeExperimentsToVariations = @{
      @"ExistingUsersExp2": @"Exp2Var1",
    };
    taplytics.properties = taplyticsProperties;

    auto exp2var2 = [[LABVariant alloc] initWithName:@"Exp2Var2"
                                         assignments:@{@"Exp2Key1": @"pong", @"Exp2Key2": @"dong"}
                                          experiment:@"ExistingUsersExp2"];

    expect(source.activeVariants).to.equal([@[exp2var2] lt_set]);
  });
});

SpecEnd
