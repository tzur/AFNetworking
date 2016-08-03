// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationStatus.h"

#import <LTKit/LTKeyPathCoding.h>
#import <LTKit/NSErrorCodes+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptValidationStatus

+ (NSSet<NSString *> *)nullablePropertyKeys {
  static NSSet<NSString *> *nullablePropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nullablePropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRReceiptValidationStatus, error),
      @instanceKeypath(BZRReceiptValidationStatus, receipt),
    ]];
  });

  return nullablePropertyKeys;
}

- (BOOL)validate:(NSError *__autoreleasing *)error {
  if (self.isValid && !self.receipt) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Receipt validation status indicates that the receipt "
                                          "is valid but receipt information is missing"];
    }
    return NO;
  }

  if (!self.isValid && !self.error) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Receipt validation status indicates that the receipt "
                                          "is invalid but validation error is missing"];
    }
    return NO;
  }

  return YES;
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

NS_ASSUME_NONNULL_END
