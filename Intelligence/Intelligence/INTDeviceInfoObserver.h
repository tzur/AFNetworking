// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@class INTDeviceInfo, INTDeviceInfoObserver;

@protocol INTDeviceInfoSource, INTStorage;

/// Defines a protocol for objects that receive updates from an \c INTDeviceInfoObserver regarding
/// \c INTDeviceInfo.
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

@end

/// Observes a stored \c INTDeviceInfo and updates it upon changes. Uses a given \c delegate to
/// inform of any changes to the device info. This class is thread safe.
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
                                 storage:(id<INTStorage>)storage
                                delegate:(id<INTDeviceInfoObserverDelegate>)delegate
    NS_DESIGNATED_INITIALIZER;

/// Sets \c appStoreCountry to the current \c INTDeviceInfo only if it is different from the current
/// app store country. If \c appStoreCountry is changed, the \c delegate is notified of a new
/// \c INTDeviceInfo.
- (void)setAppStoreCountry:(NSString *)appStoreCountry;

@end

NS_ASSUME_NONNULL_END
