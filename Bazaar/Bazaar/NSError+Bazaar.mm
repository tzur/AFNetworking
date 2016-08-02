// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kBZRErrorExceptionKey = @"BZRErrorException";
NSString * const kBZRErrorProductsRequestKey = @"BZRErrorProductsRequest";
NSString * const kBZRErrorArchivePathKey = @"BZRErrorArchivePath";
NSString * const kBZRErrorFailingItemPathKey = @"BZRErrorFailingItemPathKey";

@implementation NSError (Bazaar)

+ (instancetype)bzr_errorWithCode:(NSInteger)code exception:(NSException *)exception {
  NSString *description = [NSString stringWithFormat:@"%@ exception raised, reason: %@",
                           exception.name, exception.reason];
  NSDictionary *userInfo = @{
    kBZRErrorExceptionKey: [exception copy],
    kLTErrorDescriptionKey: description
  };

  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

+ (instancetype)bzr_errorWithCode:(NSInteger)code productsRequest:(SKProductsRequest *)request
                  underlyingError:(NSError *)underlyingError {
  NSDictionary *userInfo = @{
    kBZRErrorProductsRequestKey: request,
    NSUnderlyingErrorKey: underlyingError
  };
  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

+ (instancetype)bzr_errorWithCode:(NSInteger)code
                      archivePath:(NSString *)archivePath
           failingArchiveItemPath:(nullable NSString *)failingItemPath
                  underlyingError:(nullable NSError *)underlyingError
                      description:(nullable NSString *)description {
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
  userInfo[kBZRErrorArchivePathKey] = archivePath;
  if (failingItemPath) {
    userInfo[kBZRErrorFailingItemPathKey] = [failingItemPath copy];
  }
  if (underlyingError) {
    userInfo[NSUnderlyingErrorKey] = [underlyingError copy];
  }
  if (description) {
    userInfo[kLTErrorDescriptionKey] = [description copy];
  }

  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

- (nullable NSException *)bzr_exception {
  return self.userInfo[kBZRErrorExceptionKey];
}

- (nullable SKProductsRequest *)bzr_productsRequest {
  return self.userInfo[kBZRErrorProductsRequestKey];
}

- (nullable NSString *)bzr_archivePath {
  return self.userInfo[kBZRErrorArchivePathKey];
}

- (nullable NSString *)bzr_failingItemPath {
  return self.userInfo[kBZRErrorFailingItemPathKey];
}

@end

NS_ASSUME_NONNULL_END
