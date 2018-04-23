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
  PTNOceanAssetSourcePixabay
);

@implementation PTNOceanAssetSource (Identifier)

- (NSString *)identifier {
  switch (self.value) {
    case PTNOceanAssetSourcePixabay:
      return @"pixabay";
  }
}

@end

NS_ASSUME_NONNULL_END
