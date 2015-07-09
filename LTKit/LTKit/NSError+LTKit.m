// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSError+LTKit.h"

#import "NSObject+AddToContainer.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kLTKitErrorDomain = @"com.lightricks.LTKit";

NSString * const kLTUnderlyingErrorsKey = @"UnderlyingErrors";

NSString * const kLTErrorDescriptionKey = @"ErrorDescription";

NSString * const kLTSystemErrorKey = @"SystemError";

NSString * const kLTSystemErrorMessageKey = @"SystemErrorMessage";

@implementation NSError (LTKit)

#pragma mark -
#pragma mark File System Errors
#pragma mark -

+ (instancetype)lt_errorWithCode:(LTErrorCode)code {
  return [self lt_errorWithCode:code userInfo:nil];
}

+ (instancetype)lt_errorWithCode:(LTErrorCode)code userInfo:(nullable NSDictionary *)userInfo {
  return [NSError errorWithDomain:kLTKitErrorDomain code:code userInfo:userInfo];
}

+ (instancetype)lt_errorWithCode:(LTErrorCode)code underlyingError:(NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSUnderlyingErrorKey: underlyingError ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(LTErrorCode)code underlyingErrors:(NSArray *)underlyingErrors {
  return [NSError lt_errorWithCode:code userInfo:@{
    kLTUnderlyingErrorsKey: underlyingErrors ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(LTErrorCode)code description:(NSString *)description {
  return [NSError lt_errorWithCode:code userInfo:@{
    kLTErrorDescriptionKey: description ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(LTErrorCode)code path:(NSString *)path {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSFilePathErrorKey: path ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(LTErrorCode)code path:(NSString *)path
                 underlyingError:(NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSFilePathErrorKey: path ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(LTErrorCode)code url:(NSURL *)url {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSURLErrorKey: url ?: [NSNull null],
  }];
}

+ (instancetype)lt_errorWithCode:(LTErrorCode)code url:(NSURL *)url
                 underlyingError:(NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSURLErrorKey: url ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithSystemError {
  return [NSError errorWithDomain:kLTKitErrorDomain code:LTErrorCodePOSIX userInfo:@{
    kLTSystemErrorKey: @(errno),
    kLTSystemErrorMessageKey: @(strerror(errno))
  }];
}

- (nullable NSError *)lt_underlyingError {
  return [self valueOrNilForKey:NSUnderlyingErrorKey];
}

- (nullable NSArray *)lt_underlyingErrors {
  return [self valueOrNilForKey:kLTUnderlyingErrorsKey];
}

- (nullable NSString *)lt_description {
  return [self valueOrNilForKey:kLTErrorDescriptionKey];
}

- (nullable NSString *)lt_path {
  return [self valueOrNilForKey:NSFilePathErrorKey];
}

- (nullable NSString *)lt_url {
  return [self valueOrNilForKey:NSURLErrorKey];
}

- (nullable NSNumber *)lt_systemError {
  return [self valueOrNilForKey:kLTSystemErrorKey];
}

- (nullable NSString *)lt_systemErrorMessage {
  return [self valueOrNilForKey:kLTSystemErrorMessageKey];
}

- (nullable id)valueOrNilForKey:(NSString *)key {
  return self.userInfo[key] != [NSNull null] ? self.userInfo[key] : nil;
}

@end

NS_ASSUME_NONNULL_END
