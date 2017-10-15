// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "RACSignal+CloudKitRetry.h"

#import <CloudKit/CloudKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRNonRetryableErrorWrapper
#pragma mark -

/// Wrapper class for \c NSError values that does not describe a retryable CloudKit error. This
/// class is used to wrap errors sent by the underlying signal and send them as values in order to
/// evade the \c retry operator applied to the signal.
@interface BZRNonRetryableErrorWrapper : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the wrapper with an \c error to wrap.
- (instancetype)initWithError:(NSError *)error NS_DESIGNATED_INITIALIZER;

/// Wrapped error.
@property (readonly, nonatomic) NSError *error;

@end

@implementation BZRNonRetryableErrorWrapper

- (instancetype)initWithError:(NSError *)error {
  if (self = [super init]) {
    _error = error;
  }
  return self;
}

@end

#pragma mark -
#pragma mark RACSignal+CloudKitRetry
#pragma mark -

@implementation RACSignal (CloudKitRetry)

- (instancetype)bzr_retryCloudKitErrorIfNeeded:(NSUInteger)retryCount {
  return [[[self
      catch:^RACSignal *(NSError *error) {
        NSNumber * _Nullable suggestedRetryDelay = error.userInfo[CKErrorRetryAfterKey];
        if (suggestedRetryDelay) {
          NSTimeInterval retryDelay = suggestedRetryDelay.doubleValue;
          return [[[RACSignal empty]
              delay:retryDelay]
              concat:[RACSignal error:error]];
        }

        return [RACSignal return:[[BZRNonRetryableErrorWrapper alloc] initWithError:error]];
      }]
      retry:retryCount]
      flattenMap:^RACSignal *(id value) {
        if ([value isKindOfClass:[BZRNonRetryableErrorWrapper class]]) {
          BZRNonRetryableErrorWrapper *errorWrapper = value;
          return [RACSignal error:errorWrapper.error];
        } else {
          return [RACSignal return:value];
        }
      }];
}

@end

NS_ASSUME_NONNULL_END
