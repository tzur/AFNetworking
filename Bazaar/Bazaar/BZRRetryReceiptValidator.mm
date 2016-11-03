// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRRetryReceiptValidator.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRRetryReceiptValidator ()

/// Validator used to validate the receipt.
@property (readonly, nonatomic) id<BZRReceiptValidator> underlyingValidator;

/// Specifying the delay between the first and second validation tries.
@property (nonatomic) NSTimeInterval initialRetryDelay;

/// Specifies the number of validation tries after the first try.
@property (nonatomic) NSUInteger numberOfRetries;

@end

@implementation BZRRetryReceiptValidator

- (instancetype)initWithUnderlyingValidator:(id<BZRReceiptValidator>)underlyingValidator
                          initialRetryDelay:(NSTimeInterval)initialRetryDelay
                            numberOfRetries:(NSUInteger)numberOfRetries {
  if (self = [super init]) {
    _underlyingValidator = underlyingValidator;
    _initialRetryDelay = initialRetryDelay;
    _numberOfRetries = numberOfRetries;
  }
  return self;
}

- (RACSignal *)validateReceiptWithParameters:(BZRReceiptValidationParameters *)parameters {
  if (!self.numberOfRetries) {
    return [self.underlyingValidator validateReceiptWithParameters:parameters];
  }
  __block NSTimeInterval secondsUntilNextRetry = self.initialRetryDelay;
  return [[[self.underlyingValidator validateReceiptWithParameters:parameters]
      catch:^RACSignal *(NSError *error) {
        RACSignal *delaySignal = [[[RACSignal empty]
            delay:secondsUntilNextRetry]
            concat:[RACSignal error:error]];
        secondsUntilNextRetry *= 2;
        return delaySignal;
      }]
      retry:self.numberOfRetries];
}

@end

NS_ASSUME_NONNULL_END
