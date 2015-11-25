// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Maps error code to its string description.
typedef NSDictionary<NSNumber *, NSString *> LTErrorCodeToDescription;

/// Mutable map that maps error code to its string description.
typedef NSMutableDictionary<NSNumber *, NSString *> LTMutableErrorCodeToDescription;

/// Singleton registry that holds mapping from error codes to their string representation.
///
/// @see NSErrorCodes+LTKit for more information about how to create error codes that auto-register
/// themselves.
@interface LTErrorCodesRegistry : NSObject

/// Retrieves the shared singleton registry.
+ (instancetype)sharedRegistry;

/// Registers a set of error codes, given a mapping of the error code to its string description.
- (void)registerErrorCodes:(LTErrorCodeToDescription *)errorCodes;

/// Returns the description of the given error code, or \c nil if no error code is found in the
/// registry.
- (nullable NSString *)descriptionForErrorCode:(NSInteger)errorCode;

/// Maps between an error code and its string description.
@property (readonly, nonatomic) LTMutableErrorCodeToDescription *mapping;

@end

NS_ASSUME_NONNULL_END
