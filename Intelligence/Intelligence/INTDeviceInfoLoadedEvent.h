// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@class INTDeviceInfo;

/// Event marking the load of an \c INTDeviceInfo for the current device, by either loading from
/// storage or creating a new instance by gathering info using necessary API calls and creating a
/// new info object.
@interface INTDeviceInfoLoadedEvent : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given parameters. Please refer to properties docs for each of the given
/// parameters.
- (instancetype)initWithDeviceInfo:(INTDeviceInfo *)deviceInfo
              deviceInfoRevisionID:(NSUUID *)deviceInfoRevisionID isNewRevision:(BOOL)isNewRevision
    NS_DESIGNATED_INITIALIZER;

/// The loaded device info.
@property (readonly, nonatomic) INTDeviceInfo *deviceInfo;

/// Unique Revision ID of the \c deviceInfo. This ID changes between consecutive
/// \c INTDeviceInfoLoadedEvent objects with the latter \c deviceInfo not passing an \c isEqual
/// test with the former \c deviceInfo.
@property (readonly, nonatomic) NSUUID *deviceInfoRevisionID;

/// \c YES if \c deviceInfoRevisionID changed since the last \c INTDeviceInfoLoadedEvent.
@property (readonly, nonatomic) BOOL isNewRevision;

@end

NS_ASSUME_NONNULL_END
