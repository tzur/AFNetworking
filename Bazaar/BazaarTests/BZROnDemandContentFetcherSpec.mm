// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZROnDemandContentFetcher.h"

#import <Fiber/FBROnDemandResource.h>
#import <Fiber/NSBundle+OnDemandResources.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "BZRProduct.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZROnDemandContentFetcher)

context(@"expected parameters class", ^{
  it(@"should return a non-nil class from expectedParametersClass", ^{
    expect([BZROnDemandContentFetcher expectedParametersClass]).notTo.beNil();
  });
});

context(@"fetching products content", ^{
  __block NSBundle *bundle;
  __block NSFileManager *fileManager;
  __block BZROnDemandContentFetcher *fetcher;
  __block BZROnDemandContentFetcherParameters *parameters;
  __block NSString *checksum;
  __block BZRProduct *product;

  beforeEach(^{
    bundle = OCMClassMock([NSBundle class]);
    fileManager = OCMClassMock([NSFileManager class]);
    fetcher = [[BZROnDemandContentFetcher alloc] initWithBundle:bundle fileManager:fileManager];
    parameters = OCMClassMock([BZROnDemandContentFetcherParameters class]);
    checksum = @"41dbb5e299ddf150a4952cd26c9c0331";
    OCMStub([parameters tags]).andReturn(@[@"tag"]);
    OCMStub([parameters checksum]).andReturn(checksum);
    product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
  });

  it(@"should send the fetching progress", ^{
    OCMStub([bundle fbr_beginAccessToResourcesWithTags:OCMOCK_ANY])
        .andReturn([RACSignal return:[[LTProgress alloc] initWithProgress:0.5]]);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.5]]);
  });

  it(@"should send bundle as the progress result when the content is available and passed checksum "
     "validation", ^{
    id<FBROnDemandResource> resource = OCMProtocolMock(@protocol(FBROnDemandResource));
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg anyObjectRef]])
        .andReturn([checksum dataUsingEncoding:NSUTF8StringEncoding]);
    OCMStub([resource bundle]).andReturn(bundle);
    OCMStub([bundle fbr_beginAccessToResourcesWithTags:OCMOCK_ANY])
        .andReturn([RACSignal return:[[LTProgress alloc] initWithResult:resource]]);
    OCMStub([bundle pathForResource:product.identifier ofType:@"checksum"]).andReturn(@"bar");

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

  it(@"should err if checksum file does not exist", ^{
    id<FBROnDemandResource> resource = OCMProtocolMock(@protocol(FBROnDemandResource));
    OCMStub([bundle pathForResource:product.identifier ofType:@"checksum"]);
    OCMStub([resource bundle]).andReturn(bundle);
    OCMStub([bundle fbr_beginAccessToResourcesWithTags:OCMOCK_ANY])
        .andReturn([RACSignal return:[[LTProgress alloc] initWithResult:resource]]);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeFetchedContentMismatch;
    });
  });

  it(@"should err if failed to read data from the checksum file", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    id<FBROnDemandResource> resource = OCMProtocolMock(@protocol(FBROnDemandResource));
    OCMStub([bundle pathForResource:product.identifier ofType:@"checksum"]).andReturn(@"bar");
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg setTo:error]]);
    OCMStub([resource bundle]).andReturn(bundle);
    OCMStub([bundle fbr_beginAccessToResourcesWithTags:OCMOCK_ANY])
        .andReturn([RACSignal return:[[LTProgress alloc] initWithResult:resource]]);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeFetchedContentMismatch &&
          error.lt_underlyingError.code == 1337;
    });
  });

  it(@"should err if the content was fetched but the checksum failed", ^{
    id<FBROnDemandResource> resource = OCMProtocolMock(@protocol(FBROnDemandResource));
    OCMStub([bundle pathForResource:product.identifier ofType:@"checksum"]).andReturn(@"bar");
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg anyObjectRef]])
        .andReturn([@"invalid" dataUsingEncoding:NSUTF8StringEncoding]);
    OCMStub([resource bundle]).andReturn(bundle);
    OCMStub([bundle fbr_beginAccessToResourcesWithTags:OCMOCK_ANY])
        .andReturn([RACSignal return:[[LTProgress alloc] initWithResult:resource]]);

    RACSignal *signal = [fetcher fetchProductContent:product];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeFetchedContentMismatch;
    });
  });
});

