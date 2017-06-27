// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABTaplytics.h"

#import "NSError+Laboratory.h"
#import "TLManager.h"
#import "TLProperties+Laboratory.h"

/// Fake manager to test changing properties.
@interface TLFakeManager : TLManager

/// Object containing the entire state of the Taplytics SDK.
///
/// @note This property is KVO-Compliant.
@property (readwrite, nonatomic, nullable) TLProperties *tlProperties;

@end

@implementation TLFakeManager
@synthesize tlProperties = _tlProperties;
@end

SpecBegin(LABTaplytics)

it(@"should expose nil properties if taplytics properties is nil", ^{
  TLFakeManager *tlManager = [[TLFakeManager alloc] init];
  LABTaplytics *taplytics = [[LABTaplytics alloc] initWithTLManager:tlManager];
  expect(taplytics.properties).to.beNil();

  TLProperties *tlProperties = OCMClassMock(TLProperties.class);
  auto allExperimentsAndVariations = @{
    @"exp1": @[@"exp1var1", @"exp1var2"],
    @"exp2": @[@"exp2var1", @"exp2var2"]
  };
  OCMStub([tlProperties appName]).andReturn(@"testApp");
  OCMStub([tlProperties lab_dynamicVariables]).andReturn(@{@"foo": @"bar"});
  OCMStub([tlProperties lab_allExperimentsAndVariations]).andReturn(allExperimentsAndVariations);
  OCMStub([tlProperties lab_runningExperimentsAndVariations]).andReturn(@{@"exp1": @"exp1var2"});
  OCMStub([tlProperties sessionID]).andReturn(@"1234567890abcdef");

  expect(taplytics.properties).to.beNil();
  tlManager.tlProperties = tlProperties;
  expect(taplytics.properties.activeDynamicVariables).to.equal(@{@"foo": @"bar"});
  expect(taplytics.properties.allExperimentsToVariations).to.equal(allExperimentsAndVariations);
  expect(taplytics.properties.activeExperimentsToVariations).to.equal(@{@"exp1": @"exp1var2"});

  tlManager.tlProperties = nil;
  expect(taplytics.properties).to.beNil();
});

