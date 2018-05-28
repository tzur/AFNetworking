// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanEnums.h"

NS_ASSUME_NONNULL_BEGIN

/// Types of assets that can be retrieved by the Ocean server.
LTEnumImplement(NSUInteger, PTNOceanAssetType,
  /// Photo asset type.
  PTNOceanAssetTypePhoto,
  /// Video asset type.
  PTNOceanAssetTypeVideo
);

/// Types of Ocean assets sources.
LTEnumImplement(NSUInteger, PTNOceanAssetSource,
  /// Pixabay https://pixabay.com/.
  PTNOceanAssetSourcePixabay,
  /// Getty Images https://www.gettyimages.com/.
  PTNOceanAssetSourceGetty
);

@implementation PTNOceanAssetSource (Identifier)

static LTBidirectionalMap *kPTNOceanAssetSourceIdentifiers =
  [LTBidirectionalMap mapWithDictionary:@{
    @"pixabay": $(PTNOceanAssetSourcePixabay),
    @"getty": $(PTNOceanAssetSourceGetty)
  }];

+ (nullable instancetype)sourceWithIdentifier:(NSString *)identifier {
  return kPTNOceanAssetSourceIdentifiers[identifier];
}

- (NSString *)identifier {
  return [kPTNOceanAssetSourceIdentifiers keyForObject:self];
}

@end

@implementation PTNOceanAssetType (Identifier)

static LTBidirectionalMap *kPTNOceanAssetTypeIdentifiers =
  [LTBidirectionalMap mapWithDictionary:@{
    @"image": $(PTNOceanAssetTypePhoto),
    @"video": $(PTNOceanAssetTypeVideo)
  }];

+ (nullable instancetype)typeWithIdentifier:(NSString *)identifier {
  return kPTNOceanAssetTypeIdentifiers[identifier];
}

- (NSString *)identifier {
  return [kPTNOceanAssetTypeIdentifiers keyForObject:self];
}

@end

NS_ASSUME_NONNULL_END
