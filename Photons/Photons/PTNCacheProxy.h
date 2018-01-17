// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class PTNCacheInfo;

/// Proxy extending a class by providing cache information that is not included in the original
/// class. The proxy forwards any messages not handled by itself to the underlying class. This
/// allows entities that are not aware of the caching system use this proxy in a regular fashion,
/// while enabling entities that need the caching information to access it for their purposes.
///
/// @note This class will dynamically behave as if it were an instance of the underlying object.
/// It responds to the same selectors, conforms to the same protocols, etc..
@interface PTNCacheProxy<UnderlyingType: id<NSObject>> : NSProxy

/// Initializes with \c underlyingObject and \c cacheInfo. All methods not handled by the receiver
/// are forwarded to \c underlyingObject. Additionally the receiver dynamically conforms to all
/// protocols conformed by \c underlyingObject.
- (instancetype)initWithUnderlyingObject:(UnderlyingType)underlyingObject
                               cacheInfo:(PTNCacheInfo *)cacheInfo;

/// Underlying object wrapped by the receiver.
@property (readonly, nonatomic) UnderlyingType underlyingObject;

/// Cache information associated with the receiver's \c underlyingObject.
@property (readonly, nonatomic) PTNCacheInfo *cacheInfo;

@end

NS_ASSUME_NONNULL_END
