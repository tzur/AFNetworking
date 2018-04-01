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
  PTNOceanAssetSourcePixabay
);

/// Category augmenting the \c PTNOceanAssetSource class with Ocean related attributes.
@interface PTNOceanAssetSource (Identifier)

/// Ocean identifier associated with the source. Referred to as \c source_id in Ocean API
/// notations.
- (NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
