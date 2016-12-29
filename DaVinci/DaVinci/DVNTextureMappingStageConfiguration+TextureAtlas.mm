// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTextureMappingStageConfiguration+TextureAtlas.h"

#import <LTEngine/LTTexture.h>
#import <LTEngine/LTTextureAtlas.h>
#import <LTKit/LTRandom.h>

#import "DVNRandomTexCoordProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNTextureMappingStageConfiguration (TextureAtlas)

+ (instancetype)configurationFromTextureAtlas:(LTTextureAtlas *)textureAtlas {
  LTRandomState *randomState = [[LTRandom alloc] init].engineState;
  lt::unordered_map<NSString *, CGRect> areas = textureAtlas.areas;

  std::vector<lt::Quad> quads;
  quads.reserve(areas.size());
  CGSize size = textureAtlas.texture.size;
  
  for (auto it = areas.begin(); it != areas.end(); ++it) {
    CGRect rect = it->second;
    quads.push_back(lt::Quad(CGRectFromOriginAndSize(rect.origin / size, rect.size / size)));
  }

  DVNRandomTexCoordProviderModel *model =
      [[DVNRandomTexCoordProviderModel alloc] initWithRandomState:randomState
                                                  textureMapQuads:quads];
  return [[DVNTextureMappingStageConfiguration alloc]
          initWithTexCoordProviderModel:model texture:textureAtlas.texture];
}

@end

NS_ASSUME_NONNULL_END
