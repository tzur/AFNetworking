// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductContentFetcher.h"

#import <LTKit/LTPath.h>

#import "BZRProduct.h"
#import "BZRProductContentManager.h"
#import "BZRProductContentProvider.h"
#import "BZRProductEligibilityVerifier.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRProductContentFetcher)

__block BZRProductEligibilityVerifier *eligibilityVerifier;
__block id<BZRProductContentProvider> contentProvider;
__block BZRProductContentManager *contentManager;
__block BZRProductContentFetcher *contentFetcher;

beforeEach(^{
  eligibilityVerifier = OCMClassMock([BZRProductEligibilityVerifier class]);
  contentProvider = OCMProtocolMock(@protocol(BZRProductContentProvider));
  contentManager = OCMClassMock([BZRProductContentManager class]);
  contentFetcher = [[BZRProductContentFetcher alloc] initWithEligibilityVerifier:eligibilityVerifier
                                                                 contentProvider:contentProvider
                                                                  contentManager:contentManager];
});

context(@"deallocating object", ^{
  it(@"should not create retain cycle", ^{
    BZRProductContentFetcher __weak *weakFetcher;
    LLSignalTestRecorder *recorder;
    BZRProduct *product = BZRProductWithIdentifier(@"foo");

    @autoreleasepool {
      BZRProductContentFetcher *fetcher =
          [[BZRProductContentFetcher alloc] initWithEligibilityVerifier:eligibilityVerifier
              contentProvider:contentProvider contentManager:contentManager];
      weakFetcher = fetcher;
      recorder = [[fetcher fetchProductContent:product] testRecorder];
    }
    expect(weakFetcher).to.beNil();
  });
});

context(@"user is not eligible to use product", ^{
  beforeEach(^{
    OCMStub([eligibilityVerifier verifyEligibilityForProduct:OCMOCK_ANY])
        .andReturn([RACSignal return:@NO]);
  });

  it(@"should err when fetching content", ^{
    BZRProduct *product = BZRProductWithIdentifier(@"foo");

    RACSignal *fetchingContent = [contentFetcher fetchProductContent:product];

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

    LLSignalTestRecorder *recorder = [[contentFetcher fetchProductContent:product] testRecorder];

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

      LLSignalTestRecorder *recorder = [[contentFetcher fetchProductContent:product] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[path]);
    });

    it(@"should err when content provider errs", ^{
      NSError *fetchContentError = OCMClassMock([NSError class]);
      OCMStub([contentProvider fetchContentForProduct:OCMOCK_ANY])
          .andReturn([RACSignal error:fetchContentError]);

      RACSignal *fetchingContent = [contentFetcher fetchProductContent:product];

      expect(fetchingContent).will.sendError(fetchContentError);
    });

    it(@"should err when content manager errs", ^{
      LTPath *contentProviderPath = [LTPath pathWithPath:@"foo"];
      OCMStub([contentProvider fetchContentForProduct:OCMOCK_ANY])
          .andReturn([RACSignal return:contentProviderPath]);
      NSError *extractContentError = OCMClassMock([NSError class]);
      OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY])
          .andReturn([RACSignal error:extractContentError]);

      RACSignal *fetchingContent = [contentFetcher fetchProductContent:product];

      expect(fetchingContent).will.sendError(extractContentError);
    });

    it(@"should fetch and extract content if content directory doesn't exist", ^{
      LTPath *contentProviderPath = [LTPath pathWithPath:@"foo"];
      OCMStub([contentProvider fetchContentForProduct:OCMOCK_ANY])
          .andReturn([RACSignal return:contentProviderPath]);
      LTPath *extractedContentPath = [LTPath pathWithPath:@"bar"];
      OCMStub([contentManager extractContentOfProduct:OCMOCK_ANY fromArchive:OCMOCK_ANY])
          .andReturn([RACSignal return:extractedContentPath]);

      LLSignalTestRecorder *recorder = [[contentFetcher fetchProductContent:product] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[extractedContentPath]);
    });
  });
});

SpecEnd
