// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

/// Callback of requests for authorization of the PhotoKit photo library.
typedef void (^PTNAuthorizationStatusHandler)(PHAuthorizationStatus status);

/// Encapsulation of the PhotoKit authorization process, enabling to inject it to dependent objects,
/// by converting class methods in PhotoKit to instance methods.
@interface PTNPhotoKitAuthorizer : NSObject

/// Requests the user's permission, if needed, for accessing the Photos library.
///
/// Accessing the Photos library always requires explicit permission from the user. The first time
/// the app uses \c PHAsset, \c PHCollection, \c PHAssetCollection, or \c PHCollectionList methods
/// to fetch content from the library, or uses one of the methods listed in Applying Changes to the
/// Photo Library to request changes to library content, Photos automatically and asynchronously
/// prompts the user to request authorization. Alternatively, you can call this method to prompt the
/// user at a time of choosing.
///
/// After the user grants permission, the system remembers the choice for future use in your app,
/// but the user can change this choice at any time using the Settings app. If the user has denied
/// your app photo library access, not yet responded to the permission prompt, or cannot grant
/// access due to restrictions, any attempts to fetch photo library content will return empty
/// \c PHFetchResult objects, and any attempts to perform changes to the photo library will fail.
///
/// The given \c handler is a block \c Photos calls upon determining the app's authorization to
/// access the photo library. The block takes a single parameter: current authorization status.
- (void)requestAuthorization:(PTNAuthorizationStatusHandler)handler;

/// The current authorization status.
@property (readonly, nonatomic) PHAuthorizationStatus authorizationStatus;

@end

NS_ASSUME_NONNULL_END
