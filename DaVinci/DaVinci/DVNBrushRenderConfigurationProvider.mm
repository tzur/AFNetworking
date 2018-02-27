// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel.h"
#import "DVNBrushRenderConfigurationProviderV1.h"
#import "DVNBrushRenderModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVNBrushRenderConfigurationProvider ()

/// Provider of \c DVNPipelineConfiguration objects for the \c model of this instance.
@property (strong, nonatomic) id<DVNBrushRenderConfigurationProvider> provider;

@end

@implementation DVNBrushRenderConfigurationProvider

#pragma mark -
#pragma mark DVNBrushRenderConfigurationProvider
#pragma mark -

- (DVNPipelineConfiguration *)configurationForModel:(DVNBrushRenderModel *)model
    withTextureMapping:(NSDictionary<NSString *, LTTexture *> *)textureMapping {
  id<DVNBrushRenderConfigurationProvider> _Nullable provider = self.provider;

  switch (model.brushModel.version.value) {
    case DVNBrushModelVersionV1:
      if (![self.provider isMemberOfClass:[DVNBrushRenderConfigurationProviderV1 class]]) {
        provider = [[DVNBrushRenderConfigurationProviderV1 alloc] init];
      }
  }

  self.provider = provider;

  return [self.provider configurationForModel:model withTextureMapping:textureMapping];
}

@end

NS_ASSUME_NONNULL_END
