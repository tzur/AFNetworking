// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "NSError+Warehouse.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kWHSErrorAssociatedProjectIDKey = @"AssociatedProjectID";
NSString * const kWHSErrorAssociatedStepIDKey = @"AssociatedStepID";

@implementation NSError (Warehouse)

+ (instancetype)whs_errorWithCode:(NSInteger)code
              associatedProjectID:(nullable NSUUID *)associatedProjectID
                      description:(nullable NSString *)description, ... {
  NSString * _Nullable formattedDescription = nil;
  if (description) {
    va_list argList;
    va_start(argList, description);
    formattedDescription = [[NSString alloc] initWithFormat:nn(description) arguments:argList];
    va_end(argList);
  }
  return [NSError lt_errorWithCode:code userInfo:@{
    kWHSErrorAssociatedProjectIDKey: associatedProjectID ?: [NSNull null],
    kLTErrorDescriptionKey: formattedDescription ?: [NSNull null]
  }];
}

+ (instancetype)whs_errorWithCode:(NSInteger)code
              associatedProjectID:(nullable NSUUID *)associatedProjectID
                  underlyingError:(nullable NSError *)underlyingError
                      description:(nullable NSString *)description, ... {
  NSString * _Nullable formattedDescription = nil;
  if (description) {
    va_list argList;
    va_start(argList, description);
    formattedDescription = [[NSString alloc] initWithFormat:nn(description) arguments:argList];
    va_end(argList);
  }
  return [NSError lt_errorWithCode:code userInfo:@{
    kWHSErrorAssociatedProjectIDKey: associatedProjectID ?: [NSNull null],
    kLTErrorDescriptionKey: formattedDescription ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSError whs_nullValueGivenError]
  }];
}

+ (instancetype)whs_errorWithCode:(NSInteger)code
              associatedProjectID:(nullable NSUUID *)associatedProjectID
                 associatedStepID:(nullable NSUUID *)associatedStepID
                      description:(nullable NSString *)description, ... {
  NSString * _Nullable formattedDescription = nil;
  if (description) {
    va_list argList;
    va_start(argList, description);
    formattedDescription = [[NSString alloc] initWithFormat:nn(description) arguments:argList];
    va_end(argList);
  }
  return [NSError lt_errorWithCode:code userInfo:@{
    kWHSErrorAssociatedProjectIDKey: associatedProjectID ?: [NSNull null],
    kWHSErrorAssociatedStepIDKey: associatedStepID ?: [NSNull null],
    kLTErrorDescriptionKey: formattedDescription ?: [NSNull null]
  }];
}

+ (instancetype)whs_errorWithCode:(NSInteger)code
              associatedProjectID:(nullable NSUUID *)associatedProjectID
                 associatedStepID:(nullable NSUUID *)associatedStepID
                  underlyingError:(nullable NSError *)underlyingError
                      description:(nullable NSString *)description, ... {
  NSString * _Nullable formattedDescription = nil;
  if (description) {
    va_list argList;
    va_start(argList, description);
    formattedDescription = [[NSString alloc] initWithFormat:nn(description) arguments:argList];
    va_end(argList);
  }
  return [NSError lt_errorWithCode:code userInfo:@{
    kWHSErrorAssociatedProjectIDKey: associatedProjectID ?: [NSNull null],
    kWHSErrorAssociatedStepIDKey: associatedStepID ?: [NSNull null],
    kLTErrorDescriptionKey: formattedDescription ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSError whs_nullValueGivenError]
  }];
}

- (nullable NSUUID *)whs_associatedProjectID {
  return self.userInfo[kWHSErrorAssociatedProjectIDKey] != [NSNull null] ?
      self.userInfo[kWHSErrorAssociatedProjectIDKey] : nil;
}

- (nullable NSUUID *)whs_associatedStepID {
  return self.userInfo[kWHSErrorAssociatedStepIDKey] != [NSNull null] ?
      self.userInfo[kWHSErrorAssociatedStepIDKey] : nil;
}

+ (instancetype)whs_nullValueGivenError {
  return [NSError lt_errorWithCode:LTErrorCodeNullValueGiven];
}

@end

NS_ASSUME_NONNULL_END
