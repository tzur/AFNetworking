// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "RACSignal+Mantle.h"

#import <Mantle/MTLJSONAdapter.h>
#import <Mantle/MTLModel.h>

#import "NSErrorCodes+Photons.h"

/// Mantle model conforming to \c MTLJSONSerializing for testing.
@interface PTNTestModel : MTLModel <MTLJSONSerializing>

/// Dummy property for testing.
@property (readonly, nonatomic) NSString *foo;

@end

@implementation PTNTestModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{@"foo": @"foo"};
}

@end

SpecBegin(RACSignal_Mantle)

it(@"should parse correctly", ^{
  NSDictionary<NSString *, NSString *> *expectedModel = @{@"foo": @"bar"};
  MTLModel *model = [MTLJSONAdapter modelOfClass:[PTNTestModel class]
                              fromJSONDictionary:expectedModel error:nil];
  RACSubject *subject = [RACSubject subject];
  LLSignalTestRecorder *recorder =
      [[subject ptn_parseDictionaryWithClass:[PTNTestModel class]] testRecorder];

  [subject sendNext:expectedModel];

  expect(recorder).to.sendValues(@[model]);
});

it(@"should send error when parsing fails", ^{
  RACSubject *subject = [RACSubject subject];
  LLSignalTestRecorder *recorder =
      [[subject ptn_parseDictionaryWithClass:[PTNTestModel class]] testRecorder];

  [subject sendNext:@[]];

  expect(recorder).to.matchError(^BOOL(NSError *error) {
    return error.lt_isLTDomain && error.code == PTNErrorCodeDeserializationFailed &&
        error.lt_underlyingError.domain == MTLJSONAdapterErrorDomain;
  });
});

SpecEnd
