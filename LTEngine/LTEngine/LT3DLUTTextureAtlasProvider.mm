// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LT3DLUTTextureAtlasProvider.h"

#import <LTKit/LTUnorderedMap.h>

#import "LT3DLUT.h"
#import "LT3DLUTTextureAtlas.h"
#import "LTHorizontalPackingRectsProvider.h"
#import "LTTextureAtlasFromMatsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTextureAtlas;

@interface LT3DLUTTextureAtlasProvider ()

/// Map of 3D LUTs for packing.
@property (readonly, nonatomic) NSDictionary<NSString *, LT3DLUT *> *luts;

/// Auxiliary texture atlas provider for producing atlas objects.
@property (readonly, nonatomic) LTTextureAtlasFromMatsProvider *atlasProvider;

@end

@implementation LT3DLUTTextureAtlasProvider

@synthesize  atlasProvider = _atlasProvider;

- (instancetype)initWithLUTs:(NSDictionary<NSString *,LT3DLUT *> *)luts {
  LTParameterAssert(luts.count, @"LUTs map cannot be empty");

  if (self = [super init]) {
    _luts = luts;
  }

  return self;
}

- (LT3DLUTTextureAtlas *)textureAtlas {
  [self createAtlasProviderIfNeeded];
  LTTextureAtlas *textureAtlas = [self.atlasProvider atlas];
  lt::unordered_map<NSString *, LT3DLUTLatticeSize> latticesSizesMap = [self latticeSizesMap];
  return [[LT3DLUTTextureAtlas alloc] initWithTextureAtlas:textureAtlas
                                              latticeSizes:latticesSizesMap];
}

- (void)createAtlasProviderIfNeeded {
  if (_atlasProvider) {
    return;
  }

  id<LTPackingRectsProvider> packingRectsProvider =
      [[LTHorizontalPackingRectsProvider alloc] init];
  _atlasProvider =
      [[LTTextureAtlasFromMatsProvider alloc] initWithMatrices:[self lutsPackedMatsMap]
                                          packingRectsProvider:packingRectsProvider];
}

- (lt::unordered_map<NSString *, cv::Mat>)lutsPackedMatsMap {
  __block lt::unordered_map<NSString *, cv::Mat> map;

  [self.luts enumerateKeysAndObjectsUsingBlock:^(NSString *key, LT3DLUT *lut, BOOL *) {
    map[key] = [lut packedMat];
  }];

  return map;
}

- (lt::unordered_map<NSString *, LT3DLUTLatticeSize>)latticeSizesMap {
  __block lt::unordered_map<NSString *, LT3DLUTLatticeSize> map;

  [self.luts enumerateKeysAndObjectsUsingBlock:^(NSString *key, LT3DLUT *lut, BOOL *) {
    map[key] = lut.latticeSize;
  }];

  return map;
}

@end

NS_ASSUME_NONNULL_END
