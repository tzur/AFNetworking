// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSError+LTKit.h"

#import "LTErrorCodesRegistry.h"
#import "NSErrorCodes+LTKit.h"
#import "NSObject+AddToContainer.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kLTErrorDomain = @"com.lightricks";

NSString * const kLTUnderlyingErrorsKey = @"UnderlyingErrors";

NSString * const kLTErrorDescriptionKey = @"ErrorDescription";

NSString * const kLTSystemErrorKey = @"SystemError";

NSString * const kLTSystemErrorMessageKey = @"SystemErrorMessage";

NSString * const kLTExceptionNameKey = @"ExceptionName";

NSString *LTSystemErrorMessageForError(int error) {
  std::vector<char> message(1024);
  while (strerror_r(error, message.data(), message.size()) == ERANGE) {
    message.resize(message.size() * 2);
  }
  return nn(@(message.data()));
}

@implementation NSError (LTKit)

#pragma mark -
#pragma mark File System Errors
#pragma mark -

+ (instancetype)lt_errorWithCode:(NSInteger)code {
  return [self lt_errorWithCode:code userInfo:nil];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo {
  return [NSError errorWithDomain:kLTErrorDomain code:code
                         userInfo:[self lt_userInfo:userInfo withCodeDescription:code]];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code
                 underlyingError:(nullable NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSUnderlyingErrorKey: underlyingError ?: [NSError lt_nullValueGivenError]
  }];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code
                underlyingErrors:(NSArray<NSError *> *)underlyingErrors {
  return [NSError lt_errorWithCode:code userInfo:@{
    kLTUnderlyingErrorsKey: underlyingErrors ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code description:(NSString *)description, ... {
  va_list argList;
  va_start(argList, description);
  NSString *formattedDescription = [[NSString alloc] initWithFormat:description arguments:argList];
  va_end(argList);

  return [NSError lt_errorWithCode:code userInfo:@{
    kLTErrorDescriptionKey: formattedDescription ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code path:(NSString *)path {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSFilePathErrorKey: path ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code underlyingError:(nullable NSError *)underlyingError
                     description:(NSString *)description, ... {
  va_list argList;
  va_start(argList, description);
  NSString *formattedDescription = [[NSString alloc] initWithFormat:description arguments:argList];
  va_end(argList);

  return [NSError lt_errorWithCode:code userInfo:@{
    kLTErrorDescriptionKey: formattedDescription ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSError lt_nullValueGivenError]
  }];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code path:(NSString *)path
                 underlyingError:(nullable NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSFilePathErrorKey: path ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSError lt_nullValueGivenError]
  }];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code path:(NSString *)path
                underlyingErrors:(NSArray<NSError *> *)underlyingErrors {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSFilePathErrorKey: path ?: [NSNull null],
    kLTUnderlyingErrorsKey: underlyingErrors ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code path:(NSString *)path
                     description:(NSString *)description, ... {
  va_list argList;
  va_start(argList, description);
  NSString *formattedDescription = [[NSString alloc] initWithFormat:description arguments:argList];
  va_end(argList);

  return [NSError lt_errorWithCode:code userInfo:@{
    NSFilePathErrorKey: path ?: [NSNull null],
    kLTErrorDescriptionKey: formattedDescription ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code url:(NSURL *)url {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSURLErrorKey: url ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code url:(NSURL *)url
                     description:(NSString *)description, ... {
  va_list argList;
  va_start(argList, description);
  NSString *formattedDescription = [[NSString alloc] initWithFormat:description arguments:argList];
  va_end(argList);

  return [NSError lt_errorWithCode:code userInfo:@{
    NSURLErrorKey: url ?: [NSNull null],
    kLTErrorDescriptionKey: formattedDescription ?: [NSNull null]
  }];
}

+ (instancetype)lt_errorWithCode:(NSInteger)code url:(NSURL *)url
                 underlyingError:(nullable NSError *)underlyingError {
  return [NSError lt_errorWithCode:code userInfo:@{
    NSURLErrorKey: url ?: [NSNull null],
    NSUnderlyingErrorKey: underlyingError ?: [NSError lt_nullValueGivenError]
  }];
}

+ (instancetype)lt_errorWithException:(NSException *)exception {
  auto userInfo = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo ?: @{}];
  [userInfo addEntriesFromDictionary:@{
    kLTExceptionNameKey: exception.name,
    kLTErrorDescriptionKey: exception.description,
    NSLocalizedFailureReasonErrorKey: exception.reason ?: [NSNull null]
  }];

  return [NSError lt_errorWithCode:LTErrorCodeExceptionRaised userInfo:userInfo];
}

+ (instancetype)lt_errorWithSystemError {
  return [NSError errorWithDomain:kLTErrorDomain code:LTErrorCodePOSIX userInfo:@{
    kLTSystemErrorKey: @(errno),
    kLTSystemErrorMessageKey: LTSystemErrorMessageForError(errno)
  }];
}

+ (nullable NSDictionary *)lt_userInfo:(nullable NSDictionary *)userInfo
                   withCodeDescription:(NSInteger)code {
  NSString * _Nullable description = [[LTErrorCodesRegistry sharedRegistry]
                                      descriptionForErrorCode:code];
  if (!description) {
    return userInfo;
  }

  NSMutableDictionary *mutableUserInfo = userInfo ? [userInfo mutableCopy] :
      [NSMutableDictionary dictionary];
  mutableUserInfo[(NSString *)kCFErrorDescriptionKey] = description;
  return [mutableUserInfo copy];
}

+ (instancetype)lt_nullValueGivenError {
  return [NSError lt_errorWithCode:LTErrorCodeNullValueGiven];
}

- (BOOL)lt_isLTDomain {
  return [self.domain isEqualToString:kLTErrorDomain];
}

- (nullable NSError *)lt_underlyingError {
  return [self lt_valueOrNilForKey:NSUnderlyingErrorKey];
}

- (nullable NSArray<NSError *> *)lt_underlyingErrors {
  return [self lt_valueOrNilForKey:kLTUnderlyingErrorsKey];
}

- (nullable NSString *)lt_description {
  return [self lt_valueOrNilForKey:kLTErrorDescriptionKey];
}

- (nullable NSString *)lt_errorCodeDescription {
  return [self lt_valueOrNilForKey:(NSString *)kCFErrorDescriptionKey];
}

- (nullable NSString *)lt_path {
  return [self lt_valueOrNilForKey:NSFilePathErrorKey];
}

- (nullable NSString *)lt_url {
  return [self lt_valueOrNilForKey:NSURLErrorKey];
}

- (nullable NSNumber *)lt_systemError {
  return [self lt_valueOrNilForKey:kLTSystemErrorKey];
}

- (nullable NSString *)lt_systemErrorMessage {
  return [self lt_valueOrNilForKey:kLTSystemErrorMessageKey];
}

- (nullable id)lt_valueOrNilForKey:(NSString *)key {
  return self.userInfo[key] != [NSNull null] ? self.userInfo[key] : nil;
}

@end

NS_ASSUME_NONNULL_END
