// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class LTPath;

/// Possible types of File System URL.
typedef NS_ENUM(NSUInteger, PTNFileSystemURLType) {
  /// URL of a specific asset.
  PTNFileSystemURLTypeAsset,
  /// URL of a specific album.
  PTNFileSystemURLTypeAlbum,
  /// Invalid URL type.
  PTNFileSystemURLTypeInvalid
};

/// Category for easy analysis and synthesis of URLs related to File System objects.
///
/// The following URL types are supported:
///   - Album path: <filesystem scheme>://album/?base=<base dir>&relative=<path>
///   - Asset path: <filesystem scheme>://asset/?base=<base dir>&relative=<path>
///
/// Where:
///   - \c base is the base directory and can be one of {"none", "temp", "documents", "mainbundle",
///                                                      "caches", "applicationsupport"}.
///   - \c relative is a relative path starting from \c base.
@interface NSURL (FileSystem)

/// The URL Scheme associated with File System URLs.
+ (NSString *)ptn_fileSystemScheme;

/// Unique identifier URL of an asset pointed by \c path.
+ (NSURL *)ptn_fileSystemAssetURLWithPath:(LTPath *)path;

/// Unique identifier URL of an album pointed by \c path.
+ (NSURL *)ptn_fileSystemAlbumURLWithPath:(LTPath *)path;

/// Album path or \c nil if the URL is not a valid File System album URL.
@property (readonly, nonatomic, nullable) LTPath *ptn_fileSystemAlbumPath;

/// Asset path or \c nil if the URL is not a valid File System album URL.
@property (readonly, nonatomic, nullable) LTPath *ptn_fileSystemAssetPath;

/// Type of the URL, or \c PTNFileSystemURLTypeInvalid if the URL is not of File System type.
@property (readonly, nonatomic) PTNFileSystemURLType ptn_fileSystemURLType;

@end

NS_ASSUME_NONNULL_END
