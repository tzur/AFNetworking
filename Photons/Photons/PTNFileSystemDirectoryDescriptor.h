// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNDescriptor.h"

@class LTPath;

NS_ASSUME_NONNULL_BEGIN

/// Represents a File System directory.
@interface PTNFileSystemDirectoryDescriptor : NSObject <PTNAlbumDescriptor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the path the descriptor points to.
- (instancetype)initWithPath:(LTPath *)path NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
