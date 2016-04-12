// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Value class containing information required for proper cache use and validation.
@interface PTNCacheInfo : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c maxAge as the time in seconds for which the object associated with this
/// cache info is considered fresh starting from \c responseTime, and \c entityTag as a unique
/// identifier for the object associated with this cache info or \c nil if no such identifier is
/// available or required.
///
/// @important \c responseTime will be treated as a date in coordinated universal time (UTC) by this
/// class and its methods.
///
/// @see PTNCachingAssetManager for more information regarding definitions of \c cache, \c fresh
/// and \c stale.
- (instancetype)initWithMaxAge:(NSTimeInterval)maxAge responseTime:(NSDate *)responseTime
                     entityTag:(nullable NSString *)entityTag NS_DESIGNATED_INITIALIZER;

/// Initializes with \c maxAge as the time in seconds for which the object associated with this
/// cache info is considered fresh starting from now in coordinated universal time (UTC), and
/// \c entityTag as a unique identifier for the object associated with this cache info or \c nil if
/// no such identifier is available or required.
///
/// @see -initWithMaxAge:responseTime:entityTag:.
- (instancetype)initWithMaxAge:(NSTimeInterval)maxAge entityTag:(nullable NSString *)entityTag;

/// Creates and returns a copy of the receiver by replacing \c responseTime with the current time
/// in coordinated universal time (UTC).
- (instancetype)refreshedCacheInfo;

/// \c YES if the date created by appending \c maxAge to \c responseTime is equal to or greater than
/// \c date.
- (BOOL)isFreshComparedTo:(NSDate *)date;

/// \c YES if the date created by appending \c maxAge to \c responseTime is equal to or greater than
/// the current time in coordinated universal time (UTC).
- (BOOL)isFresh;

/// Date in which the object associated with this cache info was retuned by the server in
/// coordinated universal time (UTC).
@property (readonly, nonatomic) NSDate *responseTime;

/// Time interval in seconds for which the object associated with this cache info is considered
/// fresh.
@property (readonly, nonatomic) NSTimeInterval maxAge;

/// Identifier of the object associated with the receiver used to distinguish it when performing
/// cache validation or \c nil if if no such identifier is available or required.
@property (readonly, nonatomic, nullable) NSString *entityTag;

@end

/// Serialization additions.
@interface PTNCacheInfo (Serialization)

/// Initializes by setting the values of this \c PTNCacheInfo to the values stored in \c dictionary
/// assuming it was created from another instance of \c PTNCacheInfo using the \c dictionary
/// property. If \c dictionary does not contain keys matching the internal key-value coding or uses
/// the key-value paradigm of an earlier version \c nil will be returned.
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary;

/// Dictionary representing the properties of the receiver. All \c nil values and their
/// corresponding keys are not added.
@property (readonly, nonatomic) NSDictionary *dictionary;

@end

NS_ASSUME_NONNULL_END
