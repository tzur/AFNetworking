// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACSignal+Photons.h"

#import <LTKit/LTProgress.h>

#import "PTNImageAsset.h"
#import "PTNImageMetadata.h"

SpecBegin(RACSignal_Photons)

context(@"ptn_replayLastLazily", ^{
  __block RACSubject *subject;
  __block RACSignal *lastLazily;

  beforeEach(^{
    subject = [RACSubject subject];
    lastLazily = [[subject ptn_replayLastLazily] startCountingSubscriptions];
  });

  it(@"should not subscribe to signal", ^{
    expect(lastLazily).to.beSubscribedTo(0);
  });

  it(@"should pass through all values sent after subscription", ^{
    LLSignalTestRecorder *recorder = [lastLazily testRecorder];

    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];

    expect(recorder.values).to.equal(@[@1, @2, @3]);
  });

  it(@"should replay only the last value sent to late subscribers", ^{
    [lastLazily subscribeNext:^(id __unused x) {}];

    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];
    LLSignalTestRecorder *recorder = [lastLazily testRecorder];

    expect(recorder.values).to.equal(@[@3]);
  });

  it(@"should replay last value and pass through all future values sent to late subscribers", ^{
    [lastLazily subscribeNext:^(id __unused x) {}];

    [subject sendNext:@1];
    [subject sendNext:@2];
    LLSignalTestRecorder *recorder = [lastLazily testRecorder];
    [subject sendNext:@3];

    expect(recorder.values).to.equal(@[@2, @3]);
  });

  it(@"should continue to operate regularly after reaching zero subscribers", ^{
    RACDisposable *earlySubscriber = [lastLazily subscribeNext:^(id __unused x) {}];

    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];

    expect(lastLazily).to.beSubscribedTo(1);
    [earlySubscriber dispose];
    LLSignalTestRecorder *recorder = [lastLazily testRecorder];
    expect(recorder.values).to.equal(@[@3]);
  });

  it(@"should not dispose its subscription to the source signal when its subscribers dispose", ^{
    __block BOOL wasDisposed = NO;
    __block NSMutableArray *subscribers = [NSMutableArray array];
    RACSignal *sourceSignal =
        [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          [subscribers addObject:subscriber];

          return [RACDisposable disposableWithBlock:^{
            [subscribers removeObject:subscriber];
            wasDisposed = YES;
          }];
        }];

    RACDisposable *sourceSubscriber = [sourceSignal subscribeNext:^(id __unused x) {}];
    RACDisposable *lastLazilySubscriber = [[sourceSignal
        ptn_replayLastLazily]
        subscribeNext:^(id __unused x) {}];

    [lastLazilySubscriber dispose];
    expect(wasDisposed).to.beFalsy();

    [sourceSubscriber dispose];
    expect(wasDisposed).to.beTruthy();
  });
});

context(@"ptn_wrapErrorWithError", ^{
  __block RACSubject *subject;
  __block NSError *underlyingError;

  beforeEach(^{
    underlyingError = [NSError lt_errorWithCode:1337];
    subject = [RACSubject subject];
  });

  it(@"should not alter values", ^{
    NSError *error = [NSError lt_errorWithCode:1337];

    LLSignalTestRecorder *recorder = [[subject ptn_wrapErrorWithError:error] testRecorder];

    [subject sendNext:@1];
    [subject sendNext:@2];
    [subject sendNext:@3];

    expect(recorder.values).to.equal(@[@1, @2, @3]);
  });

  it(@"should map errors without altering values", ^{
    NSError *error = [NSError lt_errorWithCode:1338 path:@"foo"];

    LLSignalTestRecorder *recorder = [[subject ptn_wrapErrorWithError:error] testRecorder];

    [subject sendError:underlyingError];

    expect(recorder.error.code).to.equal(error.code);
    expect(recorder.error.lt_path).to.equal(@"foo");
    expect(recorder.error.lt_underlyingError).to.equal(underlyingError);
  });

  it(@"should overwrite underlying error", ^{
    NSError *error = [NSError lt_errorWithCode:1338 path:@"foo"
                               underlyingError:[NSError lt_errorWithCode:1337]];

    LLSignalTestRecorder *recorder = [[subject ptn_wrapErrorWithError:error] testRecorder];

    [subject sendError:underlyingError];

    expect(recorder.error.code).to.equal(error.code);
    expect(recorder.error.lt_path).to.equal(@"foo");
    expect(recorder.error.lt_underlyingError).to.equal(underlyingError);
  });
});

