// Copyright (c) 2016 s. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheResponse.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNDataAsset;

/// Protocol representing a generic cache over \c NSData, capable of storing and fetching an
/// \c NSData object and its associated information as an \c NSDictionary in a thread safe manner.
/// Storing is made if the size of the data requested for storing is small enough to reasonably fit
/// within the cache.
@protocol PTNDataCache <NSObject>

/// Stores \c data and \c info under \c url as the key. If \c info is \c nil it will be ignored and
/// \c nil info will be returned when fetching the cached data.
///
/// @note This is a non-blocking call.
///
/// @note Storage is taking place in memory or disk depending on implementation.
///
/// @important \c info must be a property list valid for the \c NSPropertyListBinaryFormat_v1_0
/// format.
- (void)storeData:(NSData *)data withInfo:(nullable NSDictionary *)info
           forURL:(NSURL *)url;

/// Stores empty data and \c info under \c url as the key. This method is non blocking.
///
/// @note This is a non-blocking call.
///
/// @note Storage is taking place in memory.
- (void)storeInfo:(NSDictionary *)info forURL:(NSURL *)url;

/// Retrieves data and inforamtion perviously stored with \c url. The returned signal will send a
/// single \c PTNCacheResponse and complete if data or information were found for \c url or send
/// a single \c nil and complete if data and information stored for \c url could not be found.
/// Data and information will not be found if they were not stored in the cache or if they were
/// purged by the caching system to make room for other objects. The returned signal will err if an
/// error occured while fetching the data and information.
///
/// @return RACSignal<nullable PTNCacheResponse<nullable NSData *, nullable NSDictionary *>>
- (RACSignal *)cachedDataForURL:(NSURL *)url;

/// Clears the cache from all stored data.
- (void)clearCache;

@end

NS_ASSUME_NONNULL_END
