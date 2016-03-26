// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNFileSystemFileManager;

@class PTNImageResizer;

/// Asset manager which backs the device's file system. Returned assets will represent files with
/// the extensions {"jpg", "jpeg", "png", "tiff"}.
@interface PTNFileSystemAssetManager : NSObject <PTNAssetManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a File System asset manager with the given \c fileManager and an \c imageResizer.
/// \c fileManager enables shallow iteration of a file system. \c imageResizer is used to resize
/// images according to fetch requests specifications.
- (instancetype)initWithFileManager:(id<PTNFileSystemFileManager>)fileManager
                       imageResizer:(PTNImageResizer *)imageResizer NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
