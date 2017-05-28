// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSError+Laboratory.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kLABErrorAssociatedExperimentKey = @"AssociatedExperiment";
NSString * const kLABErrorAssociatedVariantKey = @"AssociatedVariant";
NSString * const kLABErrorAssociatedAssignmentKeyKey = @"AssociatedAssignmentKey";

@implementation NSError (Laboratory)

+ (instancetype)lab_errorWithCode:(NSInteger)code
             associatedExperiment:(NSString *)associatedExperiment {
  return [NSError lt_errorWithCode:code userInfo:@{
    kLABErrorAssociatedExperimentKey: associatedExperiment ?: [NSNull null]
  }];
}

+ (instancetype)lab_errorWithCode:(NSInteger)code
             associatedExperiment:(NSString *)associatedExperiment
                  underlyingError:(nullable NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    kLABErrorAssociatedExperimentKey: associatedExperiment ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSError lab_nullValueGivenError]
  }];
}

+ (instancetype)lab_errorWithCode:(NSInteger)code
                associatedVariant:(NSString *)associatedVariant {
  return [NSError lt_errorWithCode:code userInfo:@{
    kLABErrorAssociatedVariantKey: associatedVariant ?: [NSNull null]
  }];
}

+ (instancetype)lab_errorWithCode:(NSInteger)code
                associatedVariant:(NSString *)associatedVariant
                  underlyingError:(nullable NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    kLABErrorAssociatedVariantKey: associatedVariant ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSError lab_nullValueGivenError]
  }];
}

+ (instancetype)lab_errorWithCode:(NSInteger)code
          associatedAssignmentKey:(NSString *)associatedAssignmentKey {
  return [NSError lt_errorWithCode:code userInfo:@{
    kLABErrorAssociatedAssignmentKeyKey: associatedAssignmentKey ?: [NSNull null]
  }];
}

+ (instancetype)lab_errorWithCode:(NSInteger)code
             associatedExperiment:(NSString *)associatedExperiment
                associatedVariant:(NSString *)associatedVariant {
  return [NSError lt_errorWithCode:code userInfo:@{
    kLABErrorAssociatedExperimentKey: associatedExperiment ?: [NSNull null],
    kLABErrorAssociatedVariantKey: associatedVariant ?: [NSNull null]
  }];
}

+ (instancetype)lab_errorWithCode:(NSInteger)code
             associatedExperiment:(NSString *)associatedExperiment
                associatedVariant:(NSString *)associatedVariant
                  underlyingError:(nullable NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    kLABErrorAssociatedExperimentKey: associatedExperiment ?: [NSNull null],
    kLABErrorAssociatedVariantKey: associatedVariant ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSError lab_nullValueGivenError]
  }];
}

+ (instancetype)lab_nullValueGivenError {
  return [NSError lt_errorWithCode:LTErrorCodeNullValueGiven];
}

- (nullable NSString *)lab_associatedExperiment {
  return self.userInfo[kLABErrorAssociatedExperimentKey] != [NSNull null] ?
      self.userInfo[kLABErrorAssociatedExperimentKey] : nil;
}

- (nullable NSString *)lab_associatedVariant {
  return self.userInfo[kLABErrorAssociatedVariantKey] != [NSNull null] ?
      self.userInfo[kLABErrorAssociatedVariantKey] : nil;
}

- (nullable NSString *)lab_associatedAssignmentKey {
  return self.userInfo[kLABErrorAssociatedAssignmentKeyKey] != [NSNull null] ?
      self.userInfo[kLABErrorAssociatedAssignmentKeyKey] : nil;
}

@end

NS_ASSUME_NONNULL_END
