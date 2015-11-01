// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTMeshProcessor.h"

#import "LTMeshDrawer.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTMeshProcessor ()

/// Mesh displacement texture.
@property (strong, nonatomic) LTTexture *meshTexture;

@end

@implementation LTMeshProcessor

- (instancetype)initWithInput:(LTTexture *)input meshSize:(CGSize)meshSize
                       output:(LTTexture *)output {
  return [self initWithFragmentSource:[LTPassthroughShaderFsh source] input:input meshSize:meshSize
                               output:output];
}

- (instancetype)initWithFragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
                              meshSize:(CGSize)meshSize output:(LTTexture *)output {
  LTParameterAssert(fragmentSource);
  LTParameterAssert(input);
  LTParameterAssert(output);
  LTTexture *meshTexture = [self meshTextureWithSize:meshSize];
  LTMeshDrawer *drawer = [[LTMeshDrawer alloc] initWithSourceTexture:input meshTexture:meshTexture
                                                      fragmentSource:fragmentSource];
  if (self = [super initWithDrawer:drawer sourceTexture:input
                 auxiliaryTextures:nil andOutput:output]) {
    self.meshTexture = meshTexture;
    [self.meshTexture clearWithColor:LTVector4::zeros()];
  }
  return self;
}

- (LTTexture *)meshTextureWithSize:(CGSize)size {
  return [LTTexture textureWithSize:size precision:LTTexturePrecisionHalfFloat
                             format:LTTextureFormatRGBA allocateMemory:YES];
}

#pragma mark -
#pragma mark Reset
#pragma mark -

- (void)resetMesh {
  [self.meshTexture clearWithColor:LTVector4::zeros()];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (LTTexture *)meshDisplacementTexture {
  return self.meshTexture;
}

@end

NS_ASSUME_NONNULL_END
