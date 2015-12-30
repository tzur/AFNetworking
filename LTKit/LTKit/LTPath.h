// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Possible base directories for the path.
typedef NS_ENUM(NSUInteger, LTPathBaseDirectory) {
  /// No base directory - relative path will be used as full path.
  LTPathBaseDirectoryNone,
  /// Base directory is the temporary directory.
  LTPathBaseDirectoryTemp,
  /// Base directory is the documents directory.
  LTPathBaseDirectoryDocuments,
  /// Base directory is the main bundle's directory.
  LTPathBaseDirectoryMainBundle,
  /// Base directory is the discardable caches directory path.
  LTPathBaseDirectoryCachesDirectory,
  /// Base directory is the application support directory path.
  LTPathBaseDirectoryApplicationSupport
};

/// Represents a path split to a base path and a relative path to that base path. This class is
/// mostly used when the base path is changing in each execution of the app.
///
/// @see https://developer.apple.com/library/ios/technotes/tn2406/_index.html
@interface LTPath : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new \c LTPath object with the given \c path and \c LTPathBaseDirectoryNone as its
/// \c baseDirectory.
/// The path will be constructed by resolving the path of the concatenated base directory and the
/// relative path.
+ (instancetype)pathWithPath:(NSString *)path;

/// Initializes a new \c LTPath object with the given \c baseDirectory and \c relativePath.
/// The path will be constructed by resolving the path of the concatenated base directory and the
/// relative path.
+ (instancetype)pathWithBaseDirectory:(LTPathBaseDirectory)baseDirectory
                      andRelativePath:(NSString *)relativePath;

/// Returns a new path made by appending \c pathComponent to the receiver's \c relativePath
/// component. \c baseDirectory is the same as the receiver's.
///
/// @see -[NSString stringByAppendingPathComponent:].
- (LTPath *)filePathByAppendingPathComponent:(NSString *)pathComponent;

/// Returns a new path made by appending \c pathExtension to the receiver's \c relativePath
/// component. \c baseDirectory is the same as the receiver's.
///
/// @see -[NSString stringByAppendingPathExtension:].
- (LTPath *)filePathByAppendingPathExtension:(NSString *)pathExtension;

/// Base directory of the path.
@property (readonly, nonatomic) LTPathBaseDirectory baseDirectory;

/// Relative path from the base directory.
@property (readonly, nonatomic) NSString *relativePath;

/// Path joined from \c baseDirectory and \c relativePath
@property (readonly, nonatomic) NSString *path;

/// Path represented as file URL.
@property (readonly, nonatomic) NSURL *url;

@end

NS_ASSUME_NONNULL_END
