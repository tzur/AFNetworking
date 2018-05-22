// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Types of assets that can be retrieved by the Ocean server.
LTEnumDeclare(NSUInteger, PTNOceanAssetType,
  /// Photo asset type.
  PTNOceanAssetTypePhoto,
  /// Video asset type.
  PTNOceanAssetTypeVideo
);

/// Types of Ocean assets sources.
LTEnumDeclare(NSUInteger, PTNOceanAssetSource,
  /// Pixabay https://pixabay.com/.
  PTNOceanAssetSourcePixabay,
  /// Getty Images https://www.gettyimages.com/.
  PTNOceanAssetSourceGetty
);

/// Category augmenting the \c PTNOceanAssetSource class with Ocean related attributes.
@interface PTNOceanAssetSource (Identifier)

/// Initializes with the given \c identifier. Returns \c nil if the given \c identifier does not
/// match any enum value.
+ (nullable instancetype)sourceWithIdentifier:(NSString *)identifier;

/// Ocean identifier associated with the source. Referred to as \c source_id in Ocean API
/// notations.
- (NSString *)identifier;

@end

/// Category augmenting the \c PTNOceanAssetType class with Ocean related attributes.
@interface PTNOceanAssetType (Identifier)

/// Initializes with the given \c identifier. Returns \c nil if the given \c identifier does not
/// match any enum value.
+ (nullable instancetype)typeWithIdentifier:(NSString *)identifier;

/// Ocean identifier associated with the type.
- (NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
