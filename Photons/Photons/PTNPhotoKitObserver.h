// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol for an observable photo library.
@protocol PTNPhotoLibrary <NSObject>

/// Returns information about your app’s authorization for accessing the photo library.
- (PHAuthorizationStatus)authorizationStatus;

/// Registers \c observer to receive messages when objects in the photo library change. Upon changes
/// the library automatically sends change messages.
- (void)registerChangeObserver:(id<PHPhotoLibraryChangeObserver>)observer;

/// Unregisters \c observer so that it no longer receives change messages.
- (void)unregisterChangeObserver:(id<PHPhotoLibraryChangeObserver>)observer;

@end

@interface PHPhotoLibrary (PTNPhotoLibrary) <PTNPhotoLibrary>
@end

/// Protocol for observing PhotoKit notifications provided by \c PHPhotoLibrary.
@protocol PTNPhotoKitObserver <NSObject>

/// Returns an infinite signal of \c PHChange objects, which are delivered when there's a change in
/// PhotoKit's library, subscribing to this signal will begin the observation if authorization was
/// granted, or err if no authorization was given to the photo library.
@property (readonly, nonatomic) RACSignal *photoLibraryChanged;

@end

/// Adapter for observing PhotoKit notifications provided by \c PHPhotoLibrary.
@interface PTNPhotoKitObserver : NSObject <PTNPhotoKitObserver>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the photo library used to observe the changes.
- (instancetype)initWithPhotoLibrary:(id<PTNPhotoLibrary>)photoLibrary NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
