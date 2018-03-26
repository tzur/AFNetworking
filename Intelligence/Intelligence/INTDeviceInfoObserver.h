// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@class INTDeviceInfo, INTDeviceInfoObserver, INTSubscriptionInfo;

@protocol INTDeviceInfoSource, LTKeyValuePersistentStorage;

/// Defines a protocol for objects that receive updates from an \c INTDeviceInfoObserver regarding
/// \c INTDeviceInfo and push notification device tokens.
@protocol INTDeviceInfoObserverDelegate <NSObject>

/// Notifies the delegate that \c deviceInfoObserver had loaded the \c deviceInfo.
/// \c deviceInfoRevisionID is a unique ID that changes between consecutive calls to this method
/// with the latter \c deviceInfo not passing an \c isEqual test with the former \c deviceInfo.
/// \c isNewRevision is \c YES if \c deviceInfoRevisionID changed between two consecutive calls to
/// this method.
- (void)deviceInfoObserver:(INTDeviceInfoObserver *)deviceInfoObserver
          loadedDeviceInfo:(INTDeviceInfo *)deviceInfo
      deviceInfoRevisionID:(NSUUID *)deviceInfoRevisionID
             isNewRevision:(BOOL)isNewRevision;

/// Notifies the receiver that the a device token has changed. \c nil device token means that push
/// notifications are disabled for the device.
- (void)deviceTokenDidChange:(nullable NSData *)deviceToken;

/// Notifies the receiver that the application's run count on the device had been updated to
/// \c runCount. The underlying type of \c runCount is an \c NSUInteger.
- (void)appRunCountUpdated:(NSNumber *)runCount;

/// Notifies the receiver that the devices subscription info had changed. \c nil
/// \c subscriptionInfo means that the subscription info is unavailable.
- (void)subscriptionInfoDidChanged:(nullable INTSubscriptionInfo *)subscriptionInfo;

@end

/// Observes a stored \c INTDeviceInfo, \c NSData representing a device push notification token and
/// \c NSNumber representing the number of times the application had launched on the device and
/// updates them. Uses a given \c delegate to inform any changes to the device info or device token.
/// This class is thread safe.
@interface INTDeviceInfoObserver : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a default \c deviceInfoSource, default \c storage and the given \c delegate.
/// All instances initialized with this call have a shared storage, and thus a shared state.
/// \c delegate is held weakly. Upon initialization, loads the stored \c INTDeviceInfo, checks for
/// any updates to any device info, stores the updates and notifies the delegate that
/// \c INTDeviceInfo was loaded.
- (instancetype)initWithDelegate:(id<INTDeviceInfoObserverDelegate>)delegate;

/// Initializes with \c deviceInfoSource, \c storage, and \c delegate. \c deviceInfoSource is used
/// for creating new \c INTDeviceInfo instances. \c storage is used for storing and fetching the
/// most up to date \c INTDeviceInfo. \c delegate is held weakly. Upon initialization, loads the
/// stored \c INTDeviceInfo, checks for any updates to any device info, stores the updates and
/// notifies the delegate that \c INTDeviceInfo was loaded.
- (instancetype)initWithDeviceInfoSource:(id<INTDeviceInfoSource>)deviceInfoSource
                                 storage:(id<LTKeyValuePersistentStorage>)storage
                                delegate:(id<INTDeviceInfoObserverDelegate>)delegate
    NS_DESIGNATED_INITIALIZER;

/// Sets \c appStoreCountry to the current \c INTDeviceInfo only if it is different from the current
/// app store country. If \c appStoreCountry is changed, the \c delegate is notified of a new
/// \c INTDeviceInfo.
- (void)setAppStoreCountry:(NSString *)appStoreCountry;

/// Sets a device push notification token from Apple if \c deviceToken is different from a
/// previously set device token, \c delegate is notified of the change. \c nil device token means
/// that push notifications are disabled for the device.
- (void)setDeviceToken:(nullable NSData *)deviceToken;

/// Sets the current \c subscriptionInfo of the device. If the \c subscriptionInfo is different from
/// the current subscription info, the \c delegate is notified of the change. \c nil
/// \c subscriptionInfo means that the subscription info is unavailable.
- (void)setSubscriptionInfo:(nullable INTSubscriptionInfo *)subscriptionInfo;

@end

NS_ASSUME_NONNULL_END
