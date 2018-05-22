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

/// Query item key containing the source associated with the URL.
extern NSString * const kPTNOceanURLQueryItemSourceKey;

/// Query item key containing the asset type associated with the URL.
extern NSString * const kPTNOceanURLQueryItemTypeKey;

/// Query item key containing the search phrase associated with the URL.
extern NSString * const kPTNOceanURLQueryItemPhraseKey;

/// Query item key containing the page number associated with the URL.
extern NSString * const kPTNOceanURLQueryItemPageKey;

/// Query item key containing the identifier associated with the URL.
extern NSString * const kPTNOceanURLQueryItemIdentifierKey;

/// Category for easy analysis and synthesis of URLs related to Ocean objects.
///
/// The following URL types are supported:
///   - Asset descriptor: ptn-oceanScheme://asset?id=<id>&source=<source_identifier>
///   - Assets album: ptn-oceanScheme://album?phrase=<phrase>&source=<source_identifier>type=<asset_type>&page=<page>
@interface NSURL (Ocean)

/// Scheme of Ocean URLs.
+ (NSString *)ptn_oceanScheme;

/// Initializes an album URL with the given \c source, \c assetType and \c phrase. If \c phrase is
/// an empty string, the returned URL will be associated with the album of the most popular assets.
+ (NSURL *)ptn_oceanAlbumURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType
                                phrase:(NSString *)phrase;

/// Initializes an album URL with the given \c source, \c assetType \c phrase and \c page. If
/// \c phrase is an empty string, the returned URL will be associated with the album of the most
/// popular assets. Albums backed by URLs returned from this method are paginated. Use the given
/// \c page to specify the page number.
+ (NSURL *)ptn_oceanAlbumURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType phrase:(NSString *)phrase
                                  page:(NSUInteger)page;

/// Initializes an asset URL with the given \c source, \c assetType and \c identifier.
+ (NSURL *)ptn_oceanAssetURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType
                            identifier:(NSString *)identifier;

/// Initializes an asset URL by prasing the given \c bazaarIdentifier, see the
/// \c ptn_bazaarIdentifier property a description of Bazaar identifier. If the given
/// \c bazaarIdentifier cannot be parsed \c nil is returned.
+ (nullable NSURL *)ptn_oceanAssetURLWithBazaarIdentifier:(NSString *)bazaarIdentifier;

/// Ocean type associated with this instance, or \c nil if the URL is not of Ocean type or isn't an
/// Ocean url.
@property (readonly, nonatomic, nullable) PTNOceanURLType *ptn_oceanURLType;

/// Asset type associated with this instance, or \c nil if the URL does not contain asset type or
/// isn't an Ocean url.
@property (readonly, nonatomic, nullable) PTNOceanAssetType *ptn_oceanAssetType;

/// Asset source associated with this instance, or \c nil if the URL does not contain asset source
/// or isn't an Ocean url.
@property (readonly, nonatomic, nullable) PTNOceanAssetSource *ptn_oceanAssetSource;

/// Seach phrase associated with this instance, or \c nil if the URL does not contain search phrase
/// or isn't an Ocean url.
@property (readonly, nonatomic, nullable) NSString *ptn_oceanSearchPhrase;

/// Page number associated with this instance, or \c nil if the URL does not contain a page number
/// or isn't an Ocean url.
@property (readonly, nonatomic, nullable) NSNumber *ptn_oceanPageNumber;

/// Asset identifier associated with this instance, or \c nil if the URL does not contain an asset
/// identifier or isn't an Ocean url.
@property (readonly, nonatomic, nullable) NSString *ptn_oceanAssetIdentifier;

/// A unique identifier representing the asset. The identifier is comprised of Ocean URL scheme,
/// the source, the asset type and the identifier of the asset, separated by a dot.
///
/// @example \c com.lightricks.Photons.Ocean.pixabay.image.ba84nsk3n1vkdsn3l4k
/// @example \c com.lightricks.Photons.Ocean.getty.video.574852058740
///
/// Returns \c nil if the URL does not represent an asset or isn't an Ocean url.
@property (readonly, nonatomic, nullable) NSString *ptn_bazaarIdentifier;

@end

NS_ASSUME_NONNULL_END
