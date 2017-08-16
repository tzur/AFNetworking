// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

@class PTNOceanAssetSource;

/// Possible types of Ocean URLs.
LTEnumDeclare(NSUInteger, PTNOceanURLType,
  /// Album URL type.
  PTNOceanURLTypeAlbum,
  /// Asset URL type.
  PTNOceanURLTypeAsset
);

/// Category for easy analysis and synthesis of URLs related to Ocean objects.
///
/// The following URL types are supported:
///   - Asset descriptor: <ocean scheme>://asset?id=<id>&source=<source identifier>
///   - Assets album: <ocean scheme>://album?phrase=<phrase>&source=<source identifier>
@interface NSURL (Ocean)

/// Scheme of Ocean URLs.
+ (NSString *)ptn_oceanScheme;

/// Initializes an album URL with the given \c source and \c phrase. If \c phrase is \c nil, the
/// returned URL will be associated with the album of the most popular assets.
+ (NSURL *)ptn_oceanAlbumURLWithSource:(PTNOceanAssetSource *)source
                                phrase:(nullable NSString *)phrase;

/// Initializes an asset URL with the give \c source and \c identifier.
+ (NSURL *)ptn_oceanAssetURLWithSource:(PTNOceanAssetSource *)source
                            identifier:(NSString *)identifier;

/// Ocean type associated with this instance, or \c nil if the URL is not of Ocean type.
@property (readonly, nonatomic, nullable) PTNOceanURLType *ptn_oceanURLType;

@end

NS_ASSUME_NONNULL_END
