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

- (instancetype)initWithInput:(LTTexture *)input
      meshDisplacementTexture:(LTTexture *)meshDisplacementTexture output:(LTTexture *)output {
  return [self initWithFragmentSource:[LTPassthroughShaderFsh source] input:input
              meshDisplacementTexture:meshDisplacementTexture output:output];
}

- (instancetype)initWithFragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
               meshDisplacementTexture:(LTTexture *)meshDisplacementTexture
                                output:(LTTexture *)output {
  return [self initWithFragmentSource:fragmentSource input:input
               displacementSourceRect:CGRectFromSize(input.size)
              meshDisplacementTexture:meshDisplacementTexture output:output];
}

- (instancetype)initWithFragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
                displacementSourceRect:(CGRect)displacementSourceRect
               meshDisplacementTexture:(LTTexture *)meshDisplacementTexture
                                output:(LTTexture *)output {
  LTParameterAssert(fragmentSource);
  LTParameterAssert(input);
  LTParameterAssert(meshDisplacementTexture);
  LTParameterAssert(output);
  [LTMeshProcessor assertMeshTextureFormatOfTexture:meshDisplacementTexture];

  LTMeshDrawer *drawer = [[LTMeshDrawer alloc] initWithSourceTexture:input
                                                      meshSourceRect:displacementSourceRect
                                                         meshTexture:meshDisplacementTexture
                                                      fragmentSource:fragmentSource];

  if (self = [super initWithDrawer:drawer sourceTexture:input
                 auxiliaryTextures:nil andOutput:output]) {
    self.meshTexture = meshDisplacementTexture;
  }

  return self;
}

+ (void)assertMeshTextureFormatOfTexture:(LTTexture *)meshDisplacementTexture {
  LTParameterAssert(meshDisplacementTexture.pixelFormat.value == LTGLPixelFormatRG16Float ||
                    meshDisplacementTexture.pixelFormat.value == LTGLPixelFormatRGBA16Float,
                    @"mesh displacement texture must have at least two channels of half-float "
                    "precision but input texture pixel format is %@",
                    meshDisplacementTexture.pixelFormat);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (LTTexture *)meshDisplacementTexture {
  return self.meshTexture;
}

@end

NS_ASSUME_NONNULL_END
