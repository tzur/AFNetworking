// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@class INTDeviceInfo;

/// Defines a source that provides \c INTDeviceInfo objects.
@protocol INTDeviceInfoSource <NSObject>

/// Returns a new \c INTDeviceInfo with \c appStoreCoutry.
///
/// @see INTDeviceInfo for docs for the arguments.
- (INTDeviceInfo *)deviceInfoWithAppStoreCountry:(nullable NSString *)appStoreCountry;

@end

/// Default implementation of the \c INTDeviceInfoSource protocol.
@interface INTDeviceInfoSource : NSObject <INTDeviceInfoSource>
@end

NS_ASSUME_NONNULL_END
