// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class PTNDropboxEntry;

/// Possible types of Dropbox URL.
typedef NS_ENUM(NSUInteger, PTNDropboxURLType) {
  /// URL of a specific asset.
  PTNDropboxURLTypeAsset,
  /// URL of a specific album.
  PTNDropboxURLTypeAlbum,
  /// Invalid URL type.
  PTNDropboxURLTypeInvalid
};

/// Category for easy analysis and synthesis of URLs related to Dropbox objects.
///
/// The following URL types are supported:
///   - Album path: <dropbox scheme>://album/?path=<path>&revision=<revision>
///   - Asset path: <dropbox scheme>://asset/?path=<path>&revision=<revision>
///
/// Where:
///   - \c path is a the path to the file.
///   - \c revision is the file's revision version.
@interface NSURL (Dropbox)

/// The URL scheme associated with Dropbox URLs.
+ (NSString *)ptn_dropboxScheme;

/// Unique identifier URL of an asset pointed by \c entry.
+ (NSURL *)ptn_dropboxAssetURLWithEntry:(PTNDropboxEntry *)entry;

/// Unique identifier URL of an album pointed by \c entry.
+ (NSURL *)ptn_dropboxAlbumURLWithEntry:(PTNDropboxEntry *)entry;

/// Album entry or \c nil if the URL is not a valid Dropbox album URL.
@property (readonly, nonatomic, nullable) PTNDropboxEntry *ptn_dropboxAlbumEntry;

/// Asset entry or \c nil if the URL is not a valid Dropbox album URL.
@property (readonly, nonatomic, nullable) PTNDropboxEntry *ptn_dropboxAssetEntry;

/// Type of the URL, or \c PTNDropboxURLTypeInvalid if the URL is not of Dropbox type.
@property (readonly, nonatomic) PTNDropboxURLType ptn_dropboxURLType;

@end

NS_ASSUME_NONNULL_END