context(@"ptn_combineLatestWithIndex", ^{
  __block RACSubject *subjectA;
  __block RACSubject *subjectB;

  beforeEach(^{
    subjectA = [RACSubject subject];
    subjectB = [RACSubject subject];
  });

  it(@"should send the latest values when all signals sent at least one next", ^{
    LLSignalTestRecorder *recorder = [[RACSignal ptn_combineLatestWithIndex:@[subjectA, subjectB]]
                                      testRecorder];

    [subjectA sendNext:@"a"];
    [subjectA sendNext:@"b"];
    [subjectA sendNext:@"c"];
    [subjectB sendNext:@1];

    expect(recorder).to.sendValues(@[RACTuplePack(RACTuplePack(@"c", @1), nil)]);
  });

  it(@"should send the latest values with the index of the signal that initiated them", ^{
    LLSignalTestRecorder *recorder = [[RACSignal ptn_combineLatestWithIndex:@[subjectA, subjectB]]
                                      testRecorder];

    [subjectA sendNext:@"a"];
    [subjectB sendNext:@1];
    [subjectB sendNext:@2];
    [subjectA sendNext:@"b"];

    expect(recorder).to.sendValues(@[
      RACTuplePack(RACTuplePack(@"a", @1), nil),
      RACTuplePack(RACTuplePack(@"a", @2), @1),
      RACTuplePack(RACTuplePack(@"b", @2), @0)
    ]);
  });

  it(@"should complete immediately when no signals are given", ^{
    expect([RACSignal ptn_combineLatestWithIndex:@[]]).to.complete();
  });

  it(@"should let errors through", ^{
    LLSignalTestRecorder *recorder = [[RACSignal ptn_combineLatestWithIndex:@[subjectA, subjectB]]
                                      testRecorder];

    [subjectA sendError:[NSError lt_errorWithCode:1337]];

    expect(recorder).to.sendError([NSError lt_errorWithCode:1337]);
  });

  it(@"should complete when all given signals complete", ^{
    LLSignalTestRecorder *recorder = [[RACSignal ptn_combineLatestWithIndex:@[subjectA, subjectB]]
                                      testRecorder];

    [subjectA sendCompleted];
    expect(recorder).toNot.complete();

    [subjectB sendCompleted];
    expect(recorder).to.complete();
  });
});

context(@"ptn_imageAndMetadata", ^{
  __block RACSubject *subject;
  __block LLSignalTestRecorder *recorder;
  __block id<PTNImageAsset> asset;
  __block UIImage *image;
  __block PTNImageMetadata *metadata;

  beforeEach(^{
    subject = [RACSubject subject];
    recorder = [[subject ptn_imageAndMetadata] testRecorder];
    asset = OCMProtocolMock(@protocol(PTNImageAsset));

    image = [[UIImage alloc] init];
    metadata = [[PTNImageMetadata alloc] init];
  });

  afterEach(^{
    [subject sendCompleted];
    subject = nil;
    recorder = nil;
  });

  it(@"should raise exception if the underlying signal sends unexpected values", ^{
    expect(^{
      [subject sendNext:@"foo"];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should ignore incomplete progress values", ^{
    [subject sendNext:[[LTProgress alloc] initWithProgress:0.5]];
    [subject sendNext:[[LTProgress alloc] initWithProgress:1]];

    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should send the underlying image and image metadata", ^{
    OCMStub([asset fetchImage]).andReturn([RACSignal return:image]);
    OCMStub([asset fetchImageMetadata]).andReturn([RACSignal return:metadata]);

    [subject sendNext:[[LTProgress alloc] initWithProgress:0.5]];
    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];
    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];

    expect(recorder).to.sendValues(@[RACTuplePack(image, metadata), RACTuplePack(image, metadata)]);
    expect(recorder).toNot.complete();
  });

  it(@"should send only the image and metadata from the latest image asset", ^{
    RACSubject *previousAssetImageSubject = [RACSubject subject];
    RACSubject *previousAssetMetadataSubject = [RACSubject subject];
    OCMStub([asset fetchImage]).andReturn(previousAssetImageSubject);
    OCMStub([asset fetchImageMetadata]).andReturn(previousAssetMetadataSubject);
    id<PTNImageAsset> latestAsset = OCMProtocolMock(@protocol(PTNImageAsset));
    OCMStub([latestAsset fetchImage]).andReturn([RACSignal return:image]);
    OCMStub([latestAsset fetchImageMetadata]).andReturn([RACSignal return:metadata]);

    [subject sendNext:[LTProgress progressWithResult:asset]];
    [subject sendNext:[LTProgress progressWithResult:latestAsset]];
    [previousAssetImageSubject sendNext:[[UIImage alloc] init]];
    [previousAssetMetadataSubject sendNext:[[PTNImageMetadata alloc] init]];

    expect(recorder).to.sendValues(@[RACTuplePack(image, metadata)]);
  });

  it(@"should complete when the underlying signal completes before sending a result", ^{
    [subject sendCompleted];
    expect(recorder).to.complete();
  });

  it(@"should complete when all underlying signals complete", ^{
    OCMStub([asset fetchImage]).andReturn([RACSignal return:image]);
    OCMStub([asset fetchImageMetadata]).andReturn([RACSignal return:metadata]);

    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];
    expect(recorder).toNot.complete();

    [subject sendCompleted];
    expect(recorder).to.complete();
  });

  it(@"should err if the underlying signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    [subject sendError:error];

    expect(recorder).to.sendError(error);
  });

  it(@"should err if the image signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([asset fetchImage]).andReturn([RACSignal error:error]);
    OCMStub([asset fetchImageMetadata]).andReturn([RACSignal return:metadata]);

    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];

    expect(recorder).to.sendError(error);
  });

  it(@"should err if the image metadata signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([asset fetchImage]).andReturn([RACSignal return:image]);
    OCMStub([asset fetchImageMetadata]).andReturn([RACSignal error:error]);

    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];

    expect(recorder).to.sendError(error);
  });
});

