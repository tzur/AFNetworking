// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSError+Photons.h"

NS_ASSUME_NONNULL_BEGIN

NSString * kPTNErrorDomain = @"com.lightricks.Photons";
NSString * kPTNErrorRequestURLKey = @"URL";

@implementation NSError (Photons)

+ (NSError *)ptn_invalidURL:(NSURL *)url {
  return [NSError errorWithDomain:kPTNErrorDomain
                             code:PTNErrorCodeInvalidURL
                         userInfo:@{kPTNErrorRequestURLKey: url ?: [NSNull null]}];
}

+ (NSError *)ptn_albumNotFound:(NSURL *)url {
  return [NSError errorWithDomain:kPTNErrorDomain
                             code:PTNErrorCodeAlbumNotFound
                         userInfo:@{kPTNErrorRequestURLKey: url ?: [NSNull null]}];
}

@end

NS_ASSUME_NONNULL_END
