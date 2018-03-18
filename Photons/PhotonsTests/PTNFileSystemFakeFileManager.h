// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileSystemFileManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake file value class for file system simulation.
@interface PTNFileSystemFakeFileManagerFile : NSObject

/// Initializes a fake file system file with \c name, \c path and \c isDirectory.
/// \c path is the path upto and not including the file's name.
- (instancetype)initWithName:(NSString *)name path:(NSString *)path isDirectory:(BOOL)isDirectory;

@end

/// Fake file system file manager for easier testing.
///
/// @note This file system manager ignores options and property keys input and always assumes
/// options are \c nil and property keys include \c NSURLIsDirectoryKey and \c NSURLNameKey.
@interface PTNFileSystemFakeFileManager : NSObject <PTNFileSystemFileManager>

/// Initializes a fake file system manager with \c files as its registered files.
- (instancetype)initWithFiles:(NSArray<PTNFileSystemFakeFileManagerFile *> *)files;

/// Fake file system representation.
@property (strong, nonatomic) NSArray<PTNFileSystemFakeFileManagerFile *> *files;

@end

NS_ASSUME_NONNULL_END