context(@"fetch", ^{
  __block TLProperties *tlProperties;
  __block TLManager *tlManager;
  __block LABTaplytics *taplytics;

  beforeEach(^{
    tlManager = OCMClassMock(TLManager.class);
    tlProperties = OCMClassMock(TLProperties.class);
    taplytics = [[LABTaplytics alloc] initWithTLManager:tlManager];
  });

  context(@"properties fetch", ^{
    it(@"should fail if callback returns error", ^{
      OCMStub([tlManager getPropertiesFromServer:[OCMArg isNil]
                                     returnBlock:([OCMArg invokeBlockWithArgs:[NSNull null], @YES,
                                                   [NSError lt_errorWithCode:1337], nil])]);

      __block NSError *err;
      [taplytics fetchPropertiesWithCompletion:
          ^(id<LABTaplyticsProperties> _Nullable, NSError * _Nullable error) {
        err = error;
      }];

      auto expectedError = [NSError lt_errorWithCode:LABErrorCodeFetchFailed
                                     underlyingError:[NSError lt_errorWithCode:1337]];
      expect(err).to.equal(expectedError);
    });

    it(@"should fail if callback returns nil properties", ^{
      OCMStub([tlManager getPropertiesFromServer:[OCMArg isNil]
                                     returnBlock:([OCMArg invokeBlockWithArgs:[NSNull null], @YES,
                                                   [NSNull null], nil])]);

      __block NSError *err;
      [taplytics fetchPropertiesWithCompletion:
          ^(id<LABTaplyticsProperties> _Nullable, NSError * _Nullable error) {
        err = error;
      }];

      auto expectedError = [NSError lt_errorWithCode:LABErrorCodeFetchFailed underlyingError:nil];
      expect(err).to.equal(expectedError);
    });

    it(@"should return fetched assignments and complete", ^{
      TLProperties *variantTlProperties = OCMClassMock(TLProperties.class);
      auto allExperimentsAndVariations = @{
        @"exp1": @[@"exp1var1", @"exp1var2"],
        @"exp2": @[@"exp2var1", @"exp2var2"]
      };
      OCMStub([variantTlProperties appName]).andReturn(@"testApp");
      OCMStub([variantTlProperties lab_dynamicVariables]).andReturn(@{@"foo": @"bar"});
      OCMStub([variantTlProperties lab_allExperimentsAndVariations])
          .andReturn(allExperimentsAndVariations);
      OCMStub([variantTlProperties lab_runningExperimentsAndVariations])
          .andReturn(@{@"exp1": @"exp1var2"});

      OCMStub([tlManager getPropertiesFromServer:[OCMArg isNil]
                                     returnBlock:([OCMArg invokeBlockWithArgs:variantTlProperties,
                                                   @YES, [NSNull null], nil])]);

      __block id<LABTaplyticsProperties> props;
      [taplytics fetchPropertiesWithCompletion:
          ^(id<LABTaplyticsProperties> _Nullable properties, NSError * _Nullable) {
        props = properties;
      }];

      expect(props.activeDynamicVariables).to.equal(@{@"foo": @"bar"});
      expect(props.allExperimentsToVariations).to.equal(allExperimentsAndVariations);
      expect(props.activeExperimentsToVariations).to.equal(@{@"exp1": @"exp1var2"});
    });
  });

  context(@"properties fetch for experiment", ^{
    beforeEach(^{
      OCMStub([tlProperties lab_experimentIDForExperiment:@"exp2"]).andReturn(@"exp2_id");
      OCMStub([tlProperties lab_variationsIDForVariation:@"exp2var2" inExperiment:@"exp2"])
          .andReturn(@"exp2var2_id");
    });

    it(@"should fail if tlProperties is nil", ^{
      __block NSError *err;
      [taplytics fetchPropertiesForExperiment:@"exp2" withVariation:@"exp2var1"
                                   completion:^(id<LABTaplyticsProperties> _Nullable,
                                                NSError * _Nullable error) {
        err = error;
      }];

      auto expectedError = [NSError lab_errorWithCode:LABErrorCodeFetchFailed
                                 associatedExperiment:@"exp2" associatedVariant:@"exp2var1"];
      expect(err).to.equal(expectedError);
    });

    it(@"should fail if sessionID is nil", ^{
      OCMStub([tlManager tlProperties]).andReturn(tlProperties);

      __block NSError *err;
      [taplytics fetchPropertiesForExperiment:@"exp2" withVariation:@"exp2var1"
                                   completion:^(id<LABTaplyticsProperties> _Nullable,
                                                NSError * _Nullable error) {
        err = error;
      }];

      auto expectedError = [NSError lab_errorWithCode:LABErrorCodeFetchFailed
                                 associatedExperiment:@"exp2" associatedVariant:@"exp2var1"];
      expect(err).to.equal(expectedError);
    });

    it(@"should fail if the experiment doesn't exist", ^{
      OCMStub([tlProperties sessionID]).andReturn(@"1234567890abcdef");
      OCMStub([tlManager tlProperties]).andReturn(tlProperties);

      __block NSError *err;
      [taplytics fetchPropertiesForExperiment:@"exp3" withVariation:@"exp2var1"
          completion:^(id<LABTaplyticsProperties> _Nullable, NSError * _Nullable error) {
        err = error;
      }];

      auto expectedError = [NSError lab_errorWithCode:LABErrorCodeVariantForExperimentNotFound
                                 associatedExperiment:@"exp3" associatedVariant:@"exp2var1"];
      expect(err).to.equal(expectedError);
    });

    it(@"should fail if the variant doesn't exist", ^{
      OCMStub([tlProperties sessionID]).andReturn(@"1234567890abcdef");
      OCMStub([tlManager tlProperties]).andReturn(tlProperties);

      __block NSError *err;

      [taplytics fetchPropertiesForExperiment:@"exp2" withVariation:@"exp2var3"
          completion:^(id<LABTaplyticsProperties> _Nullable, NSError * _Nullable error) {
        err = error;
      }];

      auto expectedError = [NSError lab_errorWithCode:LABErrorCodeVariantForExperimentNotFound
                                 associatedExperiment:@"exp2" associatedVariant:@"exp2var3"];
      expect(err).to.equal(expectedError);
    });

    it(@"should fail if no session ID is nil", ^{
      __block NSError *err;
      [taplytics fetchPropertiesForExperiment:@"exp2" withVariation:@"exp2var2"
          completion:^(id<LABTaplyticsProperties> _Nullable, NSError * _Nullable error) {
        err = error;
      }];

      auto expectedError = [NSError lab_errorWithCode:LABErrorCodeFetchFailed
                                 associatedExperiment:@"exp2" associatedVariant:@"exp2var2"];
      expect(err).to.equal(expectedError);
    });

    it(@"should fail if callback returns error", ^{
      OCMStub([tlProperties sessionID]).andReturn(@"1234567890abcdef");
      OCMStub([tlManager tlProperties]).andReturn(tlProperties);

      OCMStub([tlManager getPropertiesFromServer:[OCMArg isNotNil]
                                     returnBlock:([OCMArg invokeBlockWithArgs:[NSNull null], @YES,
                                                   [NSError lt_errorWithCode:1337], nil])]);

      __block NSError *err;
      [taplytics fetchPropertiesForExperiment:@"exp2" withVariation:@"exp2var2"
          completion:^(id<LABTaplyticsProperties> _Nullable, NSError * _Nullable error) {
        err = error;
      }];

      auto expectedError = [NSError lab_errorWithCode:LABErrorCodeFetchFailed
                                 associatedExperiment:@"exp2" associatedVariant:@"exp2var2"
                                      underlyingError:[NSError lt_errorWithCode:1337]];
      expect(err).to.equal(expectedError);
    });

    it(@"should fail if callback returns nil properties", ^{
      OCMStub([tlProperties sessionID]).andReturn(@"1234567890abcdef");
      OCMStub([tlManager tlProperties]).andReturn(tlProperties);

      OCMStub([tlManager getPropertiesFromServer:[OCMArg isNotNil]
                                     returnBlock:([OCMArg invokeBlockWithArgs:[NSNull null], @YES,
                                                   [NSNull null], nil])]);

      __block NSError *err;
      [taplytics fetchPropertiesForExperiment:@"exp2" withVariation:@"exp2var2"
          completion:^(id<LABTaplyticsProperties> _Nullable, NSError * _Nullable error) {
        err = error;
      }];

      auto expectedError = [NSError lab_errorWithCode:LABErrorCodeFetchFailed
                                 associatedExperiment:@"exp2" associatedVariant:@"exp2var2"
                                      underlyingError:nil];
      expect(err).to.equal(expectedError);
    });

    it(@"should return fetched assignments and complete", ^{
      OCMStub([tlProperties sessionID]).andReturn(@"1234567890abcdef");
      OCMStub([tlManager tlProperties]).andReturn(tlProperties);

      TLProperties *variantTlProperties = OCMClassMock(TLProperties.class);
      auto allExperimentsAndVariations = @{
        @"exp1": @[@"exp1var1", @"exp1var2"],
        @"exp2": @[@"exp2var1", @"exp2var2"]
      };
      OCMStub([variantTlProperties appName]).andReturn(@"testApp");
      OCMStub([variantTlProperties lab_dynamicVariables]).andReturn(@{@"foo": @"bar"});
      OCMStub([variantTlProperties lab_allExperimentsAndVariations])
          .andReturn(allExperimentsAndVariations);
      OCMStub([variantTlProperties lab_runningExperimentsAndVariations])
          .andReturn(@{@"exp1": @"exp1var2"});

      OCMStub([tlManager getPropertiesFromServer:[OCMArg isNotNil]
                                     returnBlock:([OCMArg invokeBlockWithArgs:variantTlProperties,
                                                   @YES, [NSNull null], nil])]);

      __block id<LABTaplyticsProperties> props;
      [taplytics fetchPropertiesForExperiment:@"exp2" withVariation:@"exp2var2"
          completion:^(id<LABTaplyticsProperties> _Nullable properties, NSError * _Nullable) {
        props = properties;
      }];

      expect(props.activeDynamicVariables).to.equal(@{@"foo": @"bar"});
      expect(props.allExperimentsToVariations).to.equal(allExperimentsAndVariations);
      expect(props.activeExperimentsToVariations).to.equal(@{@"exp1": @"exp1var2"});
    });
  });
});

SpecEnd
