// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSError+Photons.h"

NS_ASSUME_NONNULL_BEGIN

NSString * kPTNErrorDomain = @"com.lightricks.Photons";

NSString * kPTNErrorRequestURLKey = @"URL";
NSString * kPTNErrorAssociatedObjectKey = @"AssociatedObject";

@implementation NSError (Photons)

+ (instancetype)ptn_invalidURL:(NSURL *)url {
  return [NSError errorWithDomain:kPTNErrorDomain
                             code:PTNErrorCodeInvalidURL
                         userInfo:@{kPTNErrorRequestURLKey: url ?: [NSNull null]}];
}

+ (instancetype)ptn_albumNotFound:(NSURL *)url {
  return [NSError errorWithDomain:kPTNErrorDomain
                             code:PTNErrorCodeAlbumNotFound
                         userInfo:@{kPTNErrorRequestURLKey: url ?: [NSNull null]}];
}

+ (instancetype)ptn_assetNotFound:(NSURL *)url {
  return [NSError errorWithDomain:kPTNErrorDomain
                             code:PTNErrorCodeAssetNotFound
                         userInfo:@{kPTNErrorRequestURLKey: url ?: [NSNull null]}];
}

+ (instancetype)ptn_keyAssetsNotFound:(NSURL *)url {
  return [NSError errorWithDomain:kPTNErrorDomain
                             code:PTNErrorCodeKeyAssetsNotFound
                         userInfo:@{kPTNErrorRequestURLKey: url ?: [NSNull null]}];
}

+ (instancetype)ptn_assetLoadingFailed:(NSURL *)url {
  return [NSError errorWithDomain:kPTNErrorDomain
                             code:PTNErrorCodeAssetLoadingFailed
                         userInfo:@{kPTNErrorRequestURLKey: url ?: [NSNull null]}];
}

+ (instancetype)ptn_assetLoadingFailed:(NSURL *)url underlyingError:(NSError *)error {
  return [NSError errorWithDomain:kPTNErrorDomain
                             code:PTNErrorCodeAssetLoadingFailed
                         userInfo:@{kPTNErrorRequestURLKey: url ?: [NSNull null],
                                    NSUnderlyingErrorKey: error ?: [NSNull null]}];
}

+ (instancetype)ptn_invalidAssetType:(NSURL *)url {
  return [NSError errorWithDomain:kPTNErrorDomain
                             code:PTNErrorCodeInvalidAssetType
                         userInfo:@{kPTNErrorRequestURLKey: url ?: [NSNull null]}];
}

+ (instancetype)ptn_invalidObject:(id<NSObject>)object {
  return [NSError errorWithDomain:kPTNErrorDomain
                             code:PTNErrorCodeInvalidObject
                         userInfo:@{kPTNErrorAssociatedObjectKey: object ?: [NSNull null]}];
}

@end

NS_ASSUME_NONNULL_END