context(@"getting bundle of the product content", ^{
  __block NSBundle *bundle;
  __block NSFileManager *fileManager;
  __block BZROnDemandContentFetcher *fetcher;
  __block BZROnDemandContentFetcherParameters *parameters;
    __block NSString *checksum;
  __block BZRProduct *product;

  beforeEach(^{
    bundle = OCMClassMock([NSBundle class]);
    fileManager = OCMClassMock([NSFileManager class]);
    fetcher = [[BZROnDemandContentFetcher alloc] initWithBundle:bundle fileManager:fileManager];
    parameters = OCMClassMock([BZROnDemandContentFetcherParameters class]);
    checksum = @"41dbb5e299ddf150a4952cd26c9c0331";
    OCMStub([parameters tags]).andReturn([NSSet setWithObject:@"tag"]);
    OCMStub([parameters checksum]).andReturn(checksum);
    product = BZRProductWithIdentifierAndParameters(@"foo", parameters);
  });

  it(@"should send nil if the content fetcher parameters are invalid", ^{
    auto parameters = [[BZRContentFetcherParameters alloc] initWithDictionary:@{
      @"type": NSStringFromClass([BZRContentFetcherParameters class])
    } error:nil];
    auto product = BZRProductWithIdentifierAndParameters(@"foo", parameters);

    auto recorder = [[fetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[[NSNull null]]);
  });

  it(@"should send content bundle if the content exists and passed checksum validation", ^{
    id<FBROnDemandResource> resource = OCMProtocolMock(@protocol(FBROnDemandResource));
    OCMStub([bundle pathForResource:product.identifier ofType:@"checksum"]).andReturn(@"bar");
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg anyObjectRef]])
        .andReturn([checksum dataUsingEncoding:NSUTF8StringEncoding]);
    OCMStub([resource bundle]).andReturn(bundle);
    OCMStub([bundle fbr_conditionallyBeginAccessToResourcesWithTags:[NSSet setWithObject:@"tag"]])
        .andReturn([RACSignal return:resource]);

    auto recorder = [[fetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[bundle]);
  });

  it(@"should send nil if the content does not exist", ^{
    OCMStub([bundle fbr_conditionallyBeginAccessToResourcesWithTags:[NSSet setWithObject:@"tag"]])
        .andReturn([RACSignal return:nil]);

    auto recorder = [[fetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[[NSNull null]]);
  });

  it(@"should send nil if checksum file does not exist", ^{
    id<FBROnDemandResource> resource = OCMProtocolMock(@protocol(FBROnDemandResource));
    OCMStub([bundle pathForResource:product.identifier ofType:@"checksum"]);
    OCMStub([resource bundle]).andReturn(bundle);
    OCMStub([bundle fbr_conditionallyBeginAccessToResourcesWithTags:[NSSet setWithObject:@"tag"]])
        .andReturn([RACSignal return:resource]);

     auto recorder = [[fetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[[NSNull null]]);
  });

  it(@"should send nil if failed to read data from the checksum file", ^{
    id<FBROnDemandResource> resource = OCMProtocolMock(@protocol(FBROnDemandResource));
    OCMStub([bundle pathForResource:product.identifier ofType:@"checksum"]).andReturn(@"bar");
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg anyObjectRef]]);
    OCMStub([resource bundle]).andReturn(bundle);
    OCMStub([bundle fbr_conditionallyBeginAccessToResourcesWithTags:[NSSet setWithObject:@"tag"]])
        .andReturn([RACSignal return:resource]);

     auto recorder = [[fetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[[NSNull null]]);
  });

  it(@"should send nil if the content exists but the checksum failed", ^{
    id<FBROnDemandResource> resource = OCMProtocolMock(@protocol(FBROnDemandResource));
    OCMStub([bundle pathForResource:product.identifier ofType:@"checksum"]).andReturn(@"bar");
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg anyObjectRef]])
        .andReturn([@"invalid" dataUsingEncoding:NSUTF8StringEncoding]);
    OCMStub([resource bundle]).andReturn(bundle);
    OCMStub([bundle fbr_conditionallyBeginAccessToResourcesWithTags:[NSSet setWithObject:@"tag"]])
        .andReturn([RACSignal return:resource]);

    auto recorder = [[fetcher contentBundleForProduct:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[[NSNull null]]);
  });
});

SpecEnd

SpecBegin(BZROnDemandContentFetcherParameters)

__block NSArray<NSString *> *tags;
__block NSString *checksum;

beforeEach(^{
  tags = @[@"tag1", @"tag2"];
  checksum = @"41dbb5e299ddf150a4952cd26c9c0331";
});

it(@"should correctly convert BZROnDemandContentFetcherParameters instance to JSON dictionary", ^{
  auto dictionaryValue = @{
    @instanceKeypath(BZROnDemandContentFetcherParameters, type): @"BZROnDemandContentFetcher",
    @instanceKeypath(BZROnDemandContentFetcherParameters, tags): tags,
    @instanceKeypath(BZROnDemandContentFetcherParameters, checksum): checksum
  };

  NSError *error;
  auto parameters = [[BZROnDemandContentFetcherParameters alloc] initWithDictionary:dictionaryValue
                                                                              error:&error];
  expect(error).to.beNil();

  auto JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:parameters];
  expect(JSONDictionary[@instanceKeypath(BZROnDemandContentFetcherParameters, tags)]).to
      .equal(tags);
  expect(JSONDictionary[@instanceKeypath(BZROnDemandContentFetcherParameters, checksum)]).to
      .equal(checksum);
});

it(@"should correctly convert from JSON dictionary to BZROnDemandContentFetcherParameters", ^{
  auto JSONDictionary = @{
    @"type": @"BZROnDemandContentFetcher",
    @"tags": tags,
    @"checksum": @"41dbb5e299ddf150a4952cd26c9c0331"
  };

  NSError *error;
  BZROnDemandContentFetcherParameters *parameters =
      [MTLJSONAdapter modelOfClass:[BZROnDemandContentFetcherParameters class]
                fromJSONDictionary:JSONDictionary error:&error];

  expect(error).to.beNil();
  expect(parameters.tags).to.equal([NSSet setWithArray:tags]);
  expect(parameters.checksum).to.equal(checksum);
});

SpecEnd
