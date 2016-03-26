// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class PHPhotoLibrary;

/// Protocol for observing PhotoKit notifications provided by \c PHPhotoLibrary.
@protocol PTNPhotoKitObserver <NSObject>

/// Returns a hot, infinite signal of \c PHChange objects, which are delivered when there's a change
/// in PhotoKit's library.
@property (readonly, nonatomic) RACSignal *photoLibraryChanged;

@end

/// Adapter for observing PhotoKit notifications provided by \c PHPhotoLibrary.
@interface PTNPhotoKitObserver : NSObject <PTNPhotoKitObserver>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the photo library used to observe the changes.
- (instancetype)initWithPhotoLibrary:(PHPhotoLibrary *)photoLibrary NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
