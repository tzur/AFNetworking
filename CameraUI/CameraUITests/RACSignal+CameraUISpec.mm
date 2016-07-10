// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "RACSignal+CameraUI.h"

SpecBegin(RACSignal_CameraUI)

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
  static NSNumber * const value0 = @0;
  static NSNumber * const value1 = @1;

  it(@"should unpack first", ^{
    LLSignalTestRecorder *recorder = [[sender cui_unpackFirst] testRecorder];
    [sender sendNext:RACTuplePack(value0)];
    [sender sendNext:RACTuplePack(value1)];
    expect(recorder).to.sendValues(@[value0, value1]);
  });

  it(@"should unpack 0", ^{
    LLSignalTestRecorder *recorder = [[sender cui_unpack:0] testRecorder];
    [sender sendNext:RACTuplePack(value0)];
    [sender sendNext:RACTuplePack(value1)];
    expect(recorder).to.sendValues(@[value0, value1]);
  });
});

context(@"signal with tuples of size 3", ^{
  static NSNumber * const value00 = @00;
  static NSNumber * const value01 = @01;
  static NSNumber * const value02 = @02;
  static NSNumber * const value10 = @10;
  static NSNumber * const value11 = @11;
  static NSNumber * const value12 = @12;
  static RACTuple * const pack1 = RACTuplePack(value00, value01, value02);
  static RACTuple * const pack2 = RACTuplePack(value10, value11, value12);

  it(@"should unpack first", ^{
    LLSignalTestRecorder *recorder = [[sender cui_unpackFirst] testRecorder];
    [sender sendNext:pack1];
    [sender sendNext:pack2];
    expect(recorder).to.sendValues(@[value00, value10]);
  });

  it(@"should unpack 1", ^{
    LLSignalTestRecorder *recorder = [[sender cui_unpack:1] testRecorder];
    [sender sendNext:pack1];
    [sender sendNext:pack2];
    expect(recorder).to.sendValues(@[value01, value11]);
  });

  it(@"should raise an exception for index out of bounds", ^{
    LLSignalTestRecorder *recorder = [[sender cui_unpack:3] testRecorder];
    expect(^{
      [sender sendNext:pack1];
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

SpecEnd
