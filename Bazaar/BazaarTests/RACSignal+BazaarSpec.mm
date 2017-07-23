// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "RACSignal+Bazaar.h"

#import "BZRModel.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

#pragma mark -
#pragma mark BZRDummyJSONSerializingModel
#pragma mark -

/// Dummy serializable model for testing.
@interface BZRDummyJSONSerializingModel : BZRModel <MTLJSONSerializing>

/// Requried value that must be present in serialized models.
@property (strong, nonatomic) NSString *requiredValue;

/// Optional value that may be present in serialized models.
@property (strong, nonatomic, nullable) id optionalValue;

@end

@implementation BZRDummyJSONSerializingModel

+ (NSSet<NSString *> *)optionalPropertyKeys {
  return [NSSet setWithObject:@instanceKeypath(BZRDummyJSONSerializingModel, optionalValue)];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRDummyJSONSerializingModel, requiredValue): @"value",
    @instanceKeypath(BZRDummyJSONSerializingModel, optionalValue): @"anotherValue"
  };
}

+ (instancetype)modelWithValue:(NSString *)value optionalValue:(nullable id)optionalValue {
  return [[self alloc] initWithValue:value optionalValue:optionalValue];
}

- (instancetype)initWithValue:(NSString *)value optionalValue:(nullable id)optionalValue {
  if (self = [super init]) {
    _requiredValue = value;
    _optionalValue = optionalValue;
  }
  return self;
}

@end

#pragma mark -
#pragma mark BZRDummyJSONSerializingExceptionRaisingModel
#pragma mark -

/// Dummy serializable model that raises exception when initialized from dictionary.
@interface BZRDummyJSONSerializingExceptionRaisingModel : BZRModel <MTLJSONSerializing>
@end

@implementation BZRDummyJSONSerializingExceptionRaisingModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

- (instancetype)initWithDictionary:(NSDictionary __unused *)dictionaryValue
                             error:(NSError __unused * __autoreleasing *)error {
  LTMethodNotImplemented();
}

@end

#pragma mark -
#pragma mark RACSignal+Bazaar Specs
#pragma mark -

SpecBegin(RACSignal_Bazaar)

NSString * const kRACSignalModelDeserializationExamples = @"RACSignal+BazaarSharedExamples";
NSString * const kRACSignalModelDeserializationSubjectKey = @"RACSignalModelDeserializationSubject";
NSString * const kRACSignalModelDeserializationRecorderKey =
    @"RACSignalModelDeserializationRecorder";
NSString * const kRACSignalModelDeserializationBlockKey = @"RACSignalModelDeserializationBlock";

/// Block used to call the deserialize operator with \c model class.
typedef RACSignal *(^BZRDeserializationBlock) (RACSignal *signal, Class model);

