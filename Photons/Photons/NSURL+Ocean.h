// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

@class PTNOceanAssetSource, PTNOceanAssetType;

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
///   - Asset descriptor: ptn-oceanScheme://asset?id=<id>&source=<source_identifier>
///   - Assets album: ptn-oceanScheme://album?phrase=<phrase>&source=<source_identifier>type=<asset_type>&page=<page>
@interface NSURL (Ocean)

/// Scheme of Ocean URLs.
+ (NSString *)ptn_oceanScheme;

/// Initializes an album URL with the given \c source, \c assetType and \c phrase. If \c phrase is
/// \c nil, the returned URL will be associated with the album of the most popular assets.
+ (NSURL *)ptn_oceanAlbumURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType
                                phrase:(nullable NSString *)phrase;

/// Initializes an album URL with the given \c source, \c assetType \c phrase and \c page. If
/// \c phrase is \c nil, the returned URL will be associated with the album of the most popular
/// assets. Albums backed by URLs returned from this method are paginated. Use the given \c page to
/// specify the page number.
+ (NSURL *)ptn_oceanAlbumURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType
                                phrase:(nullable NSString *)phrase page:(NSUInteger)page;

/// Initializes an asset URL with the given \c source, \c assetType and \c identifier.
+ (NSURL *)ptn_oceanAssetURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType
                            identifier:(NSString *)identifier;

/// Ocean type associated with this instance, or \c nil if the URL is not of Ocean type.
@property (readonly, nonatomic, nullable) PTNOceanURLType *ptn_oceanURLType;

/// Asset type associated with this instance, or \c nil if the URL does not contain asset type.
@property (readonly, nonatomic, nullable) PTNOceanAssetType *ptn_oceanAssetType;

@end

NS_ASSUME_NONNULL_END
