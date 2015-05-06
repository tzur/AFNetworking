// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Photons error domain.
extern NSString * kPTNErrorDomain;

/// Key containing the URL associated with the error.
extern NSString * kPTNErrorRequestURLKey;

typedef NS_ENUM(NSInteger, PTNErrorCode) {
  PTNErrorCodeInvalidURL = 1,
  PTNErrorCodeAlbumNotFound = 2
};

@interface NSError (Photons)

/// Caused when an invalid URL has been given.
+ (NSError *)ptn_invalidURL:(NSURL *)url;

/// Caused when the given album \c url has not been found.
+ (NSError *)ptn_albumNotFound:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
