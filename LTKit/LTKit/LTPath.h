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
  LTPathBaseDirectoryCaches,
  /// Base directory is the application support directory path.
  LTPathBaseDirectoryApplicationSupport
};

/// Represents a path split to a base path and a relative path to that base path. This class is
/// mostly used when the base path is changing in each execution of the app.
///
/// @see https://developer.apple.com/library/ios/technotes/tn2406/_index.html
@interface LTPath : NSObject <NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new \c LTPath object with the given \c path and \c LTPathBaseDirectoryNone as its
/// \c baseDirectory. The full path will be constructed by resolving the path of the concatenated
/// base directory and the relative path.
+ (instancetype)pathWithPath:(NSString *)path;

/// Initializes a new \c LTPath object with the given \c baseDirectory and \c relativePath.
/// \c relativePath will be standardized and will be converted to absolute path (by adding a leading
/// '/'). The path will be constructed by resolving the path of the concatenated base directory and
/// the relative path.
+ (instancetype)pathWithBaseDirectory:(LTPathBaseDirectory)baseDirectory
                      andRelativePath:(NSString *)relativePath;

/// Initializes a new \c LTPath with the given \c relativeURL. If the \c relativeURL's \c scheme,
/// \c host or \c path doesn't match the values accepted by \c LTPath, \c nil will be returned.
///
/// @see <tt>-[LTPath relativeURL]</tt> for more details.
+ (nullable instancetype)pathWithRelativeURL:(NSURL *)relativeURL;

/// Initializes a new \c LTPath of a random and unique file in the root of the temporary directory.
/// \c baseDirectory is set to \c LTPathBaseDirectoryTemp and \c relativePath is a random UUID with
/// \c extension as the file extension.
+ (instancetype)temporaryPathWithExtension:(NSString *)extension;

/// Returns a new path made by appending \c pathComponent to the receiver's \c relativePath
/// component. \c baseDirectory is the same as the receiver's.
///
/// @see -[NSString stringByAppendingPathComponent:].
- (LTPath *)pathByAppendingPathComponent:(NSString *)pathComponent;

/// Returns a new path made by appending \c pathExtension to the receiver's \c relativePath
/// component. \c baseDirectory is the same as the receiver's.
///
/// @see -[NSString stringByAppendingPathExtension:].
- (LTPath *)pathByAppendingPathExtension:(NSString *)pathExtension;

/// Base directory of the path.
@property (readonly, nonatomic) LTPathBaseDirectory baseDirectory;

/// Relative path from the base directory.
@property (readonly, nonatomic) NSString *relativePath;

/// Path joined from \c baseDirectory and \c relativePath
@property (readonly, nonatomic) NSString *path;

/// Path represented as file URL.
@property (readonly, nonatomic) NSURL *url;

/// Path represented as a URL, with a custom scheme and host. This can be used in conjunction with
/// <tt>+[LTPath pathWithRelativeURL:]</tt> to serialize and deserialize the receiver to and
/// from \c NSURL, accordingly.
@property (readonly, nonatomic) NSURL *relativeURL;

@end

NS_ASSUME_NONNULL_END