context(@"ptn_image", ^{
  __block RACSubject *subject;
  __block LLSignalTestRecorder *recorder;
  __block id<PTNImageAsset> asset;

  beforeEach(^{
    subject = [RACSubject subject];
    recorder = [[subject ptn_image] testRecorder];
    asset = OCMProtocolMock(@protocol(PTNImageAsset));
  });

  afterEach(^{
    [subject sendCompleted];
    subject = nil;
    recorder = nil;
  });

  it(@"should raise exception if the underlying signal sends unexpected values", ^{
    expect(^{
      [subject sendNext:@"foo"];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should ignore incomplete progress values", ^{
    [subject sendNext:[[LTProgress alloc] initWithProgress:0.5]];
    [subject sendNext:[[LTProgress alloc] initWithProgress:1]];

    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should send the underlying image", ^{
    UIImage *image = [[UIImage alloc] init];
    OCMStub([asset fetchImage]).andReturn([RACSignal return:image]);

    [subject sendNext:[[LTProgress alloc] initWithProgress:0.5]];
    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];
    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];

    expect(recorder).to.sendValues(@[image, image]);
    expect(recorder).toNot.complete();
  });

  it(@"should send only the image from the latest image asset", ^{
    RACSubject *previousAssetSubject = [RACSubject subject];
    UIImage *image = [[UIImage alloc] init];
    OCMStub([asset fetchImage]).andReturn(previousAssetSubject);
    id<PTNImageAsset> latestAsset = OCMProtocolMock(@protocol(PTNImageAsset));
    OCMStub([latestAsset fetchImage]).andReturn([RACSignal return:image]);

    [subject sendNext:[LTProgress progressWithResult:asset]];
    [subject sendNext:[LTProgress progressWithResult:latestAsset]];
    [previousAssetSubject sendNext:[[UIImage alloc] init]];

    expect(recorder).to.sendValues(@[image]);
  });

  it(@"should complete when the underlying signal completes before sending a result", ^{
    [subject sendCompleted];
    expect(recorder).to.complete();
  });

  it(@"should complete when the underlying signal completes and the image signal completes", ^{
    UIImage *image = [[UIImage alloc] init];
    OCMStub([asset fetchImage]).andReturn([RACSignal return:image]);

    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];
    expect(recorder).toNot.complete();

    [subject sendCompleted];
    expect(recorder).to.complete();
  });

  it(@"should err if the underlying signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    [subject sendError:error];

    expect(recorder).to.sendError(error);
  });

  it(@"should err if the image signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([asset fetchImage]).andReturn([RACSignal error:error]);

    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];

    expect(recorder).to.sendError(error);
  });
});

context(@"ptn_skipProgress", ^{
  __block RACSubject *subject;
  __block LLSignalTestRecorder *recorder;

  beforeEach(^{
    subject = [RACSubject subject];
    recorder = [[subject ptn_skipProgress] testRecorder];
  });

  it(@"should raise exception if the signal sends unexpected values", ^{
    expect(^{
      [subject sendNext:@"foo"];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should ignore incomplete progress values", ^{
    [subject sendNext:[[LTProgress alloc] initWithProgress:0.5]];
    [subject sendNext:[[LTProgress alloc] initWithProgress:0.1]];

    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should send the asset embedded in the completed progress value", ^{
    id<PTNImageAsset> asset = OCMProtocolMock(@protocol(PTNImageAsset));
    [subject sendNext:[[LTProgress alloc] initWithProgress:0.25]];
    [subject sendNext:[[LTProgress alloc] initWithProgress:0.5]];
    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];
    [subject sendNext:[[LTProgress alloc] initWithResult:asset]];

    expect(recorder).to.sendValues(@[asset, asset]);
    expect(recorder).toNot.complete();
  });

  it(@"should complete when the underlying signal completes", ^{
    [subject sendCompleted];
    expect(recorder).to.complete();
  });

  it(@"should err when the underlying signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    [subject sendError:error];

    expect(recorder).to.sendError(error);
  });
});

SpecEnd
