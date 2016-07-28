// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "RACSignal+CameraUI.h"

SpecBegin(RACSignal_CameraUI)

context(@"cui_unpack", ^{

  __block RACSubject *sender;

  beforeEach(^{
    sender = [[RACSubject alloc] init];
  });

  it(@"should raise an exception for no tuple", ^{
    LLSignalTestRecorder *recorder = [[sender cui_unpackFirst] testRecorder];
    expect(^{
      [sender sendNext:[[NSObject alloc] init]];
    }).to.raise(NSInvalidArgumentException);
    expect(recorder).to.sendValues(@[]);
  });

  context(@"signal with tuples of size one", ^{
    static NSNumber * const kValue0 = @0;
    static NSNumber * const kValue1 = @1;

    it(@"should unpack first", ^{
      LLSignalTestRecorder *recorder = [[sender cui_unpackFirst] testRecorder];
      [sender sendNext:RACTuplePack(kValue0)];
      [sender sendNext:RACTuplePack(kValue1)];
      expect(recorder).to.sendValues(@[kValue0, kValue1]);
    });

    it(@"should unpack 0", ^{
      LLSignalTestRecorder *recorder = [[sender cui_unpack:0] testRecorder];
      [sender sendNext:RACTuplePack(kValue0)];
      [sender sendNext:RACTuplePack(kValue1)];
      expect(recorder).to.sendValues(@[kValue0, kValue1]);
    });
  });

  context(@"signal with tuples of size 3", ^{
    static NSNumber * const kValue00 = @00;
    static NSNumber * const kValue01 = @01;
    static NSNumber * const kValue02 = @02;
    static NSNumber * const kValue10 = @10;
    static NSNumber * const kValue11 = @11;
    static NSNumber * const kValue12 = @12;
    static RACTuple * const kPack1 = RACTuplePack(kValue00, kValue01, kValue02);
    static RACTuple * const kPack2 = RACTuplePack(kValue10, kValue11, kValue12);

    it(@"should unpack first", ^{
      LLSignalTestRecorder *recorder = [[sender cui_unpackFirst] testRecorder];
      [sender sendNext:kPack1];
      [sender sendNext:kPack2];
      expect(recorder).to.sendValues(@[kValue00, kValue10]);
    });

    it(@"should unpack 1", ^{
      LLSignalTestRecorder *recorder = [[sender cui_unpack:1] testRecorder];
      [sender sendNext:kPack1];
      [sender sendNext:kPack2];
      expect(recorder).to.sendValues(@[kValue01, kValue11]);
    });

    it(@"should raise an exception for index out of bounds", ^{
      LLSignalTestRecorder *recorder = [[sender cui_unpack:3] testRecorder];
      expect(^{
        [sender sendNext:kPack1];
      }).to.raise(NSInvalidArgumentException);
      expect(recorder).to.sendValuesWithCount(0);
    });
  });

  context(@"completion", ^{
    it(@"should complete for unpack first", ^{
      LLSignalTestRecorder *recorder = [[sender cui_unpackFirst] testRecorder];
      [sender sendCompleted];
      expect(recorder).to.complete();
    });

    it(@"should complete for unpack", ^{
      LLSignalTestRecorder *recorder = [[sender cui_unpack:2] testRecorder];
      [sender sendCompleted];
      expect(recorder).to.complete();
    });
  });

  context(@"error", ^{
    static NSError * const kError = [NSError lt_errorWithCode:12];

    it(@"should error for unpack first", ^{
      LLSignalTestRecorder *recorder = [[sender cui_unpackFirst] testRecorder];
      [sender sendError:kError];
      expect(recorder).to.sendError(kError);
    });

    it(@"should error for unpack", ^{
      LLSignalTestRecorder *recorder = [[sender cui_unpack:2] testRecorder];
      [sender sendError:kError];
      expect(recorder).to.sendError(kError);
    });
  });
});

context(@"cui_and", ^{
  static NSError * const kError = [NSError lt_errorWithCode:12];

  __block RACSubject *left;
  __block RACSubject *right;

  beforeEach(^{
    left = [[RACSubject alloc] init];
    right = [[RACSubject alloc] init];
  });

  it(@"should raise when the receiver signal sends none NSNumber", ^{
    LLSignalTestRecorder *recorder = [[left cui_and:right] testRecorder];
    expect(^{
      [left sendNext:[[NSObject alloc] init]];
      [right sendNext:@(NO)];
    }).to.raise(NSInternalInconsistencyException);
    expect(recorder).to.sendValues(@[]);
  });

  it(@"should raise when the given signal sends none NSNumber", ^{
    LLSignalTestRecorder *recorder = [[left cui_and:right] testRecorder];
    expect(^{
      [left sendNext:@(NO)];
      [right sendNext:[[NSObject alloc] init]];
    }).to.raise(NSInternalInconsistencyException);
    expect(recorder).to.sendValues(@[]);
  });

  it(@"should send error when the receiver signal errs", ^{
    LLSignalTestRecorder *recorder = [[left cui_and:right] testRecorder];
    [left sendError:kError];
    expect(recorder).to.error();
  });

  it(@"should send error when the given signal errs", ^{
    LLSignalTestRecorder *recorder = [[left cui_and:right] testRecorder];
    [right sendError:kError];
    expect(recorder).to.error();
  });

  it(@"should not complete when only the receiver signal completes", ^{
    LLSignalTestRecorder *recorder = [[left cui_and:right] testRecorder];
    [left sendCompleted];
    expect(recorder).toNot.complete();
  });

  it(@"should not complete when only the given signal completes", ^{
    LLSignalTestRecorder *recorder = [[left cui_and:right] testRecorder];
    [right sendCompleted];
    expect(recorder).toNot.complete();
  });

  it(@"should complete when both signals complete", ^{
    LLSignalTestRecorder *recorder = [[left cui_and:right] testRecorder];
    [left sendCompleted];
    [right sendCompleted];
    expect(recorder).to.complete();
  });

  it(@"should send the results of the and operator on the signals correctly", ^{
    LLSignalTestRecorder *recorder = [[left cui_and:right] testRecorder];
    [left sendNext:@(YES)];
    [left sendNext:@(NO)];
    expect(recorder).to.sendValues(@[]);
    [right sendNext:@(NO)];
    expect(recorder).to.sendValues(@[@(NO)]);
    [right sendNext:@(NO)];
    expect(recorder).to.sendValues(@[@(NO), @(NO)]);
    [right sendNext:@(YES)];
    expect(recorder).to.sendValues(@[@(NO), @(NO), @(NO)]);
    [left sendNext:@(YES)];
    expect(recorder).to.sendValues(@[@(NO), @(NO), @(NO), @(YES)]);
    [right sendNext:@(NO)];
    expect(recorder).to.sendValues(@[@(NO), @(NO), @(NO), @(YES), @(NO)]);
  });
});

SpecEnd
