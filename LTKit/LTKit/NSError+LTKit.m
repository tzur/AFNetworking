// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSError+LTKit.h"

#import "NSObject+AddToContainer.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kLTKitErrorDomain = @"com.lightricks.LTKit";

NSString * const kLTErrorDescriptionKey = @"ErrorDescription";

NSString * const kLTFilePathErrorKey = @"FilePath";

NSString * const kLTErrnoErrorKey = @"Errno";

NSString * const kLTErrnoErrorMessageKey = @"ErrnoMessage";

@implementation NSError (LTKit)

#pragma mark -
#pragma mark File System Errors
#pragma mark -

+ (instancetype)lt_fileUknownErrorWithPath:(nullable NSString *)path
                           underlyingError:(nullable NSError *)error {
  return [self lt_fileErrorWithCode:LTErrorCodeFileUnknownError path:path underlyingError:error];
}

+ (instancetype)lt_fileNotFoundErrorWithPath:(nullable NSString *)path {
  return [self lt_fileErrorWithCode:LTErrorCodeFileNotFound path:path underlyingError:nil];
}

+ (instancetype)lt_fileAlreadyExistsErrorWithPath:(nullable NSString *)path {
  return [self lt_fileErrorWithCode:LTErrorCodeFileAlreadyExists path:path underlyingError:nil];
}

+ (instancetype)lt_fileReadFailedErrorWithPath:(nullable NSString *)path
                               underlyingError:(nullable NSError *)error {
  return [self lt_fileErrorWithCode:LTErrorCodeFileReadFailed path:path underlyingError:error];
}

+ (instancetype)lt_fileWriteFailedErrorWithPath:(nullable NSString *)path
                                underlyingError:(nullable NSError *)error {
  return [self lt_fileErrorWithCode:LTErrorCodeFileWriteFailed path:path underlyingError:error];
}

+ (instancetype)lt_fileRemovalFailedErrorWithPath:(nullable NSString *)path
                            underlyingError:(nullable NSError *)error {
  return [self lt_fileErrorWithCode:LTErrorCodeFileRemovalFailed path:path underlyingError:error];
}

+ (instancetype)lt_fileErrorWithCode:(NSInteger)code path:(nullable NSString *)path
                     underlyingError:(nullable NSError *)error {
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  [path setInDictionary:userInfo forKey:kLTFilePathErrorKey];
  [error setInDictionary:userInfo forKey:NSUnderlyingErrorKey];
  return [NSError errorWithDomain:kLTKitErrorDomain code:code userInfo:userInfo];
}

+ (instancetype)lt_errorWithSystemErrno {
  return [NSError errorWithDomain:kLTKitErrorDomain code:LTErrorCodePOSIX userInfo:@{
    kLTErrnoErrorKey: @(errno),
    kLTErrnoErrorMessageKey: @(strerror(errno))
  }];
}

+ (instancetype)lt_badFileHeaderErrorWithPath:(nullable NSString *)path
                                  description:(nullable NSString *)description {
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  [path setInDictionary:userInfo forKey:kLTFilePathErrorKey];
  [description setInDictionary:userInfo forKey:kLTErrorDescriptionKey];
  return [NSError errorWithDomain:kLTKitErrorDomain code:LTErrorCodeBadHeader userInfo:userInfo];
}

@end

NS_ASSUME_NONNULL_END
