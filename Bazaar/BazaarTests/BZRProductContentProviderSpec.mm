// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentProvider.h"

#import <LTKit/LTPath.h>

#import "BZRProduct.h"
#import "BZRProductContentFetcher.h"
#import "BZRProductContentManager.h"
#import "BZRProductEligibilityVerifier.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRProductContentProvider)

__block BZRProductEligibilityVerifier *eligibilityVerifier;
__block id<BZRProductContentFetcher> contentFetcher;
__block BZRProductContentManager *contentManager;
__block BZRProductContentProvider *contentProvider;

beforeEach(^{
  eligibilityVerifier = OCMClassMock([BZRProductEligibilityVerifier class]);
  contentFetcher = OCMProtocolMock(@protocol(BZRProductContentFetcher));
  contentManager = OCMClassMock([BZRProductContentManager class]);
  contentProvider =
      [[BZRProductContentProvider alloc] initWithEligibilityVerifier:eligibilityVerifier
                                                      contentFetcher:contentFetcher
                                                      contentManager:contentManager];
});

context(@"deallocating object", ^{
  it(@"should not create retain cycle", ^{
    BZRProductContentProvider __weak *weakProvider;
    LLSignalTestRecorder *recorder;
    BZRProduct *product = BZRProductWithIdentifier(@"foo");

    @autoreleasepool {
      BZRProductContentProvider *provider =
          [[BZRProductContentProvider alloc] initWithEligibilityVerifier:eligibilityVerifier
                                                          contentFetcher:contentFetcher
                                                          contentManager:contentManager];
      weakProvider = provider;
      recorder = [[provider fetchProductContent:product] testRecorder];
    }
    expect(weakProvider).to.beNil();
  });
});

context(@"user is not eligible to use product", ^{
  beforeEach(^{
    OCMStub([eligibilityVerifier verifyEligibilityForProduct:OCMOCK_ANY])
        .andReturn([RACSignal return:@NO]);
  });

  it(@"should err when fetching content", ^{
    BZRProduct *product = BZRProductWithIdentifier(@"foo");

    RACSignal *fetchingContent = [contentProvider fetchProductContent:product];

    expect(fetchingContent).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeUserNotAllowedToUseProduct;
    });
  });
});

context(@"user eligibile to use product", ^{
  beforeEach(^{
    OCMStub([eligibilityVerifier verifyEligibilityForProduct:OCMOCK_ANY])
        .andReturn([RACSignal return:@YES]);
  });

  it(@"should complete when product has no content", ^{
    BZRProduct *product = BZRProductWithIdentifier(@"foo");

    LLSignalTestRecorder *recorder = [[contentProvider fetchProductContent:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValuesWithCount(0);
  });

  context(@"product with content", ^{
    __block BZRProduct *product;
    beforeEach(^{
      product = BZRProductWithIdentifierAndContent(@"foo");
    });

    it(@"should return path provided by content manager", ^{
      LTPath *path = [LTPath pathWithPath:@"foo"];
      OCMStub([contentManager pathToContentDirectoryOfProduct:@"foo"]).andReturn(path);

      LLSignalTestRecorder *recorder = [[contentProvider fetchProductContent:product] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[path]);
    });

    it(@"should err when content fetcher errs", ^{
      NSError *fetchContentError = OCMClassMock([NSError class]);
      OCMStub([contentFetcher fetchContentForProduct:OCMOCK_ANY])
          .andReturn([RACSignal error:fetchContentError]);

      RACSignal *fetchingContent = [contentProvider fetchProductContent:product];

      expect(fetchingContent).will.sendError(fetchContentError);
    });

    it(@"should err when content manager errs", ^{
      LTPath *contentFetcherPath = [LTPath pathWithPath:@"foo"];
      OCMStub([contentFetcher fetchContentForProduct:OCMOCK_ANY])
          .andReturn([RACSignal return:contentFetcherPath]);
      NSError *extractContentError = OCMClassMock([NSError class]);
      OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY])
          .andReturn([RACSignal error:extractContentError]);

      RACSignal *fetchingContent = [contentProvider fetchProductContent:product];

      expect(fetchingContent).will.sendError(extractContentError);
    });

    it(@"should fetch and extract content if content directory doesn't exist", ^{
      LTPath *contentProviderPath = [LTPath pathWithPath:@"foo"];
      OCMStub([contentFetcher fetchContentForProduct:OCMOCK_ANY])
          .andReturn([RACSignal return:contentProviderPath]);
      LTPath *extractedContentPath = [LTPath pathWithPath:@"bar"];
      OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY])
          .andReturn([RACSignal return:extractedContentPath]);

      LLSignalTestRecorder *recorder = [[contentProvider fetchProductContent:product] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[extractedContentPath]);
    });
  });
});

SpecEnd
