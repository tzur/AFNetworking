// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNFileSystemFileManager;

@class PTNImageResizer;

/// Asset manager which backs the device's file system.
///
/// Supported image files are {"jpg", "jpeg", "png", "tiff"}. Supported Audiovisual files are
/// {"mp4", "qt", "m4v", "mov"}.
@interface PTNFileSystemAssetManager : NSObject <PTNAssetManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a File System asset manager with the given \c fileManager and an \c imageResizer.
/// \c fileManager enables shallow iteration of a file system. \c imageResizer is used to resize
/// images according to fetch requests specifications.
- (instancetype)initWithFileManager:(id<PTNFileSystemFileManager>)fileManager
                       imageResizer:(PTNImageResizer *)imageResizer NS_DESIGNATED_INITIALIZER;

/// Returns an array of UTIs that are supported by the receiver.
+ (NSArray<NSString *> *)supportedUTIs;

@end

NS_ASSUME_NONNULL_END
