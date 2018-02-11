// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIDocumentProvider.h"

#import "HUIDocument.h"

SpecBegin(HUIDocumentProvider)

__block NSBundle *bundle;
__block NSURL *helpURL;
__block HUIDocumentProvider *provider;

beforeEach(^{
  auto resourceName = @"HelpDocument";
  bundle = [NSBundle lt_testBundle];
  helpURL = [bundle URLForResource:resourceName withExtension:@"json"];
  LTAssert(helpURL, @"Couldn't load help document: %@ from bundle: %@", resourceName, bundle);

  provider = [[HUIDocumentProvider alloc] initWithBaseURL:bundle.bundleURL];
});

context(@"help document from path", ^{
  __block HUIDocument *expectedDocument;

  beforeEach(^{
    expectedDocument = [HUIDocument helpDocumentForJsonAtPath:helpURL.absoluteURL.path error:nil];
  });

  it(@"should send help document and complete for valid document name", ^{
    auto recorder = [[provider helpDocumentFromPath:@"Document"] testRecorder];
    expect(recorder).will.complete();
    expect(recorder).to.sendValues(@[expectedDocument]);
  });

  it(@"should send help document and complete for valid document name and invalid feature", ^{
    auto recorder = [[provider helpDocumentFromPath:@"NoSuchKey/Document"] testRecorder];
    expect(recorder).will.complete();
    expect(recorder.values).to.equal(@[expectedDocument]);
  });
});

it(@"should error for a path of invalid document names", ^{
  auto recorder =
      [[provider helpDocumentFromPath:@"NoSuchDocument1/NoSuchDocument2/NoSuchDocument3"]
       testRecorder];
  expect(recorder).will.error();
  expect(recorder.values).to.equal(@[]);
});

it(@"should deallocate after signal completes", ^{
  __weak HUIDocumentProvider *weakProvider = nil;
  @autoreleasepool {
    auto provider = [[HUIDocumentProvider alloc] initWithBaseURL:bundle.bundleURL];
    weakProvider = provider;
    auto helpDocument = [provider helpDocumentFromPath:@"Document"];
    expect(helpDocument).will.complete();
  }
  expect(weakProvider).to.beNil();
});

SpecEnd
