// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class PHPhotoLibrary;

/// Adapter for observing PhotoKit notifications provided by \c PHPhotoLibrary.
@interface PTNPhotoKitObserver : NSObject

/// Initializes with the photo library used to observe the changes.
- (instancetype)initWithPhotoLibrary:(PHPhotoLibrary *)photoLibrary NS_DESIGNATED_INITIALIZER;

/// Returns a hot, infinite signal of \c PHChange objects, which are delivered when there's a change
/// in PhotoKit's library.
@property (readonly, nonatomic) RACSignal *photoLibraryChanged;

@end

NS_ASSUME_NONNULL_END
