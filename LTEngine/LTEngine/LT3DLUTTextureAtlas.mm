// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LT3DLUTTextureAtlas.h"

#import "LTTexture.h"
#import "LTTextureAtlas.h"

@implementation LT3DLUTTextureAtlas

- (instancetype)initWithTextureAtlas:(LTTextureAtlas *)atlas
                        latticeSizes:(const LT3DLUTLatticeSizeMap &)latticeSizes{
  LTParameterAssert(atlas);
  [LT3DLUTTextureAtlas validateAtlasAreas:atlas.areas fitLatticeSizes:latticeSizes];

  if (self = [super init]) {
    _texture = atlas.texture;
    [self createSpatialDataMapFromAtlasAreas:atlas.areas andLatticeSizes:latticeSizes];
  }

  return self;
}

+ (void)validateAtlasAreas:(const lt::unordered_map<NSString *, CGRect> &)areas
           fitLatticeSizes:(const LT3DLUTLatticeSizeMap &)latticeSizes {
  LTParameterAssert(areas.size() == latticeSizes.size(), @"atlas areas size (%lu) is different "
                    "than the lattice sizes size (%lu)",
                    (unsigned long)areas.size(), (unsigned long)latticeSizes.size());

  for (const auto &keyValue : areas) {
    NSString *key = keyValue.first;
    auto latticeSizeLocation = latticeSizes.find(key);
    LTParameterAssert(latticeSizeLocation != latticeSizes.end(), @"atlas areas keys set must be "
                      "equal to the lattice sizes keys set but key %@ in atlas areas was not found "
                      "in lattice sizes keys set", key);
    LT3DLUTLatticeSize latticeSize = latticeSizeLocation->second;
    CGSize packedMatSize = CGSizeMake(latticeSize.rDimensionSize,
                                      latticeSize.gDimensionSize * latticeSize.bDimensionSize);
    CGSize areaSize = keyValue.second.size;

    LTParameterAssert(areaSize == packedMatSize, @"atlas area size in a given key must fit the "
                      "packed mat size that derives from the lattice size in the same key but area "
                      "size at key %@ is %@ and the packed mat size that derives from the lattice "
                      "size at the same key is %@",
                      key, NSStringFromCGSize(areaSize), NSStringFromCGSize(packedMatSize));
  }
}

- (void)createSpatialDataMapFromAtlasAreas:(const lt::unordered_map<NSString *, CGRect> &)areas
                           andLatticeSizes:(const LT3DLUTLatticeSizeMap &)latticeSizes {
  for (const auto &keyValue : areas) {
    NSString *key = keyValue.first;
    CGRect area = keyValue.second;
    auto latticeSizeLocation = latticeSizes.find(key);
    LT3DLUTLatticeSize latticeSize = latticeSizeLocation->second;
    _spatialDataMap[key] = {latticeSize, area};
  }
}

@end