sharedExamplesFor(kRACSignalModelDeserializationExamples, ^(NSDictionary *data) {
  __block RACSubject *subject;
  __block LLSignalTestRecorder *recorder;
  __block BZRDeserializationBlock deserializeBlock;

  beforeEach(^{
    subject = data[kRACSignalModelDeserializationSubjectKey];
    recorder = data[kRACSignalModelDeserializationRecorderKey];
    deserializeBlock = data[kRACSignalModelDeserializationBlockKey];
  });

  it(@"should raise exception if the model class is invalid", ^{
    expect(^{
      deserializeBlock(subject, [NSObject class]);
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      deserializeBlock(subject, [BZRModel class]);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should complete when the underlying signal completes", ^{
    [subject sendCompleted];
    expect(recorder).to.complete();
  });

  it(@"should err when the underlying signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    [subject sendError:error];

    expect(recorder).to.matchError(^BOOL(NSError *signalError) {
      return [signalError isEqual:error];
    });
  });

  it(@"should err if the json dictionary specifies null value for required property", ^{
    BZRDummyJSONSerializingModel *model = [[BZRDummyJSONSerializingModel alloc] init];
    model.optionalValue = @"bar";
    NSDictionary *JSONDictionary = [MTLJSONAdapter JSONDictionaryFromModel:model];

    [subject sendNext:JSONDictionary];
    expect(recorder).to.matchError(^BOOL(NSError *signalError) {
      return signalError.lt_isLTDomain &&
          signalError.code == BZRErrorCodeModelJSONDeserializationFailed;
    });
  });

  it(@"should err if the json dictionary is missing a required property", ^{
    NSDictionary *JSONDictionary = @{@"foo": @"bar"};
    [subject sendNext:JSONDictionary];
    expect(recorder).to.matchError(^BOOL(NSError *signalError) {
      return signalError.lt_isLTDomain &&
          signalError.code == BZRErrorCodeModelJSONDeserializationFailed;
    });
  });

  it(@"should err if nil is sent by the underlying signal", ^{
    expect(^{
      [subject sendNext:nil];
    }).toNot.raiseAny();
    expect(recorder).to.matchError(^BOOL(NSError *signalError) {
      return signalError.lt_isLTDomain &&
      signalError.code == BZRErrorCodeModelJSONDeserializationFailed;
    });
  });

  it(@"should err if invalid json object is sent by the underlying signal", ^{
    expect(^{
      [subject sendNext:@[@"foo", @"bar"]];
    }).toNot.raiseAny();
    expect(recorder).to.matchError(^BOOL(NSError *signalError) {
      return signalError.lt_isLTDomain &&
      signalError.code == BZRErrorCodeModelJSONDeserializationFailed;
    });
  });
});

context(@"deserialize model operator", ^{
  itShouldBehaveLike(kRACSignalModelDeserializationExamples, ^{
    RACSubject *subject = [RACSubject subject];
    LLSignalTestRecorder *recorder = [[subject bzr_deserializeModel:
        [BZRDummyJSONSerializingModel class]] testRecorder];

    return @{
      kRACSignalModelDeserializationSubjectKey: subject,
      kRACSignalModelDeserializationRecorderKey: recorder,
      kRACSignalModelDeserializationBlockKey: ^RACSignal *(RACSignal *signal, Class model) {
        return [signal bzr_deserializeModel:model];
      }
    };
  });

  it(@"should err if an exception is raised during deserialization", ^{
    RACSubject *subject = [RACSubject subject];
    LLSignalTestRecorder *recorder = [[subject bzr_deserializeModel:
        [BZRDummyJSONSerializingExceptionRaisingModel class]] testRecorder];

    expect(^{
      [subject sendNext:@{}];
    }).toNot.raiseAny();
    expect(recorder).to.matchError(^BOOL(NSError *signalError) {
      return signalError.lt_isLTDomain &&
          signalError.code == BZRErrorCodeModelJSONDeserializationFailed &&
          [signalError.bzr_exception.name isEqualToString:NSInternalInconsistencyException];
    });
  });
});

context(@"deserialize array of models operator", ^{
  itShouldBehaveLike(kRACSignalModelDeserializationExamples, ^{
    RACSubject *subject = [RACSubject subject];
    LLSignalTestRecorder *recorder = [[subject bzr_deserializeArrayOfModels:
        [BZRDummyJSONSerializingModel class]] testRecorder];

    return @{
      kRACSignalModelDeserializationSubjectKey: subject,
      kRACSignalModelDeserializationRecorderKey: recorder,
      kRACSignalModelDeserializationBlockKey: ^RACSignal *(RACSignal *signal, Class model) {
        return [signal bzr_deserializeArrayOfModels:model];
      }
    };
  });

  it(@"should err if an exception is raised during deserialization", ^{
    RACSubject *subject = [RACSubject subject];
    LLSignalTestRecorder *recorder = [[subject bzr_deserializeArrayOfModels:
        [BZRDummyJSONSerializingExceptionRaisingModel class]] testRecorder];

    expect(^{
      [subject sendNext:@[@{}]];
    }).toNot.raiseAny();
    expect(recorder).to.matchError(^BOOL(NSError *signalError) {
      return signalError.lt_isLTDomain &&
      signalError.code == BZRErrorCodeModelJSONDeserializationFailed &&
      [signalError.bzr_exception.name isEqualToString:NSInternalInconsistencyException];
    });
  });
});

context(@"delayed retry", ^{
  static const NSTimeInterval kInitialRetryDelay = 0.0005;
  static const NSUInteger kNumberOfRetries = 2;

  it(@"should complete and send value immediatley when signal completes", ^{
    auto signal = [RACSignal return:@"foo"];

    auto recorder =
        [[signal delayedRetry:kNumberOfRetries initialDelay:kInitialRetryDelay] testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[@"foo"]);
  });

  it(@"should err if the signal erred on every try", ^{
    auto error = [NSError lt_errorWithCode:1337];
    __block NSUInteger currentRetryCount = 1;
    RACSignal *signal = [RACSignal defer:^RACSignal *{
      return [[RACSignal return:@(currentRetryCount++)] concat:[RACSignal error:error]];
    }];

    auto recorder =
        [[signal delayedRetry:kNumberOfRetries initialDelay:kInitialRetryDelay] testRecorder];

    expect(recorder).will.sendValues(@[@1, @2, @3]);
    expect(recorder).will.sendError(error);
  });

  it(@"should return error on second try if the number of given retries is one", ^{
    __block NSUInteger currentRetryCount = 1;
    RACSignal *signal = [RACSignal defer:^RACSignal *{
      auto error = [NSError lt_errorWithCode:currentRetryCount];
      return [[RACSignal return:@(currentRetryCount++)] concat:[RACSignal error:error]];
    }];

    auto recorder = [[signal delayedRetry:1 initialDelay:kInitialRetryDelay] testRecorder];

    expect(recorder).will.sendValues(@[@1, @2]);
    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return [error.domain isEqualToString:kLTErrorDomain] && error.code == 2;
    });
  });

  it(@"should complete when the signal completes on second try", ^{
    auto error = [NSError lt_errorWithCode:1337];
    auto signalRetriesList = @[
      [[RACSignal return:@1] concat:[RACSignal error:error]],
      [RACSignal return:@2],
      [RACSignal return:@3]
    ];

    __block NSUInteger signalIndex = 0;
    RACSignal *signal = [RACSignal defer:^RACSignal *{
      return signalRetriesList[signalIndex++];
    }];

    auto recorder =
        [[signal delayedRetry:kNumberOfRetries initialDelay:kInitialRetryDelay] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@1, @2]);
  });
});

SpecEnd
