// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LTUTICache.h"

SpecBegin(LTUTICache)

__block id<LTMobileCoreServices> mobileCoreServices;
__block LTUTICache *utiCache;

beforeEach(^{
  mobileCoreServices = OCMProtocolMock(@protocol(LTMobileCoreServices));
  utiCache = [[LTUTICache alloc] initWithMobileCoreServices:mobileCoreServices];
});

it(@"should return the singleton object", ^{
  expect(LTUTICache.sharedCache).notTo.beNil();
});

context(@"UTI conformance", ^{
  it(@"should call only once to underlying api", ^{
    OCMExpect([mobileCoreServices isUTI:@"foo" conformsTo:@"bar"]).andReturn(YES);
    expect([utiCache isUTI:@"foo" conformsTo:@"bar"]).to.beTruthy();
    OCMReject([mobileCoreServices isUTI:@"foo" conformsTo:@"bar"]);
    expect([utiCache isUTI:@"foo" conformsTo:@"bar"]).to.beTruthy();
    OCMVerify([mobileCoreServices isUTI:@"foo" conformsTo:@"bar"]);
  });

  it(@"should not cache result if other parameter is used", ^{
    OCMExpect([mobileCoreServices isUTI:@"foo" conformsTo:@"bar"]).andReturn(YES);
    expect([utiCache isUTI:@"foo" conformsTo:@"bar"]).to.beTruthy();
    OCMExpect([mobileCoreServices isUTI:@"baz" conformsTo:@"bar"]).andReturn(NO);
    expect([utiCache isUTI:@"baz" conformsTo:@"bar"]).to.beFalsy();
    OCMVerifyAll(mobileCoreServices);
  });
});

context(@"preferredUTIForFileExtension", ^{
  it(@"should call only once to underlying api", ^{
    OCMExpect([mobileCoreServices preferredUTIForFileExtension:@"foo"]).andReturn(@"baz");
    expect([utiCache preferredUTIForFileExtension:@"foo"]).to.equal(@"baz");
    OCMReject([mobileCoreServices preferredUTIForFileExtension:@"foo"]);
    expect([utiCache preferredUTIForFileExtension:@"foo"]).to.equal(@"baz");
    OCMVerify([mobileCoreServices preferredUTIForFileExtension:@"foo"]);
  });

  it(@"should not cache result if other parameter is used", ^{
    OCMExpect([mobileCoreServices preferredUTIForFileExtension:@"foo"]).andReturn(@"baz");
    expect([utiCache preferredUTIForFileExtension:@"foo"]).to.equal(@"baz");
    OCMExpect([mobileCoreServices preferredUTIForFileExtension:@"bar"]).andReturn(@"flip");
    expect([utiCache preferredUTIForFileExtension:@"bar"]).to.equal(@"flip");
    OCMVerifyAll(mobileCoreServices);
  });
});

context(@"preferredUTIForMIMEType", ^{
  it(@"should call only once to underlying api", ^{
    OCMExpect([mobileCoreServices preferredUTIForMIMEType:@"foo"]).andReturn(@"baz");
    expect([utiCache preferredUTIForMIMEType:@"foo"]).to.equal(@"baz");
    OCMReject([mobileCoreServices preferredUTIForMIMEType:@"foo"]);
    expect([utiCache preferredUTIForMIMEType:@"foo"]).to.equal(@"baz");
    OCMVerify([mobileCoreServices preferredUTIForMIMEType:@"foo"]);
  });

  it(@"should not cache result if other parameter is used", ^{
    OCMExpect([mobileCoreServices preferredUTIForMIMEType:@"foo"]).andReturn(@"baz");
    expect([utiCache preferredUTIForMIMEType:@"foo"]).to.equal(@"baz");
    OCMExpect([mobileCoreServices preferredUTIForMIMEType:@"bar"]).andReturn(@"flip");
    expect([utiCache preferredUTIForMIMEType:@"bar"]).to.equal(@"flip");
    OCMVerifyAll(mobileCoreServices);
  });
});

context(@"preferredFileExtensionForUTI", ^{
  it(@"should call only once to underlying api", ^{
    OCMExpect([mobileCoreServices preferredFileExtensionForUTI:@"foo"]).andReturn(@"baz");
    expect([utiCache preferredFileExtensionForUTI:@"foo"]).to.equal(@"baz");
    OCMReject([mobileCoreServices preferredFileExtensionForUTI:@"foo"]);
    expect([utiCache preferredFileExtensionForUTI:@"foo"]).to.equal(@"baz");
    OCMVerify([mobileCoreServices preferredFileExtensionForUTI:@"foo"]);
  });

  it(@"should not cache result if other parameter is used", ^{
    OCMExpect([mobileCoreServices preferredFileExtensionForUTI:@"foo"]).andReturn(@"baz");
    expect([utiCache preferredFileExtensionForUTI:@"foo"]).to.equal(@"baz");
    OCMExpect([mobileCoreServices preferredFileExtensionForUTI:@"bar"]);
    expect([utiCache preferredFileExtensionForUTI:@"bar"]).to.beNil();
    OCMVerifyAll(mobileCoreServices);
  });
});

context(@"preferredFileExtensionForUTI", ^{
  it(@"should call only once to underlying api", ^{
    OCMExpect([mobileCoreServices preferredFileExtensionForUTI:@"foo"]).andReturn(@"baz");
    expect([utiCache preferredFileExtensionForUTI:@"foo"]).to.equal(@"baz");
    OCMReject([mobileCoreServices preferredFileExtensionForUTI:@"foo"]);
    expect([utiCache preferredFileExtensionForUTI:@"foo"]).to.equal(@"baz");
    OCMVerify([mobileCoreServices preferredFileExtensionForUTI:@"foo"]);
  });

  it(@"should not cache result if other parameter is used", ^{
    OCMExpect([mobileCoreServices preferredFileExtensionForUTI:@"foo"]).andReturn(@"baz");
    expect([utiCache preferredFileExtensionForUTI:@"foo"]).to.equal(@"baz");
    OCMExpect([mobileCoreServices preferredFileExtensionForUTI:@"bar"]);
    expect([utiCache preferredFileExtensionForUTI:@"bar"]).to.beNil();
    OCMVerifyAll(mobileCoreServices);
  });
});

context(@"preferredMIMETypeForUTI", ^{
  it(@"should call only once to underlying api", ^{
    OCMExpect([mobileCoreServices preferredMIMETypeForUTI:@"foo"]).andReturn(@"baz");
    expect([utiCache preferredMIMETypeForUTI:@"foo"]).to.equal(@"baz");
    OCMReject([mobileCoreServices preferredMIMETypeForUTI:@"foo"]);
    expect([utiCache preferredMIMETypeForUTI:@"foo"]).to.equal(@"baz");
    OCMVerify([mobileCoreServices preferredMIMETypeForUTI:@"foo"]);
  });

  it(@"should not cache result if other parameter is used", ^{
    OCMExpect([mobileCoreServices preferredMIMETypeForUTI:@"foo"]).andReturn(@"baz");
    expect([utiCache preferredMIMETypeForUTI:@"foo"]).to.equal(@"baz");
    OCMExpect([mobileCoreServices preferredMIMETypeForUTI:@"bar"]);
    expect([utiCache preferredMIMETypeForUTI:@"bar"]).to.beNil();
    OCMVerifyAll(mobileCoreServices);
  });
});

SpecEnd
