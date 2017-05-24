// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZROnDemandContentFetcher.h"

#import <Fiber/FBROnDemandResource.h>
#import <Fiber/NSBundle+OnDemandResources.h>

#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZROnDemandContentFetcher)

context(@"parameters conversion" , ^{
  __block NSArray<NSString *> *tags;

  beforeEach(^{
    tags = @[@"tag1", @"tag2"];
  });

  it(@"should correctly convert BZRLocalContentFetcherParameters instance to JSON dictionary", ^{
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZROnDemandContentFetcherParameters, type):
          [BZROnDemandContentFetcher class],
      @instanceKeypath(BZROnDemandContentFetcherParameters, tags): tags
    };

    NSError *error;
    BZROnDemandContentFetcherParameters *parameters =
        [[BZROnDemandContentFetcherParameters alloc] initWithDictionary:dictionaryValue
                                                                  error:&error];
    expect(error).to.beNil();

    NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:parameters];

    expect(JSONDictionary[@instanceKeypath(BZROnDemandContentFetcherParameters, tags)]).to
        .equal(tags);
  });

  it(@"should correctly convert from JSON dictionary to BZROnDemandContentFetcherParameters", ^{
    NSDictionary *JSONDictionary = @{
      @"type": @"BZROnDemandContentFetcher",
      @"tags": @[@"tag1", @"tag2"]
    };

    NSError *error;
    BZROnDemandContentFetcherParameters *parameters =
        [MTLJSONAdapter modelOfClass:[BZROnDemandContentFetcherParameters class]
                  fromJSONDictionary:JSONDictionary error:&error];
    expect(error).to.beNil();
    expect(parameters.tags).to.equal([NSSet setWithArray:tags]);
  });
});

context(@"expected parameters class", ^{
  it(@"should return a non-nil class from expectedParametersClass", ^{
    expect([BZROnDemandContentFetcher expectedParametersClass]).notTo.beNil();
  });
});

context(@"fetching products content", ^{
  __block NSBundle *bundle;
  __block BZROnDemandContentFetcher *fetcher;
  __block BZROnDemandContentFetcherParameters *parameters;
  __block BZRProduct *product;

  beforeEach(^{
    bundle = OCMClassMock([NSBundle class]);
    fetcher = [[BZROnDemandContentFetcher alloc] initWithBundle:bundle];
    parameters = OCMClassMock([BZROnDemandContentFetcherParameters class]);
    OCMStub([parameters tags]).andReturn(@[@"tag"]);
    product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
  });

  it(@"should send the fetching progress", ^{
    OCMStub([bundle fbr_beginAccessToResourcesWithTags:OCMOCK_ANY])
        .andReturn([RACSignal return:[[LTProgress alloc] initWithProgress:0.5]]);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.5]]);
  });

  it(@"should send bundle as the progress result when the content is available", ^{
    id<FBROnDemandResource> resource = OCMProtocolMock(@protocol(FBROnDemandResource));
    OCMStub([resource bundle]).andReturn(bundle);
    OCMStub([bundle fbr_beginAccessToResourcesWithTags:OCMOCK_ANY])
        .andReturn([RACSignal return:[[LTProgress alloc] initWithResult:resource]]);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.sendValues(@[[[LTProgress alloc] initWithResult:bundle]]);
  });

  it(@"should send error for invalid content fetcher parameters", ^{
    BZRContentFetcherParameters *parameters = OCMClassMock([BZRContentFetcherParameters class]);
    BZRProduct *product = BZRProductWithIdentifierAndParameters(@"foo", parameters);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidContentFetcherParameters;
    });
  });

  it(@"should send error when the resource signal sent error", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    RACSignal *errorSignal = [RACSignal error:error];
    OCMStub([bundle fbr_beginAccessToResourcesWithTags:OCMOCK_ANY]).andReturn(errorSignal);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.sendError(error);
  });
});

context(@"getting bundle of the product content", ^{
  __block NSBundle *bundle;
  __block BZROnDemandContentFetcher *fetcher;
  __block BZROnDemandContentFetcherParameters *parameters;
  __block BZRProduct *product;

  beforeEach(^{
    bundle = OCMClassMock([NSBundle class]);
    fetcher = [[BZROnDemandContentFetcher alloc] initWithBundle:bundle];
    parameters = OCMClassMock([BZROnDemandContentFetcherParameters class]);
    OCMStub([parameters tags]).andReturn([NSSet setWithObject:@"tag"]);
    product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
  });

  it(@"should return content bundle if the content exists", ^{
    id<FBROnDemandResource> resource = OCMProtocolMock(@protocol(FBROnDemandResource));
    OCMStub([resource bundle]).andReturn(bundle);
    LTPath *contentPath = [LTPath pathWithPath:@"bar"];
    OCMStub([bundle fbr_conditionallyBeginAccessToResourcesWithTags:[NSSet setWithObject:@"tag"]])
        .andReturn([RACSignal return:resource]);

    expect([fetcher contentBundleForProduct:product]).to
        .equal([NSBundle bundleWithPath:contentPath.path]);
  });

  it(@"should return nil if the content does not exist", ^{
    OCMStub([bundle fbr_conditionallyBeginAccessToResourcesWithTags:[NSSet setWithObject:@"tag"]])
        .andReturn([RACSignal return:nil]);

    expect([fetcher contentBundleForProduct:product]).to.beNil();
  });
});

SpecEnd
